import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/angler_storage.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasDiary = AnglerStorage.hasDiary();
    final tips = AnglerStorage.getDiaryTips();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181824),
        title: const Row(
          children: [
            Text('📓 ', style: TextStyle(fontSize: 20)),
            Text("Angler's Field Diary", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: !hasDiary
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 72, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'Notebook Not Owned',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You have not purchased an Angler’s Field Notebook yet!\n\nWithout a notebook, all tips and rumors purchased from local tackle shopkeepers must be memorized in your head.\n\nBuy a notebook at any Tackle Shack to automatically record all field intel forever.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            )
          : tips.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Your notebook is blank!\n\nVisit local Tackle Shacks across the 12 angling spots and purchase rumors or species dossiers to fill these pages.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.4),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tips.length,
                  itemBuilder: (context, i) {
                    final tip = tips[i];
                    final loc = FishingLocation.getLocation(tip.locationId);

                    return Card(
                      color: const Color(0xFF181826),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: tip.isDetailed ? const Color(0xFFFF8F00).withValues(alpha: 0.6) : Colors.white10,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  tip.isDetailed ? Icons.menu_book : Icons.lightbulb,
                                  color: tip.isDetailed ? const Color(0xFFFF8F00) : const Color(0xFF4FC3F7),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tip.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                Text(
                                  loc.name,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white12, height: 16),
                            Text(
                              tip.content,
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.45),
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
