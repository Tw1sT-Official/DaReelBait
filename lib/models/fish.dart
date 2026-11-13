import 'dart:math';
import 'package:flutter/material.dart';

enum FishRarity {
  common,
  uncommon,
  rare,
  trophy,
  legendary,
}

enum WaterDepth {
  surface,
  midWater,
  deep,
  bottom,
}

class FishSpecies {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final FishRarity rarity;
  final double minLengthCm;
  final double maxLengthCm;
  final double minWeightKg;
  final double maxWeightKg;
  final double girthRatio; // body thickness compared to length (0.15 = slender, 0.35 = round/thick)
  final WaterDepth preferredDepth;
  final List<String> favoriteBaits;
  final List<int> locationIds;
  final List<int> activeHours; // e.g. [5,6,7,8,17,18,19] or all 24
  final Color primaryColor;
  final Color secondaryColor;
  final Color bellyColor;
  final int baseMarketPricePerKg;

  const FishSpecies({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.rarity,
    required this.minLengthCm,
    required this.maxLengthCm,
    required this.minWeightKg,
    required this.maxWeightKg,
    this.girthRatio = 0.25,
    required this.preferredDepth,
    required this.favoriteBaits,
    required this.locationIds,
    required this.activeHours,
    required this.primaryColor,
    required this.secondaryColor,
    this.bellyColor = const Color(0xFFF5F5F0),
    required this.baseMarketPricePerKg,
  });

  String get rarityName {
    switch (rarity) {
      case FishRarity.common:
        return 'COMMON';
      case FishRarity.uncommon:
        return 'UNCOMMON';
      case FishRarity.rare:
        return 'RARE';
      case FishRarity.trophy:
        return 'TROPHY';
      case FishRarity.legendary:
        return 'LEGENDARY';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case FishRarity.common:
        return const Color(0xFF81C784); // Green
      case FishRarity.uncommon:
        return const Color(0xFF4FC3F7); // Blue
      case FishRarity.rare:
        return const Color(0xFFBA68C8); // Purple
      case FishRarity.trophy:
        return const Color(0xFFFFB74D); // Amber
      case FishRarity.legendary:
        return const Color(0xFFFF5252); // Crimson Gold
    }
  }

  bool isFavoriteBait(String baitId) {
    return favoriteBaits.contains(baitId);
  }

  bool isActiveAtHour(int hour) {
    return activeHours.isEmpty || activeHours.contains(hour);
  }
}

class CaughtFish {
  final String id;
  final String speciesId;
  final double lengthCm;
  final double weightKg;
  final double girthCm;
  final DateTime caughtAt;
  final int locationId;
  final String baitUsed;
  bool isExamined; // whether length/weight are known by player (via scale/tape or shopkeeper)

  CaughtFish({
    required this.id,
    required this.speciesId,
    required this.lengthCm,
    required this.weightKg,
    required this.girthCm,
    required this.caughtAt,
    required this.locationId,
    required this.baitUsed,
    this.isExamined = false,
  });

  FishSpecies get species => FishDatabase.getSpecies(speciesId);

  int get marketValue {
    final value = (weightKg * species.baseMarketPricePerKg).round();
    return max(value, 3);
  }

  int get dockSaleValue {
    // 60% of market value when emergency sold to dock fishermen
    return max((marketValue * 0.6).round(), 1);
  }

  int get zenValue {
    // Zen XP gained if released
    int baseZen = 15;
    switch (species.rarity) {
      case FishRarity.common:
        baseZen = 15;
        break;
      case FishRarity.uncommon:
        baseZen = 30;
        break;
      case FishRarity.rare:
        baseZen = 60;
        break;
      case FishRarity.trophy:
        baseZen = 120;
        break;
      case FishRarity.legendary:
        baseZen = 250;
        break;
    }
    return baseZen + (weightKg * 4).round();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'speciesId': speciesId,
        'lengthCm': lengthCm,
        'weightKg': weightKg,
        'girthCm': girthCm,
        'caughtAt': caughtAt.toIso8601String(),
        'locationId': locationId,
        'baitUsed': baitUsed,
        'isExamined': isExamined,
      };

