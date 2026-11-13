import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/equipment.dart';
import '../models/fish.dart';
import '../models/intel.dart';

class AnglerStorage {
  static SharedPreferences? _prefs;

  static const String _keyCoins = 'angler_coins';
  static const String _keyZen = 'angler_zen_xp';
  static const String _keyLocation = 'angler_location_id';
  static const String _keyOwnedItems = 'angler_owned_items';
  static const String _keyEquippedRod = 'angler_equipped_rod';
  static const String _keyEquippedLine = 'angler_equipped_line';
  static const String _keyEquippedBait = 'angler_equipped_bait';
  static const String _keyEquippedCooler = 'angler_equipped_cooler';
  static const String _keyBaitInventory = 'angler_bait_inventory';
  static const String _keyCoolerFish = 'angler_cooler_fish';
  static const String _keyLogbookRecords = 'angler_logbook_records';
  static const String _keyDiaryTips = 'angler_diary_tips';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Default starter kit
    if (!_prefs!.containsKey(_keyCoins)) {
      await _prefs!.setInt(_keyCoins, 60); // 60 starter coins
      await _prefs!.setInt(_keyZen, 0);
      await _prefs!.setInt(_keyLocation, 1); // Whispering Willow Lake
      await _prefs!.setStringList(_keyOwnedItems, [
        'cooler_woven',
        'rod_bamboo',
        'line_mono',
        'earthworms',
        'bread_dough',
      ]);
      await _prefs!.setString(_keyEquippedRod, 'rod_bamboo');
      await _prefs!.setString(_keyEquippedLine, 'line_mono');
      await _prefs!.setString(_keyEquippedBait, 'earthworms');
      await _prefs!.setString(_keyEquippedCooler, 'cooler_woven');

      // 10 earthworms and 10 bread dough to start
      final initialBaits = {'earthworms': 10, 'bread_dough': 10};
      await _prefs!.setString(_keyBaitInventory, jsonEncode(initialBaits));
    }
  }

  // --- Economy: Coins & Zen ---
  static int getCoins() => _prefs?.getInt(_keyCoins) ?? 60;

  static Future<void> addCoins(int amount) async {
    final current = getCoins();
    await _prefs?.setInt(_keyCoins, current + amount);
  }

  static Future<bool> spendCoins(int amount) async {
    final current = getCoins();
    if (current < amount) return false;
    await _prefs?.setInt(_keyCoins, current - amount);
    return true;
  }

  static int getZen() => _prefs?.getInt(_keyZen) ?? 0;

  // Zen Rank: Level 1 at 0 XP, Level 2 at 100 XP, Level 3 at 250 XP, etc.
  static int getZenRank() {
    final zen = getZen();
    if (zen < 100) return 1;
    if (zen < 250) return 2;
    if (zen < 450) return 3;
    if (zen < 700) return 4;
    if (zen < 1050) return 5;
    if (zen < 1500) return 6;
    if (zen < 2050) return 7;
    if (zen < 2700) return 8;
    if (zen < 3500) return 9;
    if (zen < 4500) return 10;
    if (zen < 5700) return 11;
    return 12; // Master Angler
  }

  static Future<void> addZen(int amount) async {
    final current = getZen();
    await _prefs?.setInt(_keyZen, current + amount);
  }

  // --- Location ---
  static int getCurrentLocationId() => _prefs?.getInt(_keyLocation) ?? 1;

  static Future<void> setLocation(int locationId) async {
    await _prefs?.setInt(_keyLocation, locationId);
  }

  // --- Equipment & Tools ---
  static List<String> getOwnedItems() {
    return _prefs?.getStringList(_keyOwnedItems) ?? ['cooler_woven', 'rod_bamboo', 'line_mono'];
  }

  static bool hasItem(String itemId) {
    return getOwnedItems().contains(itemId);
  }

  static bool hasScaleAndTape() => hasItem('tool_scale_tape');
  static bool hasCamera() => hasItem('tool_camera');
  static bool hasLogbook() => hasItem('tool_logbook');
  static bool hasDiary() => hasItem('tool_diary');
  static bool hasWatch() => hasItem('tool_watch');

  static Future<void> buyItem(EquipmentItem item) async {
    final owned = getOwnedItems();
    if (!owned.contains(item.id)) {
      owned.add(item.id);
      await _prefs?.setStringList(_keyOwnedItems, owned);
    }

    // Auto-equip if cooler, rod, or line
    if (item.type == EquipmentType.cooler) {
      await _prefs?.setString(_keyEquippedCooler, item.id);
    } else if (item.type == EquipmentType.rod) {
      await _prefs?.setString(_keyEquippedRod, item.id);
    } else if (item.type == EquipmentType.line) {
      await _prefs?.setString(_keyEquippedLine, item.id);
    }
  }

  static String getEquippedRodId() => _prefs?.getString(_keyEquippedRod) ?? 'rod_bamboo';
  static String getEquippedLineId() => _prefs?.getString(_keyEquippedLine) ?? 'line_mono';
  static String getEquippedBaitId() => _prefs?.getString(_keyEquippedBait) ?? 'earthworms';
  static String getEquippedCoolerId() => _prefs?.getString(_keyEquippedCooler) ?? 'cooler_woven';

  static EquipmentItem getEquippedRod() => EquipmentDatabase.getItem(getEquippedRodId());
  static EquipmentItem getEquippedLine() => EquipmentDatabase.getItem(getEquippedLineId());
  static EquipmentItem getEquippedCooler() => EquipmentDatabase.getItem(getEquippedCoolerId());

  static Future<void> equipRod(String rodId) async => await _prefs?.setString(_keyEquippedRod, rodId);
  static Future<void> equipLine(String lineId) async => await _prefs?.setString(_keyEquippedLine, lineId);
  static Future<void> equipBait(String baitId) async => await _prefs?.setString(_keyEquippedBait, baitId);

  // --- Bait Inventory ---
  static Map<String, int> getBaitInventory() {
    final raw = _prefs?.getString(_keyBaitInventory);
    if (raw == null) return {'earthworms': 10};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {'earthworms': 10};
    }
  }

  static bool isInfiniteBait(String baitId) {
    return baitId == 'earthworms' || baitId == 'bread_dough';
  }

  static int getBaitCount(String baitId) {
    if (isInfiniteBait(baitId)) return 999;
    return getBaitInventory()[baitId] ?? 0;
  }

  static Future<void> addBait(String baitId, int count) async {
    final map = getBaitInventory();
    map[baitId] = (map[baitId] ?? 0) + count;
    await _prefs?.setString(_keyBaitInventory, jsonEncode(map));
  }

  static Future<bool> consumeEquippedBait() async {
    final currentBait = getEquippedBaitId();
    if (isInfiniteBait(currentBait)) {
      return true; // Infinite starter bait! Cannot be softlocked!
    }
    final map = getBaitInventory();
    final count = map[currentBait] ?? 0;
    if (count <= 0) return false;

    map[currentBait] = count - 1;
    await _prefs?.setString(_keyBaitInventory, jsonEncode(map));
    return true;
  }

  // --- Cooler Fish Inventory & Capacity ---
  static List<CaughtFish> getCoolerFish() {
    final rawList = _prefs?.getStringList(_keyCoolerFish) ?? [];
    return rawList.map((str) => CaughtFish.fromJson(jsonDecode(str) as Map<String, dynamic>)).toList();
  }

  static double getCoolerTotalWeightKg() {
    final fishList = getCoolerFish();
    return fishList.fold(0.0, (sum, f) => sum + f.weightKg);
  }

  static double getCoolerMaxCapacityKg() {
    final cooler = getEquippedCooler();
    return cooler.capacityKg > 0 ? cooler.capacityKg : 10.0;
  }

  static bool hasCoolerRoomFor(double fishWeightKg) {
    final currentWeight = getCoolerTotalWeightKg();
    final maxWeight = getCoolerMaxCapacityKg();
    return (currentWeight + fishWeightKg) <= maxWeight;
  }

  static Future<void> addToCooler(CaughtFish fish) async {
    final fishList = getCoolerFish();
    fishList.add(fish);
    final rawList = fishList.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs?.setStringList(_keyCoolerFish, rawList);
  }

  static Future<void> removeFromCooler(String catchId) async {
    final fishList = getCoolerFish();
    fishList.removeWhere((f) => f.id == catchId);
    final rawList = fishList.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs?.setStringList(_keyCoolerFish, rawList);
  }

  static Future<int> sellCoolerCatch(CaughtFish fish) async {
    // Market examination reveals stats
    fish.isExamined = true;
    final value = fish.marketValue;
    await addCoins(value);
    await removeFromCooler(fish.id);
    await recordLogbookCatch(fish);
    return value;
  }

  static Future<int> fieldSellCoolerCatch(CaughtFish fish) async {
    final value = fish.dockSaleValue;
    await addCoins(value);
    await removeFromCooler(fish.id);
    await recordLogbookCatch(fish);
    return value;
  }

  static Future<int> sellAllCoolerFish() async {
    final fishList = getCoolerFish();
    int totalEarned = 0;
    for (final fish in fishList) {
      fish.isExamined = true;
      totalEarned += fish.marketValue;
      await recordLogbookCatch(fish);
    }
    await addCoins(totalEarned);
    await _prefs?.setStringList(_keyCoolerFish, []);
    return totalEarned;
  }

  // --- Logbook Records & Personal Bests ---
  static Map<String, dynamic> getLogbookRecords() {
    final raw = _prefs?.getString(_keyLogbookRecords);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> recordLogbookCatch(CaughtFish fish) async {
    final records = getLogbookRecords();
    final speciesId = fish.speciesId;

    final existing = records[speciesId] as Map<String, dynamic>?;
    if (existing == null) {
      records[speciesId] = {
        'count': 1,
        'bestLengthCm': fish.lengthCm,
        'bestWeightKg': fish.weightKg,
        'firstCaughtAt': fish.caughtAt.toIso8601String(),
        'bestCaughtAt': fish.caughtAt.toIso8601String(),
      };
    } else {
      final currentBestWeight = (existing['bestWeightKg'] as num).toDouble();
      final currentBestLength = (existing['bestLengthCm'] as num).toDouble();
      final count = (existing['count'] as int) + 1;

      records[speciesId] = {
        'count': count,
        'bestLengthCm': max(currentBestLength, fish.lengthCm),
        'bestWeightKg': max(currentBestWeight, fish.weightKg),
        'firstCaughtAt': existing['firstCaughtAt'],
        'bestCaughtAt': fish.weightKg > currentBestWeight ? fish.caughtAt.toIso8601String() : existing['bestCaughtAt'],
      };
    }

    await _prefs?.setString(_keyLogbookRecords, jsonEncode(records));
  }

  // --- Angler's Diary (Saved Notes & Intel) ---
  static List<IntelTip> getDiaryTips() {
    final rawList = _prefs?.getStringList(_keyDiaryTips) ?? [];
    return rawList.map((str) => IntelTip.fromJson(jsonDecode(str) as Map<String, dynamic>)).toList();
  }

  static bool hasDiaryTip(String tipId) {
    return getDiaryTips().any((t) => t.id == tipId);
  }

  static Future<void> saveDiaryTip(IntelTip tip) async {
    final tips = getDiaryTips();
    if (!tips.any((t) => t.id == tip.id)) {
      tips.add(tip);
      final rawList = tips.map((t) => jsonEncode(t.toJson())).toList();
      await _prefs?.setStringList(_keyDiaryTips, rawList);
    }
  }
}
