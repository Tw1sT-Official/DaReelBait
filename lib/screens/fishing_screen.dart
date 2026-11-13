import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dialogs/catch_dialog.dart';
import '../dialogs/cooler_dialog.dart';
import '../dialogs/tackle_box_dialog.dart';
import '../dialogs/world_map_dialog.dart';
import '../game/water_painter.dart';
import '../models/equipment.dart';
import '../models/fish.dart';
import '../models/location.dart';
import '../services/angler_storage.dart';
import 'diary_screen.dart';
import 'logbook_screen.dart';
import 'shop_screen.dart';

class FishingScreen extends StatefulWidget {
  const FishingScreen({super.key});

  @override
  State<FishingScreen> createState() => _FishingScreenState();
}

class _FishingScreenState extends State<FishingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  double _lastTick = 0;
  double _currentTime = 0;

  // Real-time Day/Night Clock
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  // Angler State
  int _coins = 0;
  int _zenRank = 1;
  int _locationId = 1;
  late EquipmentItem _equippedBait;
  late EquipmentItem _equippedRod;
  late EquipmentItem _equippedLine;

  // Fishing Cycle & Physics
  FishingState _state = FishingState.idle;
  double _castProgress = 0.0;
  double _tension = 0.4; // 0.0 to 1.0
  double _rodSteerAngle = 0.0; // -1.0 to 1.0
  double _fishDistanceMeters = 22.0;
  double _fishLateralOffset = 0.0; // -1.0 to 1.0
  double _fishStamina = 1.0;
  bool _hasBobberSubmerged = false;

  // Realistic Pacing & Pity Timer
  double _waitTimer = 0.0;
  double _targetBiteTime = 20.0; // 15s to 45s, 60s pity
  double _nibbleTimer = 0.0;
  double _plungeTimer = 0.0;
  String? _targetFishSpeciesId;

  // Reeling Touch Coordinates
  double _lastCrankAngle = 0.0;
  Offset? _crankCenter;

  @override
  void initState() {
    super.initState();
    _loadAnglerData();

    // Clock ticker every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 365),
    )..addListener(_engineLoop);

    _ticker.forward();
  }

  void _loadAnglerData() {
    setState(() {
      _coins = AnglerStorage.getCoins();
      _zenRank = AnglerStorage.getZenRank();
      _locationId = AnglerStorage.getCurrentLocationId();
      _equippedBait = EquipmentDatabase.getItem(AnglerStorage.getEquippedBaitId());
      _equippedRod = AnglerStorage.getEquippedRod();
      _equippedLine = AnglerStorage.getEquippedLine();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _engineLoop() {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (_lastTick == 0) _lastTick = now;
    final dt = (now - _lastTick).clamp(0.0, 0.05);
    _lastTick = now;
    _currentTime = now;

    if (_state == FishingState.waitingForBite) {
      _updateWaiting(dt);
    } else if (_state == FishingState.nibbling) {
      _updateNibble(dt);
    } else if (_state == FishingState.reelingFight) {
      _updateReelingFight(dt);
    }

    setState(() {});
  }

  void _startCast() async {
    if (_state != FishingState.idle) return;

    // Check if player has bait remaining
    final hasBait = await AnglerStorage.consumeEquippedBait();
    if (!mounted) return;
    if (!hasBait) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Out of ${_equippedBait.name}! Open Tackle Box to switch bait or visit Tackle Shack.'),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _state = FishingState.casting;
      _castProgress = 0.0;
      _tension = 0.3;
      _hasBobberSubmerged = false;
      _fishDistanceMeters = 20.0 + Random().nextDouble() * 10.0;
      _fishLateralOffset = 0.0;
    });

    // Cast animation
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted || _state != FishingState.casting) return;
      setState(() {
        _castProgress = (i + 1) / 20.0;
      });
    }

    // Determine target fish from location & bait
    _chooseTargetFish();

    // Set bite timer: 15s - 45s (60s pity limit)
    final rand = Random();
    final activeSpecies = FishDatabase.getSpecies(_targetFishSpeciesId ?? 'bluegill');
    final lovesBait = activeSpecies.isFavoriteBait(_equippedBait.id);
    final baseWait = lovesBait ? 14.0 + rand.nextDouble() * 16.0 : 22.0 + rand.nextDouble() * 26.0;

    setState(() {
      _state = FishingState.waitingForBite;
      _waitTimer = 0.0;
      _targetBiteTime = baseWait.clamp(12.0, 58.0);
    });
  }

  void _chooseTargetFish() {
    final locationSpecies = FishDatabase.getSpeciesForLocation(_locationId);
    if (locationSpecies.isEmpty) {
      _targetFishSpeciesId = 'bluegill';
      return;
    }

    final rand = Random();
    // Prioritize fish that love the equipped bait and are active at the current hour
    final matches = locationSpecies.where((s) => s.isFavoriteBait(_equippedBait.id)).toList();
    if (matches.isNotEmpty && rand.nextDouble() < 0.65) {
      _targetFishSpeciesId = matches[rand.nextInt(matches.length)].id;
    } else {
      _targetFishSpeciesId = locationSpecies[rand.nextInt(locationSpecies.length)].id;
    }
  }

  void _twitchLure() {
    if (_state != FishingState.waitingForBite) return;
    HapticFeedback.selectionClick();

    // Twitching speeds up bite discovery by 3 seconds!
    setState(() {
      _waitTimer += 3.0;
    });
  }

  void _updateWaiting(double dt) {
    _waitTimer += dt;

    // Pity trigger at 60s
    if (_waitTimer >= _targetBiteTime || _waitTimer >= 60.0) {
      HapticFeedback.lightImpact();
      _state = FishingState.nibbling;
      _nibbleTimer = 0.0;
      _plungeTimer = 0.0;
      _hasBobberSubmerged = false;
    }
  }

  void _updateNibble(double dt) {
    _nibbleTimer += dt;

    if (_nibbleTimer < 2.5) {
      // Bobber twitches lightly
      if (Random().nextDouble() < 0.12) {
        HapticFeedback.lightImpact();
      }
    } else {
      // The Strike! Bobber plunges underwater!
      if (!_hasBobberSubmerged) {
        _hasBobberSubmerged = true;
        HapticFeedback.heavyImpact();
      }

      _plungeTimer += dt;
      // 2.0-second window to flick up and set the hook
      if (_plungeTimer > 2.0) {
        // Missed the bite!
        HapticFeedback.selectionClick();
        _resetToIdle('The fish nibbled off the bait and darted away!');
      }
    }
  }

  void _setHook() {
    if (_state != FishingState.nibbling) return;

    if (!_hasBobberSubmerged) {
      // Flicked too early during light nibble!
      HapticFeedback.mediumImpact();
      _resetToIdle('Flicked too early! You pulled the lure right out of its mouth.');
      return;
    }

    // SUCCESSFUL HOOK SET!
    HapticFeedback.heavyImpact();
    setState(() {
      _state = FishingState.reelingFight;
      _tension = 0.5;
      _fishStamina = 1.0;
    });
  }

  void _updateReelingFight(double dt) {
    // Fish swims laterally
    _fishLateralOffset += sin(_currentTime * 2.2) * dt * 0.8;
    _fishLateralOffset = _fishLateralOffset.clamp(-1.0, 1.0);

    // Rod damping absorbs strain
    final damping = 0.15 * _equippedRod.strengthRating;
    _tension = (_tension - damping * dt).clamp(0.0, 1.0);

    // Counter-steering bonus: steering opposite to fish reduces tension strain & drains stamina
    final isCounterSteering = (_rodSteerAngle * _fishLateralOffset) < -0.1;
    if (isCounterSteering) {
      _fishStamina = (_fishStamina - 0.25 * _equippedRod.strengthRating * dt).clamp(0.0, 1.0);
    } else {
      _fishStamina = (_fishStamina - 0.08 * dt).clamp(0.0, 1.0);
    }

    // Line snap threshold improves with heavier line
    final snapThreshold = (0.92 + (_equippedLine.strengthRating - 1.0) * 0.04).clamp(0.92, 0.99);
    if (_tension >= snapThreshold) {
      HapticFeedback.heavyImpact();
      _resetToIdle('LINE SNAPPED! Strain exceeded ${_equippedLine.name} rating.');
      return;
    }

    // Check hook spit on total slack
    if (_tension <= 0.05 && _fishDistanceMeters > 3.0) {
      _resetToIdle('HOOK SPIT! You gave the line too much slack.');
      return;
    }

    // Catch landed!
    if (_fishDistanceMeters <= 0.0) {
      _landCatch();
    }
  }

  void _onReelCrankPanUpdate(DragUpdateDetails details) {
    if (_state != FishingState.reelingFight) return;

    final touchPos = details.localPosition;
    _crankCenter ??= Offset(touchPos.dx, touchPos.dy);

    final angle = atan2(touchPos.dy - _crankCenter!.dy, touchPos.dx - _crankCenter!.dx);
    double deltaAngle = angle - _lastCrankAngle;

    // Handle wrap-around
    if (deltaAngle > pi) deltaAngle -= pi * 2;
    if (deltaAngle < -pi) deltaAngle += pi * 2;

    _lastCrankAngle = angle;

    if (deltaAngle > 0.05) {
      // Clockwise crank detected!
      final crankSpeed = deltaAngle * 2.0;

      // Crank pulls fish closer
      final retrieveDistance = crankSpeed * 0.45;
      _fishDistanceMeters = max(0.0, _fishDistanceMeters - retrieveDistance);

      // Cranking increases tension
      _tension = (_tension + 0.04 * crankSpeed).clamp(0.0, 1.0);

      HapticFeedback.selectionClick();
    }
  }

  void _landCatch() {
    HapticFeedback.heavyImpact();
    final speciesId = _targetFishSpeciesId ?? 'bluegill';
    final hasScale = AnglerStorage.hasScaleAndTape();

    final caught = FishDatabase.generateCatch(
      speciesId: speciesId,
      locationId: _locationId,
      baitUsed: _equippedBait.id,
      playerHasScaleTape: hasScale,
    );

    setState(() {
      _state = FishingState.catchLanded;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CatchShowcaseDialog(
        fish: caught,
        onDismiss: () {
          setState(() {
            _state = FishingState.idle;
            _loadAnglerData();
          });
        },
      ),
    );
  }

  void _resetToIdle(String reason) {
    setState(() {
      _state = FishingState.idle;
      _hasBobberSubmerged = false;
      _tension = 0.3;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(reason), backgroundColor: const Color(0xFFC62828)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = FishingLocation.getLocation(_locationId);
    final hasWatch = AnglerStorage.hasWatch();

    // Time Formatting
    final hourStr = _now.hour.toString().padLeft(2, '0');
    final minStr = _now.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    // Solunar Barometer
    String activityText = 'Normal Activity';
    if (_now.hour >= 17 && _now.hour <= 19) {
      activityText = 'Peak Feeding Frenzy 🔥';
    } else if (_now.hour >= 5 && _now.hour <= 8) {
      activityText = 'Morning Feeding Rush 🌅';
    } else if (_now.hour >= 23 || _now.hour <= 4) {
      activityText = 'Nocturnal Hunters 🌙';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Water Canvas
          CustomPaint(
            size: Size.infinite,
            painter: WaterPainter(
              timeSeconds: _currentTime,
              state: _state,
              castProgress: _castProgress,
              tension: _tension,
              rodSteerAngle: _rodSteerAngle,
              fishDistanceMeters: _fishDistanceMeters,
              fishLateralOffset: _fishLateralOffset,
              hasBobberSubmerged: _hasBobberSubmerged,
              currentHour: _now.hour,
              locationType: location.environmentType,
            ),
          ),

          // 2. HUD Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location Title & Travel Button
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => WorldMapDialog(onLocationChanged: _loadAnglerData),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.explore, color: Color(0xFF00E5FF), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                location.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                            ],
                          ),
                        ),
                      ),

                      // Funds & Zen Rank Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            Text('🪙 $_coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 8),
                            Text('🌿 R$_zenRank', style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),

                      // Time & Solunar Barometer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Text('⏱️ ', style: TextStyle(fontSize: 13)),
                            Text(
                              hasWatch ? timeStr : '${_now.hour}:00s',
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Solunar Activity subtitle
                  if (hasWatch)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activityText,
                          style: const TextStyle(color: Color(0xFF81C784), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Fighting HUD: Tension Gauge & Distance
                  if (_state == FishingState.reelingFight) ...[
                    _buildFightTensionGauge(),
                    const SizedBox(height: 12),
                  ],

                  // Hook-set Action Prompt
                  if (_state == FishingState.nibbling && _hasBobberSubmerged)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.red, blurRadius: 20)],
                      ),
                      child: const Text(
                        '⚡ FLICK UPWARD TO SET HOOK! ⚡',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),

                  // Active Bait Indicator
                  if (_state == FishingState.waitingForBite)
                    GestureDetector(
                      onTap: _twitchLure,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_equippedBait.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text('Lure: ${_equippedBait.name} (Tap to twitch)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),

                  // Bottom Dock Controls
                  _buildBottomDockControls(),
                ],
              ),
            ),
          ),

          // Two-Handed Touch Overlay
          if (_state == FishingState.reelingFight) ...[
            // Left Thumb Area: Steering
            Positioned(
              left: 20,
              bottom: 120,
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _rodSteerAngle = (_rodSteerAngle + d.delta.dx * 0.02).clamp(-1.0, 1.0);
                  });
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: const Center(
                    child: Text('STEER\nROD', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),

            // Right Thumb Area: Circular Reel Spool
            Positioned(
              right: 20,
              bottom: 120,
              child: GestureDetector(
                onPanStart: (d) => _crankCenter = d.localPosition,
                onPanUpdate: _onReelCrankPanUpdate,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [Color(0xFF37474F), Color(0xFF212121)]),
                    border: Border.all(color: const Color(0xFF00E5FF), width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15)],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.rotate(
                          angle: _lastCrankAngle,
                          child: const Icon(Icons.rotate_right, color: Color(0xFF00E5FF), size: 40),
                        ),
                        const Text('CRANK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Single Tap to Set Hook (Left Thumb flick area during strike)
          if (_state == FishingState.nibbling && _hasBobberSubmerged)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (d) {
                  if (d.delta.dy < -5) {
                    _setHook();
                  }
                },
                onTap: _setHook,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFightTensionGauge() {
    Color gaugeColor = const Color(0xFF81C784); // Green optimal
    if (_tension < 0.25) {
      gaugeColor = const Color(0xFFFFD54F); // Yellow slack
    } else if (_tension > 0.75) {
      gaugeColor = const Color(0xFFFF1744); // Red snapping
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gaugeColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tension > 0.75 ? '⚠️ STRAIN WARNING!' : (_tension < 0.25 ? '⚠️ SLACK LINE!' : 'OPTIMAL TENSION'),
                style: TextStyle(color: gaugeColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text(
                'Distance: ${_fishDistanceMeters.toStringAsFixed(1)} m',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _tension,
              minHeight: 12,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDockControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Tackle Box
          IconButton(
            tooltip: 'Tackle Box',
            icon: const Text('🧰', style: TextStyle(fontSize: 22)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => TackleBoxDialog(onEquipChanged: _loadAnglerData),
              );
            },
          ),

          // Cooler
          IconButton(
            tooltip: 'Cooler',
            icon: const Text('🧺', style: TextStyle(fontSize: 22)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CoolerDialog(onStateChanged: _loadAnglerData),
              );
            },
          ),

          // CAST BUTTON (Center)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _state == FishingState.idle ? const Color(0xFF00E5FF) : Colors.white12,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _state == FishingState.idle ? _startCast : null,
            child: Text(
              _state == FishingState.idle ? 'CAST LINE' : 'FISHING...',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
            ),
          ),

          // Tackle Shack (Shop)
          IconButton(
            tooltip: 'Tackle Shack',
            icon: const Text('🛖', style: TextStyle(fontSize: 22)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopScreen(locationId: _locationId, onStateChanged: _loadAnglerData),
                ),
              );
              _loadAnglerData();
            },
          ),

          // Logbook
          IconButton(
            tooltip: 'Logbook',
            icon: const Text('📖', style: TextStyle(fontSize: 22)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LogbookScreen()));
            },
          ),

          // Diary
          IconButton(
            tooltip: 'Diary',
            icon: const Text('📓', style: TextStyle(fontSize: 22)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaryScreen()));
            },
          ),
        ],
      ),
    );
  }
}
