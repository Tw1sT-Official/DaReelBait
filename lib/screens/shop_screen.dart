import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/equipment.dart';
import '../models/fish.dart';
import '../models/intel.dart';
import '../models/location.dart';
import '../services/angler_storage.dart';

class ShopScreen extends StatefulWidget {
  final int locationId;
  final VoidCallback onStateChanged;

  const ShopScreen({
    super.key,
    required this.locationId,
    required this.onStateChanged,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _coins = 0;
  List<CaughtFish> _coolerFish = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadState();
  }

  void _loadState() {
    setState(() {
      _coins = AnglerStorage.getCoins();
      _coolerFish = AnglerStorage.getCoolerFish();
    });
  }

  void _sellFish(CaughtFish fish) async {
    HapticFeedback.mediumImpact();
    final earned = await AnglerStorage.sellCoolerCatch(fish);
    _loadState();
    widget.onStateChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sold ${fish.species.name} (${fish.weightKg} kg, ${fish.lengthCm} cm) for +$earned 🪙!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _sellAllFish() async {
    if (_coolerFish.isEmpty) return;
    HapticFeedback.heavyImpact();
    final total = await AnglerStorage.sellAllCoolerFish();
    _loadState();
    widget.onStateChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sold entire cooler haul for +$total 🪙!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _buyEquipment(EquipmentItem item) async {
    if (_coins < item.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins! Sell some fish first.'),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await AnglerStorage.spendCoins(item.cost);
    if (item.type == EquipmentType.bait) {
      await AnglerStorage.addBait(item.id, 5); // 5 count bundle
    } else {
      await AnglerStorage.buyItem(item);
    }

    _loadState();
    widget.onStateChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased ${item.name}!'),
          backgroundColor: const Color(0xFF0288D1),
        ),
      );
    }
  }

  void _buyIntel(IntelTip tip) async {
    if (_coins < tip.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins for this intel!'),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    final hasDiary = AnglerStorage.hasDiary();

    HapticFeedback.mediumImpact();
    await AnglerStorage.spendCoins(tip.cost);

    if (hasDiary) {
      await AnglerStorage.saveDiaryTip(tip);
    }

    _loadState();
    widget.onStateChanged();

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A24),
          title: Text(tip.title, style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tip.content, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
              const SizedBox(height: 16),
              if (hasDiary)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF81C784), size: 16),
                    SizedBox(width: 6),
                    Text('Saved to your Angler Notebook!', style: TextStyle(color: Color(0xFF81C784), fontSize: 11)),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Text(
                    '⚠️ You do not own an Angler Notebook!\nMemorize this tip in your head, or buy a Notebook at the counter so it gets recorded forever.',
                    style: TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('GOT IT'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = FishingLocation.getLocation(widget.locationId);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${location.name} Shack', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Local Bait & Tackle', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙 ', style: TextStyle(fontSize: 14)),
                  Text(
                    '$_coins',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'SELL FISH'),
            Tab(text: 'TACKLE & GEAR'),
            Tab(text: 'LOCAL INTEL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSellTab(),
          _buildGearTab(),
          _buildIntelTab(),
        ],
      ),
    );
  }

  Widget _buildSellTab() {
    if (_coolerFish.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 54, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('Your cooler is empty!', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Cast your line and catch some fish to sell here.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    final totalMarket = _coolerFish.fold(0, (sum, f) => sum + f.marketValue);

    return Column(
      children: [
        // Sell All Header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF14141E),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_coolerFish.length} Fish in Cooler', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Total Haul Value: ~$totalMarket 🪙', style: const TextStyle(color: Color(0xFF81C784), fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: _sellAllFish,
                icon: const Icon(Icons.attach_money, size: 16),
                label: const Text('SELL ALL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Fish List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _coolerFish.length,
            itemBuilder: (context, i) {
              final fish = _coolerFish[i];
              final species = fish.species;

              return Card(
                color: const Color(0xFF14141E),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: species.rarityColor.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  title: Text(species.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${fish.weightKg} kg • ${fish.lengthCm} cm • Caught with ${EquipmentDatabase.getItem(fish.baitUsed).name}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _sellFish(fish),
                    child: Text('+${fish.marketValue} 🪙', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGearTab() {
    final availableGear = [
      ...EquipmentDatabase.allTools,
      ...EquipmentDatabase.allCoolers,
      ...EquipmentDatabase.allRods,
      ...EquipmentDatabase.allLines,
      ...EquipmentDatabase.allBaits,
    ].where((item) => item.locationUnlockedAt <= widget.locationId).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: availableGear.length,
      itemBuilder: (context, i) {
        final item = availableGear[i];
        final isOwned = AnglerStorage.hasItem(item.id);
        final isBait = item.type == EquipmentType.bait;
        final baitCount = isBait ? AnglerStorage.getBaitCount(item.id) : 0;

        return Card(
          color: const Color(0xFF14141E),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(item.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          if (isBait) ...[
                            const SizedBox(width: 8),
                            Text('($baitCount in bag)', style: const TextStyle(color: Colors.amber, fontSize: 11)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(item.description, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (isOwned && !isBait)
                  const Text('OWNED', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 12))
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _buyEquipment(item),
                    child: Text(
                      isBait ? '${item.cost} 🪙 (x5)' : '${item.cost} 🪙',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntelTab() {
    final tips = IntelDatabase.getTipsForLocation(widget.locationId);

    if (tips.isEmpty) {
      return const Center(
        child: Text('No rumors available in this area yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tips.length,
      itemBuilder: (context, i) {
        final tip = tips[i];
        final isRecorded = AnglerStorage.hasDiaryTip(tip.id);

        return Card(
          color: const Color(0xFF14141E),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  tip.isDetailed ? Icons.menu_book : Icons.lightbulb,
                  color: tip.isDetailed ? const Color(0xFFFF8F00) : const Color(0xFF4FC3F7),
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(tip.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 6),
                          if (tip.isDetailed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8F00).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('DOSSIER', style: TextStyle(color: Color(0xFFFF8F00), fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tip.isDetailed ? 'Detailed multi-point biological intel' : 'Local angler whisper & rumor',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isRecorded)
                  const Text('RECORDED', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 11))
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tip.isDetailed ? const Color(0xFFFF8F00) : const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _buyIntel(tip),
                    child: Text('${tip.cost} 🪙', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
