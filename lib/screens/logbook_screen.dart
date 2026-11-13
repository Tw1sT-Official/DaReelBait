import 'package:flutter/material.dart';
import '../models/fish.dart';
import '../services/angler_storage.dart';

class LogbookScreen extends StatelessWidget {
  const LogbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasLogbook = AnglerStorage.hasLogbook();
    final records = AnglerStorage.getLogbookRecords();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181824),
        title: const Row(
          children: [
            Text('📖 ', style: TextStyle(fontSize: 20)),
            Text("Angler's Field Logbook", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: !hasLogbook
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book, size: 72, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'Logbook Not Owned',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You have not purchased a Leather Fish Logbook yet!\n\nVisit any local Tackle Shack to buy your album so your catch records, certified lengths, and photos are permanently cataloged.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: FishDatabase.allSpecies.length,
              itemBuilder: (context, i) {
                final species = FishDatabase.allSpecies[i];
                final record = records[species.id] as Map<String, dynamic>?;
                final isCaught = record != null;

                final count = isCaught ? (record['count'] as int) : 0;
                final bestWeight = isCaught ? (record['bestWeightKg'] as num).toDouble() : 0.0;
                final bestLength = isCaught ? (record['bestLengthCm'] as num).toDouble() : 0.0;

                return Card(
                  color: const Color(0xFF161622),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isCaught ? species.rarityColor.withValues(alpha: 0.5) : Colors.white10,
                      width: isCaught ? 1.5 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Fish Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCaught ? species.primaryColor.withValues(alpha: 0.2) : Colors.white10,
                            border: Border.all(color: isCaught ? species.primaryColor : Colors.white24),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.phishing,
                              color: isCaught ? species.primaryColor : Colors.white24,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isCaught ? species.name : 'Unknown Species ???',
                                    style: TextStyle(
                                      color: isCaught ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isCaught)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: species.rarityColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        species.rarityName,
                                        style: TextStyle(color: species.rarityColor, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isCaught ? species.description : 'Explore the 12 angling waters to discover this fish.',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              if (isCaught) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text('Best: ${bestWeight.toStringAsFixed(2)} kg, ${bestLength.toStringAsFixed(1)} cm',
                                        style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    Text('Caught: $count', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
