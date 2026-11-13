import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/equipment.dart';
import '../services/angler_storage.dart';

class TackleBoxDialog extends StatefulWidget {
  final VoidCallback onEquipChanged;

  const TackleBoxDialog({super.key, required this.onEquipChanged});

  @override
  State<TackleBoxDialog> createState() => _TackleBoxDialogState();
}

class _TackleBoxDialogState extends State<TackleBoxDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final equippedRod = AnglerStorage.getEquippedRodId();
    final equippedLine = AnglerStorage.getEquippedLineId();
    final equippedBait = AnglerStorage.getEquippedBaitId();
    final ownedItems = AnglerStorage.getOwnedItems();
    final baitInventory = AnglerStorage.getBaitInventory();

    final ownedRods = EquipmentDatabase.allRods.where((r) => ownedItems.contains(r.id)).toList();
    final ownedLines = EquipmentDatabase.allLines.where((l) => ownedItems.contains(l.id)).toList();
    final ownedBaits = EquipmentDatabase.allBaits.where((b) => AnglerStorage.isInfiniteBait(b.id) || (baitInventory[b.id] ?? 0) > 0).toList();

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
                const Row(
                  children: [
                    Text('🧰 ', style: TextStyle(fontSize: 20)),
                    Text("Angler's Tackle Box", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF00E5FF),
            labelColor: const Color(0xFF00E5FF),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'BAIT / LURES'),
              Tab(text: 'RODS'),
              Tab(text: 'LINES'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Baits
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: ownedBaits.isEmpty
                      ? [const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No baits in your bag! Visit the Tackle Shack.', style: TextStyle(color: Colors.grey))))]
                      : ownedBaits.map((bait) {
                          final isEquipped = equippedBait == bait.id;
                          final count = baitInventory[bait.id] ?? 0;

                          return Card(
                            color: const Color(0xFF1E1E2C),
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isEquipped ? const Color(0xFF00E5FF) : Colors.transparent, width: 1.5),
                            ),
                            child: ListTile(
                              leading: Text(bait.icon, style: const TextStyle(fontSize: 24)),
                              title: Text(bait.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                AnglerStorage.isInfiniteBait(bait.id)
                                    ? '∞ Unlimited (Free Starter Bait) • ${bait.description}'
                                    : '$count remaining • ${bait.description}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEquipped ? const Color(0xFF00E5FF) : Colors.white12,
                                  foregroundColor: isEquipped ? Colors.black : Colors.white,
                                ),
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  await AnglerStorage.equipBait(bait.id);
                                  widget.onEquipChanged();
                                  setState(() {});
                                },
                                child: Text(isEquipped ? 'HOOKED' : 'USE'),
                              ),
                            ),
                          );
                        }).toList(),
                ),

                // Rods
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: ownedRods.map((rod) {
                    final isEquipped = equippedRod == rod.id;
                    return Card(
                      color: const Color(0xFF1E1E2C),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isEquipped ? const Color(0xFF00E5FF) : Colors.transparent, width: 1.5),
                      ),
                      child: ListTile(
                        leading: Text(rod.icon, style: const TextStyle(fontSize: 24)),
                        title: Text(rod.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(rod.description, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEquipped ? const Color(0xFF00E5FF) : Colors.white12,
                            foregroundColor: isEquipped ? Colors.black : Colors.white,
                          ),
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            await AnglerStorage.equipRod(rod.id);
                            widget.onEquipChanged();
                            setState(() {});
                          },
                          child: Text(isEquipped ? 'EQUIPPED' : 'EQUIP'),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Lines
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: ownedLines.map((line) {
                    final isEquipped = equippedLine == line.id;
                    return Card(
                      color: const Color(0xFF1E1E2C),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isEquipped ? const Color(0xFF00E5FF) : Colors.transparent, width: 1.5),
                      ),
                      child: ListTile(
                        leading: Text(line.icon, style: const TextStyle(fontSize: 24)),
                        title: Text(line.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(line.description, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEquipped ? const Color(0xFF00E5FF) : Colors.white12,
                            foregroundColor: isEquipped ? Colors.black : Colors.white,
                          ),
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            await AnglerStorage.equipLine(line.id);
                            widget.onEquipChanged();
                            setState(() {});
                          },
                          child: Text(isEquipped ? 'SPOOLED' : 'SPOOL'),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
