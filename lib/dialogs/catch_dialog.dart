import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/fish_painter.dart';
import '../models/fish.dart';
import '../services/angler_storage.dart';

class CatchShowcaseDialog extends StatefulWidget {
  final CaughtFish fish;
  final VoidCallback onDismiss;

  const CatchShowcaseDialog({
    super.key,
    required this.fish,
    required this.onDismiss,
  });

  @override
  State<CatchShowcaseDialog> createState() => _CatchShowcaseDialogState();
}

class _CatchShowcaseDialogState extends State<CatchShowcaseDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _photoTaken = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _snapPhoto() {
    HapticFeedback.heavyImpact();
    setState(() {
      _photoTaken = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📸 Catch photo snapped and saved to your Logbook!'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _storeInCooler() async {
    final fish = widget.fish;
    if (!AnglerStorage.hasCoolerRoomFor(fish.weightKg)) {
      // Cooler full dialog
      _showCoolerFullDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    await AnglerStorage.addToCooler(fish);
    await AnglerStorage.recordLogbookCatch(fish);
    if (mounted) {
      Navigator.pop(context);
      widget.onDismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stored in cooler! Current capacity: ${AnglerStorage.getCoolerTotalWeightKg().toStringAsFixed(1)} / ${AnglerStorage.getCoolerMaxCapacityKg().toStringAsFixed(1)} kg'),
          backgroundColor: const Color(0xFF0288D1),
        ),
      );
    }
  }

  void _releaseFish() async {
    HapticFeedback.lightImpact();
    final zenEarned = widget.fish.zenValue;
    await AnglerStorage.addZen(zenEarned);
    await AnglerStorage.recordLogbookCatch(widget.fish);

    if (mounted) {
      Navigator.pop(context);
      widget.onDismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🌿 Fish released back to nature! +$zenEarned Zen XP earned.'),
          backgroundColor: const Color(0xFF388E3C),
        ),
      );
    }
  }

  void _showCoolerFullDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E28),
        title: const Text('🧺 Cooler is Full!', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold)),
        content: Text(
          'Your ${AnglerStorage.getEquippedCooler().name} cannot fit this ${widget.fish.weightKg} kg fish!\n\n'
          'Current Load: ${AnglerStorage.getCoolerTotalWeightKg().toStringAsFixed(1)} / ${AnglerStorage.getCoolerMaxCapacityKg().toStringAsFixed(1)} kg.\n\n'
          'Would you like to emergency-sell a catch to nearby dock fishermen at dock price (60%) to make room, or release this fish?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _releaseFish();
            },
            child: const Text('RELEASE THIS FISH', style: TextStyle(color: Colors.greenAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300), foregroundColor: Colors.black),
            onPressed: () async {
              // Sell the oldest fish in cooler to free room
              final fishList = AnglerStorage.getCoolerFish();
              if (fishList.isNotEmpty) {
                final sold = fishList.first;
                final earned = await AnglerStorage.fieldSellCoolerCatch(sold);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  _storeInCooler();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sold 1 ${sold.species.name} to dock angler for +$earned 🪙 to make room!'),
                      backgroundColor: const Color(0xFFFF8F00),
                    ),
                  );
                }
              }
            },
            child: const Text('DOCK-SELL 1 TO MAKE ROOM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fish = widget.fish;
    final species = fish.species;
    final hasScale = AnglerStorage.hasScaleAndTape();
    final hasCam = AnglerStorage.hasCamera();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: species.rarityColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: species.rarityColor.withValues(alpha: 0.35),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        species.name,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        species.scientificName,
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: species.rarityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: species.rarityColor),
                    ),
                    child: Text(
                      species.rarityName,
                      style: TextStyle(color: species.rarityColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // Canvas Display of Fish on Dock
            ClipRRect(
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) => CustomPaint(
                    painter: FishCatchPainter(
                      fish: fish,
                      hasScaleAndTape: hasScale,
                      animationProgress: _animController.value,
                    ),
                  ),
                ),
              ),
            ),

            // Stats Card (Examined or Unknown)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Length
                    Column(
                      children: [
                        const Text('LENGTH', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(
                          hasScale ? '${fish.lengthCm} cm' : '??? cm',
                          style: TextStyle(
                            color: hasScale ? Colors.white : Colors.white38,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.white12),
                    // Weight
                    Column(
                      children: [
                        const Text('WEIGHT', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(
                          hasScale ? '${fish.weightKg} kg' : '??? kg',
                          style: TextStyle(
                            color: hasScale ? const Color(0xFFFFD54F) : Colors.white38,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.white12),
                    // Estimated Market Value
                    Column(
                      children: [
                        const Text('MARKET', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(
                          '~${fish.marketValue} 🪙',
                          style: const TextStyle(color: Color(0xFF81C784), fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (!hasScale)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Text(
                  '💡 Purchase Brass Scale & Tape at the Tackle Shack to weigh and measure catches yourself!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),

            // Camera Action (if owned)
            if (hasCam)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00E5FF),
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    minimumSize: const Size(double.infinity, 38),
                  ),
                  onPressed: _photoTaken ? null : _snapPhoto,
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: Text(_photoTaken ? 'PHOTO SAVED TO LOGBOOK' : 'SNAP CATCH CERTIFICATE PHOTO'),
                ),
              ),

            const SizedBox(height: 10),

            // Action Buttons: Cooler vs Release
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF81C784),
                        side: const BorderSide(color: Color(0xFF81C784), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _releaseFish,
                      child: Text('RELEASE (+${fish.zenValue} Zen)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _storeInCooler,
                      child: const Text('STORE IN COOLER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
