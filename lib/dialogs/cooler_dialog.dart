import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/equipment.dart';
import '../models/fish.dart';
import '../services/angler_storage.dart';

class CoolerDialog extends StatefulWidget {
  final VoidCallback onStateChanged;

  const CoolerDialog({super.key, required this.onStateChanged});

  @override
  State<CoolerDialog> createState() => _CoolerDialogState();
}

class _CoolerDialogState extends State<CoolerDialog> {
  List<CaughtFish> _fishList = [];
  double _currentWeight = 0;
  double _maxWeight = 10;
  late EquipmentItem _cooler;

  @override
  void initState() {
    super.initState();
    _loadCooler();
  }

  void _loadCooler() {
    setState(() {
      _fishList = AnglerStorage.getCoolerFish();
      _currentWeight = AnglerStorage.getCoolerTotalWeightKg();
      _maxWeight = AnglerStorage.getCoolerMaxCapacityKg();
      _cooler = AnglerStorage.getEquippedCooler();
    });
  }

  void _fieldSellFish(CaughtFish fish) async {
    HapticFeedback.mediumImpact();
    final earned = await AnglerStorage.fieldSellCoolerCatch(fish);
    _loadCooler();
    widget.onStateChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sold ${fish.species.name} to dock angler for +$earned 🪙 (60% dock rate)!'),
          backgroundColor: const Color(0xFFFF8F00),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fillRatio = (_currentWeight / _maxWeight).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: const Color(0xFF14141E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(_cooler.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(_cooler.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Capacity Gauge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CAPACITY USAGE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(
                      '${_currentWeight.toStringAsFixed(1)} / ${_maxWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: fillRatio > 0.85 ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fillRatio,
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fillRatio > 0.85 ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 24),

          // Fish List
          Expanded(
            child: _fishList.isEmpty
                ? const Center(
                    child: Text('Your cooler is empty.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _fishList.length,
                    itemBuilder: (context, i) {
                      final fish = _fishList[i];
                      final species = fish.species;

                      return Card(
                        color: const Color(0xFF1E1E2C),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(species.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${fish.weightKg} kg • ${fish.lengthCm} cm',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          trailing: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFFB300),
                              side: const BorderSide(color: Color(0xFFFFB300)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: () => _fieldSellFish(fish),
                            child: Text('DOCK-SELL (+${fish.dockSaleValue} 🪙)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
