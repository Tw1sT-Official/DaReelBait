import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/location.dart';
import '../services/angler_storage.dart';

class WorldMapDialog extends StatefulWidget {
  final VoidCallback onLocationChanged;

  const WorldMapDialog({super.key, required this.onLocationChanged});

  @override
  State<WorldMapDialog> createState() => _WorldMapDialogState();
}

class _WorldMapDialogState extends State<WorldMapDialog> {
  int _currentLocId = 1;
  int _coins = 0;
  int _zenRank = 1;

  @override
  void initState() {
    super.initState();
    _currentLocId = AnglerStorage.getCurrentLocationId();
    _coins = AnglerStorage.getCoins();
    _zenRank = AnglerStorage.getZenRank();
  }

  void _travelTo(FishingLocation loc) async {
    if (loc.id == _currentLocId) return;

    if (_zenRank < loc.requiredZenRank) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Requires Zen Rank ${loc.requiredZenRank}! Release more fish to level up.'),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
      return;
    }

    if (_coins < loc.travelFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins for the travel permit/ferry ticket!'),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    if (loc.travelFee > 0) {
      await AnglerStorage.spendCoins(loc.travelFee);
    }
    await AnglerStorage.setLocation(loc.id);
    widget.onLocationChanged();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Traveled to ${loc.name}! ${loc.travelFee > 0 ? "(-${loc.travelFee} 🪙 fare paid)" : "(Free Starter Lake)"}'),
          backgroundColor: const Color(0xFF0288D1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF14141E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🗺️ ', style: TextStyle(fontSize: 22)),
                    Text('Angling Destinations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('YOUR FUNDS: $_coins 🪙', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('ZEN MASTERY: RANK $_zenRank', style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: FishingLocation.all.length,
              itemBuilder: (context, i) {
                final loc = FishingLocation.all[i];
                final isCurrent = loc.id == _currentLocId;
                final isLocked = _zenRank < loc.requiredZenRank;

                return Card(
                  color: isCurrent ? const Color(0xFF1E2838) : const Color(0xFF191924),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isCurrent ? const Color(0xFF00E5FF) : Colors.white10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isLocked ? Colors.white12 : const Color(0xFF0288D1).withValues(alpha: 0.3),
                          child: Text(
                            '${loc.id}',
                            style: TextStyle(
                              color: isLocked ? Colors.grey : const Color(0xFF00E5FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(loc.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 6),
                                    const Text('• HERE', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(loc.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    loc.isFree ? 'FREE ENTRY' : 'FEE: ${loc.travelFee} 🪙',
                                    style: TextStyle(
                                      color: loc.isFree ? const Color(0xFF81C784) : Colors.amber,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'REQ: RANK ${loc.requiredZenRank}',
                                    style: TextStyle(
                                      color: isLocked ? const Color(0xFFFF5252) : Colors.white54,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrent)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLocked ? Colors.white12 : const Color(0xFF0288D1),
                              foregroundColor: isLocked ? Colors.grey : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _travelTo(loc),
                            child: Text(isLocked ? 'LOCKED' : (loc.isFree ? 'GO (FREE)' : 'TRAVEL')),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
