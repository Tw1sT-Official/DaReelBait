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
  double _tension = 0.45; // 0.0 to 1.0 (Sweet spot: 0.25 to 0.75)
  double _rodSteerAngle = 0.0; // -1.0 to 1.0
  double _fishDistanceMeters = 14.0;
  double _fishLateralOffset = 0.0; // -1.0 to 1.0
  double _fishStamina = 1.0;
  bool _hasBobberSubmerged = false;

  // Hold-to-Reel Mechanics
  bool _isHoldingReel = false;
  double _reelVisualAngle = 0.0;
  double _hapticThrottle = 0.0;
  double _escapeGraceTimer = 4.0; // 4 seconds warning before fish can escape

  // Realistic Pacing & Pity Timer
  double _waitTimer = 0.0;
  double _targetBiteTime = 20.0; // 15s to 45s, 60s pity
  double _nibbleTimer = 0.0;
  double _plungeTimer = 0.0;
  String? _targetFishSpeciesId;

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

    // Check if player has bait remaining (Earthworms & Bread are infinite!)
    final hasBait = await AnglerStorage.consumeEquippedBait();
    if (!mounted) return;
    if (!hasBait) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Out of ${_equippedBait.name}! Switch to Earthworms (Unlimited) in your Tackle Box.'),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _state = FishingState.casting;
      _castProgress = 0.0;
      _tension = 0.45;
      _hasBobberSubmerged = false;
      _fishDistanceMeters = 12.0 + Random().nextDouble() * 5.0; // 12m - 17m distance
      _fishLateralOffset = 0.0;
      _escapeGraceTimer = 4.0;
      _isHoldingReel = false;
    });

    // Cast animation
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted || _state != FishingState.casting) return;
      setState(() {
        _castProgress = (i + 1) / 15.0;
      });
    }

    // Determine target fish from location & bait
    _chooseTargetFish();

    // Set bite timer: 12s - 35s (60s max pity)
    final rand = Random();
    final activeSpecies = FishDatabase.getSpecies(_targetFishSpeciesId ?? 'bluegill');
    final lovesBait = activeSpecies.isFavoriteBait(_equippedBait.id);
    final baseWait = lovesBait ? 12.0 + rand.nextDouble() * 14.0 : 18.0 + rand.nextDouble() * 20.0;

    setState(() {
      _state = FishingState.waitingForBite;
      _waitTimer = 0.0;
      _targetBiteTime = baseWait.clamp(10.0, 55.0);
    });
  }

  void _chooseTargetFish() {
    final locationSpecies = FishDatabase.getSpeciesForLocation(_locationId);
    if (locationSpecies.isEmpty) {
      _targetFishSpeciesId = 'bluegill';
      return;
    }

    final rand = Random();
    final matches = locationSpecies.where((s) => s.isFavoriteBait(_equippedBait.id)).toList();
    if (matches.isNotEmpty && rand.nextDouble() < 0.70) {
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

    // Pity trigger
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

    if (_nibbleTimer < 2.0) {
      // Light nibbles
      if (Random().nextDouble() < 0.15) {
        HapticFeedback.lightImpact();
      }
    } else {
      // The Strike! Bobber plunges underwater!
      if (!_hasBobberSubmerged) {
        _hasBobberSubmerged = true;
        HapticFeedback.heavyImpact();
      }

      _plungeTimer += dt;
      // Generous 2.5-second window to flick up or tap to set the hook
      if (_plungeTimer > 2.5) {
        HapticFeedback.selectionClick();
        _resetToIdle('The fish nibbled the bait away. Cast again!');
      }
    }
  }

  void _setHook() {
    if (_state != FishingState.nibbling) return;

    if (!_hasBobberSubmerged) {
      // Flicked too early during light nibble
      HapticFeedback.mediumImpact();
      _resetToIdle('Flicked too early! Wait for the bobber to plunge under.');
      return;
    }

    // SUCCESSFUL HOOK SET!
    HapticFeedback.heavyImpact();
    setState(() {
      _state = FishingState.reelingFight;
      _tension = 0.45;
      _fishStamina = 1.0;
      _escapeGraceTimer = 4.0;
      _isHoldingReel = false;
    });
  }

  void _updateReelingFight(double dt) {
    // Fish swims left and right smoothly
    _fishLateralOffset = sin(_currentTime * 1.8) * 0.85;

    // Counter-steering check (steering opposite to fish direction)
    final isCounterSteering = (_rodSteerAngle * _fishLateralOffset) < -0.05;
    if (isCounterSteering) {
      _fishStamina = (_fishStamina - 0.20 * _equippedRod.strengthRating * dt).clamp(0.0, 1.0);
    } else {
      _fishStamina = (_fishStamina - 0.06 * dt).clamp(0.0, 1.0);
    }

    // HOLD TO REEL MECHANIC
    if (_isHoldingReel) {
      // Retrieve line steadily (approx 1.8m to 2.4m per second)
      final retrieveRate = (1.8 + (_equippedRod.strengthRating * 0.3)) * dt;
      _fishDistanceMeters = max(0.0, _fishDistanceMeters - retrieveRate);

      // Cranking builds tension
      _tension = (_tension + 0.30 * dt).clamp(0.0, 1.0);

      // Rotate visual reel spool
      _reelVisualAngle += dt * 10;

      // Haptic tick
      _hapticThrottle += dt;
      if (_hapticThrottle > 0.12) {
        HapticFeedback.selectionClick();
        _hapticThrottle = 0.0;
      }
    } else {
      // When not holding, drag lets tension drop back into safe green zone
      final dropRate = 0.28 * dt;
      _tension = (_tension - dropRate).clamp(0.0, 1.0);
    }

    // DANGER BUFFER: Check if tension is in dangerous slack (< 0.10) or dangerous strain
    final maxStrain = (0.86 + (_equippedLine.strengthRating - 1.0) * 0.05).clamp(0.86, 0.98);
    final isDanger = _tension > maxStrain || (_tension < 0.10 && _fishDistanceMeters > 2.0);

    if (isDanger) {
      _escapeGraceTimer -= dt;
      if (_escapeGraceTimer <= 0.0) {
        if (_tension > maxStrain) {
          HapticFeedback.heavyImpact();
          _resetToIdle('LINE SNAPPED! Tension exceeded ${_equippedLine.name} rating.');
        } else {
          _resetToIdle('HOOK SPIT! The line went too slack. Remember to keep reeling.');
        }
        return;
      }
    } else {
      // Safe zone restores escape grace timer
      _escapeGraceTimer = (_escapeGraceTimer + dt * 1.5).clamp(0.0, 4.0);
    }

    // Catch landed!
    if (_fishDistanceMeters <= 0.0) {
      _landCatch();
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
      _isHoldingReel = false;
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
      _tension = 0.45;
      _isHoldingReel = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(reason), backgroundColor: const Color(0xFFC62828), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = FishingLocation.getLocation(_locationId);
    final hasWatch = AnglerStorage.hasWatch();

    final hourStr = _now.hour.toString().padLeft(2, '0');
    final minStr = _now.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

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

                  // Fighting HUD: Tension Gauge & Guidance
                  if (_state == FishingState.reelingFight) ...[
                    _buildFightTensionGauge(),
                    const SizedBox(height: 8),
                    _buildSteeringGuidanceBanner(),
                    const SizedBox(height: 12),
                  ],

                  // Hook-set Action Prompt (Plunge state)
                  if (_state == FishingState.nibbling && _hasBobberSubmerged)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Colors.redAccent, blurRadius: 25)],
                      ),
                      child: const Text(
                        '⚡ TAP ANYWHERE TO SET HOOK! ⚡',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
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
                            Text('Lure: ${_equippedBait.name} (Tap to twitch line)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),

                  // Bottom Dock Controls
                  if (_state != FishingState.reelingFight) _buildBottomDockControls(),
                ],
              ),
            ),
          ),

          // Two-Handed Touch Controls during Reeling Fight
          if (_state == FishingState.reelingFight) ...[
            // Left Side: Easy Steering Buttons
            Positioned(
              left: 20,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ROD STEERING', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Steer Left Button
                      GestureDetector(
                        onTapDown: (_) {
                          HapticFeedback.lightImpact();
                          setState(() => _rodSteerAngle = -0.85);
                        },
                        onTapUp: (_) => setState(() => _rodSteerAngle = 0.0),
                        onTapCancel: () => setState(() => _rodSteerAngle = 0.0),
                        child: Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: _rodSteerAngle < -0.2 ? const Color(0xFF00E5FF) : const Color(0xFF1E2838),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00E5FF)),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: _rodSteerAngle < -0.2 ? Colors.black : Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Steer Right Button
                      GestureDetector(
                        onTapDown: (_) {
                          HapticFeedback.lightImpact();
                          setState(() => _rodSteerAngle = 0.85);
                        },
                        onTapUp: (_) => setState(() => _rodSteerAngle = 0.0),
                        onTapCancel: () => setState(() => _rodSteerAngle = 0.0),
                        child: Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: _rodSteerAngle > 0.2 ? const Color(0xFF00E5FF) : const Color(0xFF1E2838),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00E5FF)),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: _rodSteerAngle > 0.2 ? Colors.black : Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Side: Press-and-Hold Reel Button (With spinning spool!)
            Positioned(
              right: 20,
              bottom: 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('REEL CONTROL', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTapDown: (_) {
                      HapticFeedback.mediumImpact();
                      setState(() => _isHoldingReel = true);
                    },
                    onTapUp: (_) {
                      setState(() => _isHoldingReel = false);
                    },
                    onTapCancel: () {
                      setState(() => _isHoldingReel = false);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: _isHoldingReel
                              ? [const Color(0xFF00E5FF), const Color(0xFF0091EA)]
                              : [const Color(0xFF37474F), const Color(0xFF1E2838)],
                        ),
                        border: Border.all(
                          color: _tension > 0.80 ? const Color(0xFFFF1744) : const Color(0xFF00E5FF),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isHoldingReel
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                                : Colors.black54,
                            blurRadius: _isHoldingReel ? 25 : 12,
                            spreadRadius: _isHoldingReel ? 3 : 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.rotate(
                              angle: _reelVisualAngle,
                              child: Icon(
                                Icons.rotate_right,
                                color: _isHoldingReel ? Colors.black : const Color(0xFF00E5FF),
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isHoldingReel ? 'REELING!' : 'HOLD TO\nREEL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isHoldingReel ? Colors.black : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tap Anywhere to Hook when Fish Strikes!
          if (_state == FishingState.nibbling && _hasBobberSubmerged)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _setHook,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFightTensionGauge() {
    Color gaugeColor = const Color(0xFF81C784); // Green optimal
    String statusTitle = '🟢 OPTIMAL TENSION — KEEP HOLDING REEL!';

    if (_tension < 0.15) {
      gaugeColor = const Color(0xFFFFD54F); // Yellow slack
      statusTitle = '⚠️ LINE TOO SLACK! HOLD REEL TO TIGHTEN!';
    } else if (_tension > 0.80) {
      gaugeColor = const Color(0xFFFF1744); // Red snapping
      statusTitle = '⚠️ STRAIN HIGH! RELEASE REEL FOR A SECOND!';
    }

    final isDanger = _tension > 0.85 || (_tension < 0.12 && _fishDistanceMeters > 2.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gaugeColor.withValues(alpha: 0.8), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusTitle,
                style: TextStyle(color: gaugeColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text(
                '${_fishDistanceMeters.toStringAsFixed(1)} m left',
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
          if (isDanger) ...[
            const SizedBox(height: 6),
            Text(
              '⚠️ DANGER! Fish escaping in ${_escapeGraceTimer.toStringAsFixed(1)}s!',
              style: const TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSteeringGuidanceBanner() {
    // Check which way fish is running
    final fishRunningLeft = _fishLateralOffset < -0.15;
    final fishRunningRight = _fishLateralOffset > 0.15;

    String guideText = '🐟 Fish is centered. Keep holding reel!';
    Color guideColor = const Color(0xFF00E5FF);

    if (fishRunningLeft) {
      guideText = '◀◀ FISH RUNNING LEFT! TAP RIGHT STEER! ◀◀';
      guideColor = const Color(0xFFFFB300);
    } else if (fishRunningRight) {
      guideText = '▶▶ FISH RUNNING RIGHT! TAP LEFT STEER! ▶▶';
      guideColor = const Color(0xFFFFB300);
    }

    final isCountering = (_rodSteerAngle * _fishLateralOffset) < -0.1;
    if (isCountering) {
      guideText = '🎯 COUNTERED! Fish is tiring out fast!';
      guideColor = const Color(0xFF81C784);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: guideColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: guideColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        guideText,
        textAlign: TextAlign.center,
        style: TextStyle(color: guideColor, fontWeight: FontWeight.bold, fontSize: 11.5),
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