  factory CaughtFish.fromJson(Map<String, dynamic> json) => CaughtFish(
        id: json['id'] as String,
        speciesId: json['speciesId'] as String,
        lengthCm: (json['lengthCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        girthCm: (json['girthCm'] as num).toDouble(),
        caughtAt: DateTime.parse(json['caughtAt'] as String),
        locationId: json['locationId'] as int,
        baitUsed: json['baitUsed'] as String,
        isExamined: json['isExamined'] as bool? ?? false,
      );
}

class FishDatabase {
  static final List<FishSpecies> allSpecies = [
    // ==========================================
    // 1. Whispering Willow Lake (1-15)
    // ==========================================
    const FishSpecies(
      id: 'bluegill',
      name: 'Bluegill',
      scientificName: 'Lepomis macrochirus',
      description: 'A classic saucer-shaped sunfish with a dark ear flap and vibrant orange breast.',
      rarity: FishRarity.common,
      minLengthCm: 12.0,
      maxLengthCm: 22.0,
      minWeightKg: 0.15,
      maxWeightKg: 0.65,
      girthRatio: 0.35,
      preferredDepth: WaterDepth.surface,
      favoriteBaits: ['earthworms', 'bread_dough'],
      locationIds: [1, 2, 4],
      activeHours: [6, 7, 8, 9, 10, 11, 14, 15, 16, 17, 18],
      primaryColor: Color(0xFF4A6B82),
      secondaryColor: Color(0xFFE6953B),
      bellyColor: Color(0xFFFFB74D),
      baseMarketPricePerKg: 18,
    ),
    const FishSpecies(
      id: 'pumpkinseed',
      name: 'Pumpkinseed Sunfish',
      scientificName: 'Lepomis gibbosus',
      description: 'Luminous olive and turquoise body with bright crimson spot on its gill cover.',
      rarity: FishRarity.common,
      minLengthCm: 10.0,
      maxLengthCm: 20.0,
      minWeightKg: 0.12,
      maxWeightKg: 0.45,
      girthRatio: 0.38,
      preferredDepth: WaterDepth.surface,
      favoriteBaits: ['earthworms', 'bread_dough'],
      locationIds: [1, 4],
      activeHours: [7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      primaryColor: Color(0xFF558B2F),
      secondaryColor: Color(0xFF00ACC1),
      bellyColor: Color(0xFFFF8A65),
      baseMarketPricePerKg: 20,
    ),
    const FishSpecies(
      id: 'yellow_perch',
      name: 'Yellow Perch',
      scientificName: 'Perca flavescens',
      description: 'Golden yellow body marked by six to eight prominent dark vertical tiger bars.',
      rarity: FishRarity.common,
      minLengthCm: 15.0,
      maxLengthCm: 32.0,
      minWeightKg: 0.25,
      maxWeightKg: 1.10,
      girthRatio: 0.26,
      preferredDepth: WaterDepth.midWater,
      favoriteBaits: ['earthworms', 'live_minnows'],
      locationIds: [1, 2, 4, 8],
      activeHours: [6, 7, 8, 16, 17, 18, 19],
      primaryColor: Color(0xFFF9A825),
      secondaryColor: Color(0xFF33691E),
      bellyColor: Color(0xFFFFF9C4),
      baseMarketPricePerKg: 24,
    ),
    const FishSpecies(
      id: 'black_crappie',
      name: 'Black Crappie',
      scientificName: 'Pomoxis nigromaculatus',
      description: 'Silvery-olive panfish mottled with dark irregular spots and paper-thin mouth.',
      rarity: FishRarity.common,
      minLengthCm: 18.0,
      maxLengthCm: 36.0,
      minWeightKg: 0.35,
      maxWeightKg: 1.40,
      girthRatio: 0.30,
      preferredDepth: WaterDepth.midWater,
      favoriteBaits: ['live_minnows', 'earthworms'],
      locationIds: [1, 5, 8],
      activeHours: [5, 6, 7, 17, 18, 19, 20],
      primaryColor: Color(0xFF78909C),
      secondaryColor: Color(0xFF263238),
      bellyColor: Color(0xFFECEFF1),
      baseMarketPricePerKg: 26,
    ),
    const FishSpecies(
      id: 'largemouth_bass',
      name: 'Largemouth Bass',
      scientificName: 'Micropterus salmoides',
      description: 'Aggressive top predator of warm lakes, known for explosive surface lunges and jumps.',
      rarity: FishRarity.uncommon,
      minLengthCm: 30.0,
      maxLengthCm: 65.0,
      minWeightKg: 1.10,
      maxWeightKg: 5.80,
      girthRatio: 0.32,
      preferredDepth: WaterDepth.surface,
      favoriteBaits: ['live_minnows', 'surface_poppers'],
      locationIds: [1, 4, 6],
      activeHours: [5, 6, 7, 8, 17, 18, 19],
      primaryColor: Color(0xFF33691E),
      secondaryColor: Color(0xFF1B5E20),
      bellyColor: Color(0xFFF1F8E9),
      baseMarketPricePerKg: 35,
    ),
    const FishSpecies(
      id: 'channel_catfish',
      name: 'Channel Catfish',
      scientificName: 'Ictalurus punctatus',
      description: 'Whiskered bottom-hugger with smooth scaleless skin and strong olfactory barbels.',
      rarity: FishRarity.rare,
      minLengthCm: 40.0,
      maxLengthCm: 88.0,
      minWeightKg: 2.50,
      maxWeightKg: 11.50,
      girthRatio: 0.28,
      preferredDepth: WaterDepth.bottom,
      favoriteBaits: ['cut_bait', 'earthworms'],
      locationIds: [1, 6, 8],
      activeHours: [19, 20, 21, 22, 23, 0, 1, 2, 3, 4, 5],
      primaryColor: Color(0xFF455A64),
      secondaryColor: Color(0xFF263238),
      bellyColor: Color(0xFFCFD8DC),
      baseMarketPricePerKg: 38,
    ),
    const FishSpecies(
      id: 'grand_solar_bass',
      name: 'Grand Solar Bass',
      scientificName: 'Micropterus aureum',
      description: 'A radiant golden-scaled trophy bass that only stalks the reed shallows at sunset.',
      rarity: FishRarity.legendary,
      minLengthCm: 55.0,
      maxLengthCm: 78.0,
      minWeightKg: 5.50,
      maxWeightKg: 9.80,
      girthRatio: 0.34,
      preferredDepth: WaterDepth.surface,
      favoriteBaits: ['live_minnows', 'surface_poppers'],
      locationIds: [1],
      activeHours: [17, 18, 19],
      primaryColor: Color(0xFFFFB300),
      secondaryColor: Color(0xFFFF6F00),
      bellyColor: Color(0xFFFFF8E1),
      baseMarketPricePerKg: 75,
    ),

    // ==========================================
    // 2. Old Miller's Creek (16-25)
    // ==========================================
    const FishSpecies(
      id: 'creek_chub',
      name: 'Creek Chub',
      scientificName: 'Semotilus atromaculatus',
      description: 'Quick-darting stream minnow with a prominent black spot at the base of its dorsal fin.',
      rarity: FishRarity.common,
      minLengthCm: 10.0,
      maxLengthCm: 22.0,
      minWeightKg: 0.10,
      maxWeightKg: 0.45,
      girthRatio: 0.22,
      preferredDepth: WaterDepth.surface,
      favoriteBaits: ['bread_dough', 'earthworms'],
      locationIds: [2, 3],
      activeHours: [],
      primaryColor: Color(0xFF6D4C41),
      secondaryColor: Color(0xFF3E2723),
      bellyColor: Color(0xFFEFEBE9),
      baseMarketPricePerKg: 15,
    ),
    const FishSpecies(
      id: 'yellow_bullhead',
      name: 'Yellow Bullhead',
      scientificName: 'Ameiurus natalis',
      description: 'Stocky, docile whiskered catfish residing under shady sunken mill timbers.',
      rarity: FishRarity.uncommon,
      minLengthCm: 20.0,
      maxLengthCm: 42.0,
      minWeightKg: 0.50,
      maxWeightKg: 2.10,
      girthRatio: 0.30,
      preferredDepth: WaterDepth.bottom,
      favoriteBaits: ['cut_bait', 'earthworms'],
      locationIds: [2, 6],
      activeHours: [18, 19, 20, 21, 22, 23, 0, 1],
      primaryColor: Color(0xFF827717),
      secondaryColor: Color(0xFF558B2F),
      bellyColor: Color(0xFFFFFDE7),
      baseMarketPricePerKg: 28,
    ),
    const FishSpecies(
      id: 'river_dace',
      name: 'River Dace',
      scientificName: 'Leuciscus leuciscus',
      description: 'Slender, energetic silver fish with bright yellow fins, loving gentle creek currents.',
      rarity: FishRarity.common,
      minLengthCm: 14.0,
      maxLengthCm: 28.0,
      minWeightKg: 0.18,
      maxWeightKg: 0.60,
      girthRatio: 0.22,
      preferredDepth: WaterDepth.midWater,
      favoriteBaits: ['sweet_corn', 'earthworms'],
      locationIds: [2, 3],
      activeHours: [6, 7, 8, 9, 15, 16, 17, 18],
      primaryColor: Color(0xFF90A4AE),
      secondaryColor: Color(0xFFCFD8DC),
      bellyColor: Color(0xFFFFFFFF),
      baseMarketPricePerKg: 22,
    ),

    // ==========================================
    // 3. Misty Pine River (Alpine Trout & Salmon)
    // ==========================================
    const FishSpecies(
      id: 'brook_trout',
      name: 'Brook Trout',
      scientificName: 'Salvelinus fontinalis',
      description: 'Intricately marbled olive back with bright red halo spots and snowy-edged fins.',
      rarity: FishRarity.uncommon,
      minLengthCm: 20.0,
      maxLengthCm: 42.0,
      minWeightKg: 0.45,
      maxWeightKg: 2.20,
      girthRatio: 0.25,
      preferredDepth: WaterDepth.midWater,
      favoriteBaits: ['metal_spoons', 'earthworms'],
      locationIds: [3, 7],
      activeHours: [6, 7, 8, 9, 16, 17, 18],
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFFC62828),
      bellyColor: Color(0xFFFF8A65),
      baseMarketPricePerKg: 42,
    ),
    const FishSpecies(
      id: 'rainbow_trout',
      name: 'Rainbow Trout',
      scientificName: 'Oncorhynchus mykiss',
      description: 'Famous alpine river acrobat adorned with a vivid iridescent magenta lateral stripe.',
      rarity: FishRarity.uncommon,
      minLengthCm: 28.0,
      maxLengthCm: 60.0,
      minWeightKg: 0.90,
      maxWeightKg: 4.50,
      girthRatio: 0.26,
      preferredDepth: WaterDepth.surface,
      favoriteBaits: ['surface_poppers', 'metal_spoons'],
      locationIds: [3, 7],
      activeHours: [6, 7, 8, 17, 18, 19],
      primaryColor: Color(0xFF388E3C),
      secondaryColor: Color(0xFFE91E63),
      bellyColor: Color(0xFFF1F8E9),
      baseMarketPricePerKg: 48,
    ),
    const FishSpecies(
      id: 'sockeye_salmon',
      name: 'Sockeye Salmon',
      scientificName: 'Oncorhynchus nerka',
      description: 'Fiery crimson upstream migrant with an olive hooked jaw and tremendous burst stamina.',
      rarity: FishRarity.rare,
      minLengthCm: 45.0,
      maxLengthCm: 72.0,
      minWeightKg: 2.40,
      maxWeightKg: 7.20,
      girthRatio: 0.28,
      preferredDepth: WaterDepth.midWater,
      favoriteBaits: ['metal_spoons', 'live_minnows'],
      locationIds: [3, 7],
      activeHours: [5, 6, 7, 8, 17, 18],
      primaryColor: Color(0xFFC62828),
      secondaryColor: Color(0xFF2E7D32),
      bellyColor: Color(0xFFFFCDD2),
      baseMarketPricePerKg: 55,
    ),
    const FishSpecies(
      id: 'river_king_chinook',
      name: 'River King Chinook',
      scientificName: 'Oncorhynchus tshawytscha',
      description: 'The titanic emperor of alpine rivers, capable of smoking reels and snapping light line.',
      rarity: FishRarity.legendary,
      minLengthCm: 72.0,
      maxLengthCm: 122.0,
      minWeightKg: 9.50,
      maxWeightKg: 26.50,
      girthRatio: 0.32,
      preferredDepth: WaterDepth.deep,
      favoriteBaits: ['metal_spoons', 'live_minnows'],
      locationIds: [3],
      activeHours: [18, 19, 20, 5, 6],
      primaryColor: Color(0xFF455A64),
      secondaryColor: Color(0xFF90A4AE),
      bellyColor: Color(0xFFECEFF1),
      baseMarketPricePerKg: 85,
    ),

    // ==========================================
    // 5. Twilight Lotus Pond (Koi, Arowana, Carp)
    // ==========================================
    const FishSpecies(
      id: 'crucian_carp',
      name: 'Crucian Carp',
      scientificName: 'Carassius carassius',
      description: 'Broad, tranquil golden-bronze carp with a high arched back and calm gentle feeding habits.',
      rarity: FishRarity.common,
      minLengthCm: 20.0,
      maxLengthCm: 38.0,
      minWeightKg: 0.60,
      maxWeightKg: 2.20,
      girthRatio: 0.36,
      preferredDepth: WaterDepth.bottom,
      favoriteBaits: ['sweet_corn', 'bread_dough'],
      locationIds: [5],
      activeHours: [],
      primaryColor: Color(0xFFA1887F),
      secondaryColor: Color(0xFFD7CCC8),
      bellyColor: Color(0xFFFFF8E1),
      baseMarketPricePerKg: 25,
    ),
    const FishSpecies(
      id: 'japanese_kohaku_koi',
      name: 'Kohaku Koi',
      scientificName: 'Cyprinus carpio kohaku',
      description: 'Pristine porcelain-white body adorned with brilliant, deep crimson scarlet patches.',
      rarity: FishRarity.rare,
      minLengthCm: 35.0,
      maxLengthCm: 75.0,
      minWeightKg: 2.20,
      maxWeightKg: 8.50,
      girthRatio: 0.30,
      preferredDepth: WaterDepth.midWater,
      favoriteBaits: ['sweet_corn', 'bread_dough'],
      locationIds: [5],
      activeHours: [16, 17, 18, 19, 20],
      primaryColor: Color(0xFFFFFFFF),
      secondaryColor: Color(0xFFD50000),
      bellyColor: Color(0xFFFAFAFA),
      baseMarketPricePerKg: 65,
    ),
    const FishSpecies(
      id: 'golden_dragon_arowana',
      name: 'Dragon Arowana',
      scientificName: 'Scleropages formosus',
      description: 'Ancient armored scales glistening like solid gold, possessing chin barbels of fortune.',
      rarity: FishRarity.trophy,
      minLengthCm: 50.0,
      maxLengthCm: 92.0,
      minWeightKg: 3.50,
      maxWeightKg: 9.80,
      girthRatio: 0.22,
      preferredDepth: WaterDepth.surface,
      favoriteBaits: ['live_minnows', 'surface_poppers'],
      locationIds: [5],
      activeHours: [18, 19, 20, 21, 22],
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFFF8F00),
      bellyColor: Color(0xFFFFF9C4),
      baseMarketPricePerKg: 90,
    ),

    // ==========================================
    // 6. Sunken Cypress Bayou (Gar & Swamp Predators)
    // ==========================================
    const FishSpecies(
      id: 'longnose_gar',
      name: 'Longnose Gar',
      scientificName: 'Lepisosteus osseus',
      description: 'Prehistoric predatory needle-snouted fish with diamond-hard ganoid armored scales.',
      rarity: FishRarity.rare,
      minLengthCm: 60.0,
      maxLengthCm: 118.0,
      minWeightKg: 3.20,
      maxWeightKg: 13.00,
      girthRatio: 0.16,
      preferredDepth: WaterDepth.surface,
      favoriteBaits: ['live_minnows', 'cut_bait'],
      locationIds: [6, 8],
      activeHours: [19, 20, 21, 22, 23, 0],
      primaryColor: Color(0xFF4E342E),
      secondaryColor: Color(0xFF8D6E63),
      bellyColor: Color(0xFFD7CCC8),
      baseMarketPricePerKg: 45,
    ),

    // ==========================================
    // 10. Starlit Ocean Pier & 12. Abyssal Trench
    // ==========================================
    const FishSpecies(
      id: 'chub_mackerel',
      name: 'Chub Mackerel',
      scientificName: 'Scomber japonicus',
      description: 'Speedy schooling ocean cruiser with iridescent emerald zigzag wavy bars along its spine.',
      rarity: FishRarity.common,
      minLengthCm: 22.0,
      maxLengthCm: 38.0,
      minWeightKg: 0.35,
      maxWeightKg: 1.25,
      girthRatio: 0.22,
      preferredDepth: WaterDepth.midWater,
      favoriteBaits: ['metal_spoons', 'cut_bait'],
      locationIds: [9, 10],
      activeHours: [],
      primaryColor: Color(0xFF00897B),
      secondaryColor: Color(0xFF26A69A),
      bellyColor: Color(0xFFE0F2F1),
      baseMarketPricePerKg: 25,
    ),
    const FishSpecies(
      id: 'pacific_red_snapper',
      name: 'Pacific Red Snapper',
      scientificName: 'Lutjanus campechanus',
      description: 'Deep crimson prize of the ocean shelf with powerful downward runs into reefs.',
      rarity: FishRarity.uncommon,
      minLengthCm: 38.0,
      maxLengthCm: 68.0,
      minWeightKg: 2.00,
      maxWeightKg: 7.20,
      girthRatio: 0.32,
      preferredDepth: WaterDepth.deep,
      favoriteBaits: ['cut_bait', 'live_minnows'],
      locationIds: [10, 11],
      activeHours: [18, 19, 20, 21, 22],
      primaryColor: Color(0xFFD32F2F),
      secondaryColor: Color(0xFFFF5252),
      bellyColor: Color(0xFFFFCDD2),
      baseMarketPricePerKg: 52,
    ),
    const FishSpecies(
      id: 'california_halibut',
      name: 'California Halibut',
      scientificName: 'Paralichthys californicus',
      description: 'Wide, flat stealth predator lying camouflaged on the sandy ocean floor.',
      rarity: FishRarity.rare,
      minLengthCm: 45.0,
      maxLengthCm: 90.0,
      minWeightKg: 3.00,
      maxWeightKg: 12.00,
      girthRatio: 0.45,
      preferredDepth: WaterDepth.bottom,
      favoriteBaits: ['cut_bait', 'live_minnows'],
      locationIds: [9, 10],
      activeHours: [20, 21, 22, 23, 0, 1, 2],
      primaryColor: Color(0xFF5D4037),
      secondaryColor: Color(0xFF3E2723),
      bellyColor: Color(0xFFFFFFFF),
      baseMarketPricePerKg: 60,
    ),
    const FishSpecies(
      id: 'opah_moonfish',
      name: 'Opah (Moonfish)',
      scientificName: 'Lampris guttatus',
      description: 'Spectacular disc-shaped, warm-blooded ocean wanderer gleaming with pink-silver sheen.',
      rarity: FishRarity.trophy,
      minLengthCm: 60.0,
      maxLengthCm: 115.0,
      minWeightKg: 8.00,
      maxWeightKg: 24.00,
      girthRatio: 0.50,
      preferredDepth: WaterDepth.deep,
      favoriteBaits: ['cut_bait', 'metal_spoons'],
      locationIds: [10, 11, 12],
      activeHours: [21, 22, 23, 0, 1, 2, 3],
      primaryColor: Color(0xFFFF4081),
      secondaryColor: Color(0xFF7C4DFF),
      bellyColor: Color(0xFFECEFF1),
      baseMarketPricePerKg: 80,
    ),
    const FishSpecies(
      id: 'abyssal_armored_sturgeon',
      name: 'Abyssal Armored Sturgeon',
      scientificName: 'Acipenser titanicus',
      description: 'Living dinosaur of the ocean trench with bony armored scutes and relentless pulling power.',
      rarity: FishRarity.legendary,
      minLengthCm: 95.0,
      maxLengthCm: 195.0,
      minWeightKg: 18.00,
      maxWeightKg: 62.00,
      girthRatio: 0.24,
      preferredDepth: WaterDepth.bottom,
      favoriteBaits: ['cut_bait'],
      locationIds: [12],
      activeHours: [22, 23, 0, 1, 2, 3],
      primaryColor: Color(0xFF263238),
      secondaryColor: Color(0xFF37474F),
      bellyColor: Color(0xFFCFD8DC),
      baseMarketPricePerKg: 110,
    ),
  ];

  static FishSpecies getSpecies(String id) {
    return allSpecies.firstWhere(
      (s) => s.id == id,
      orElse: () => allSpecies.first,
    );
  }

  static List<FishSpecies> getSpeciesForLocation(int locationId) {
    return allSpecies.where((s) => s.locationIds.contains(locationId)).toList();
  }

  static CaughtFish generateCatch({
    required String speciesId,
    required int locationId,
    required String baitUsed,
    required bool playerHasScaleTape,
  }) {
    final species = getSpecies(speciesId);
    final random = Random();

    // Generate bell-curve distributed length and weight
    final rollLength = (random.nextDouble() + random.nextDouble()) / 2.0;
    final length = species.minLengthCm + rollLength * (species.maxLengthCm - species.minLengthCm);

    // Weight roughly proportional to length cubed, with random condition factor
    final lengthRatio = (length - species.minLengthCm) / (species.maxLengthCm - species.minLengthCm);
    final condition = 0.85 + random.nextDouble() * 0.3; // skinny vs plump
    final weight = (species.minWeightKg + (lengthRatio * lengthRatio) * (species.maxWeightKg - species.minWeightKg)) * condition;
    final girth = length * species.girthRatio * condition;

    return CaughtFish(
      id: 'catch_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(9999)}',
      speciesId: speciesId,
      lengthCm: double.parse(length.toStringAsFixed(1)),
      weightKg: double.parse(weight.toStringAsFixed(2)),
      girthCm: double.parse(girth.toStringAsFixed(1)),
      caughtAt: DateTime.now(),
      locationId: locationId,
      baitUsed: baitUsed,
      isExamined: playerHasScaleTape, // If player owns scale & tape, known immediately!
    );
  }
}
