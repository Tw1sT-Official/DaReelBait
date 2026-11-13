enum EquipmentType {
  tool,
  cooler,
  rod,
  line,
  bait,
}

class EquipmentItem {
  final String id;
  final String name;
  final EquipmentType type;
  final String icon;
  final String description;
  final int cost;
  final double capacityKg; // For coolers
  final double strengthRating; // For rods and lines
  final int locationUnlockedAt; // which shop sells it

  const EquipmentItem({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.description,
    required this.cost,
    this.capacityKg = 0.0,
    this.strengthRating = 1.0,
    this.locationUnlockedAt = 1,
  });
}

class EquipmentDatabase {
  // Tools
  static const toolScaleTape = EquipmentItem(
    id: 'tool_scale_tape',
    name: 'Brass Scale & Tape',
    type: EquipmentType.tool,
    icon: '⚖️',
    description: 'Allows you to personally weigh (kg) and measure (cm) your catch right at the water before deciding to keep or release.',
    cost: 50,
    locationUnlockedAt: 1,
  );

  static const toolCamera = EquipmentItem(
    id: 'tool_camera',
    name: "Angler's Instant Camera",
    type: EquipmentType.tool,
    icon: '📷',
    description: 'Captures a clean vintage photograph of your catch resting on the dock, ready to save or share.',
    cost: 75,
    locationUnlockedAt: 1,
  );

  static const toolLogbook = EquipmentItem(
    id: 'tool_logbook',
    name: 'Leather Fish Logbook',
    type: EquipmentType.tool,
    icon: '📖',
    description: 'A handsome album to paste your catch certificates and track personal records for all 60 species.',
    cost: 40,
    locationUnlockedAt: 1,
  );

  static const toolDiary = EquipmentItem(
    id: 'tool_diary',
    name: "Angler's Field Notebook",
    type: EquipmentType.tool,
    icon: '📓',
    description: 'Permanently records all purchased tips, rumors, and feeding schedules so you never have to memorize them.',
    cost: 60,
    locationUnlockedAt: 1,
  );

  static const toolWatch = EquipmentItem(
    id: 'tool_watch',
    name: 'Solunar Pocket Watch',
    type: EquipmentType.tool,
    icon: '⏱️',
    description: 'Displays the precise local time and a Solunar Barometer forecasting fish feeding activity (Peak vs. Sluggish).',
    cost: 85,
    locationUnlockedAt: 2,
  );

  // Coolers
  static const coolerWovenCreel = EquipmentItem(
    id: 'cooler_woven',
    name: 'Woven Willow Creel',
    type: EquipmentType.cooler,
    icon: '🧺',
    description: 'A modest shoulder creel lined with fresh moss. Holds up to 10.0 kg of fresh catches.',
    cost: 0, // Starter free cooler!
    capacityKg: 10.0,
    locationUnlockedAt: 1,
  );

  static const coolerPlasticPail = EquipmentItem(
    id: 'cooler_pail',
    name: '5-Gallon Heavy Pail',
    type: EquipmentType.cooler,
    icon: '🪣',
    description: 'A sturdy utility bucket with a sealable lid. Holds up to 25.0 kg of fish.',
    cost: 90,
    capacityKg: 25.0,
    locationUnlockedAt: 2,
  );

  static const coolerCampIcebox = EquipmentItem(
    id: 'cooler_camp',
    name: 'Insulated Camp Icebox',
    type: EquipmentType.cooler,
    icon: '🧊',
    description: 'Thick dual-wall insulation with ice pack lining. Holds up to 65.0 kg of fish.',
    cost: 220,
    capacityKg: 65.0,
    locationUnlockedAt: 5,
  );

  static const coolerMarineChest = EquipmentItem(
    id: 'cooler_marine',
    name: 'Offshore Marine Chest',
    type: EquipmentType.cooler,
    icon: '📦',
    description: 'Commercial-grade saltwater chest. Holds up to 160.0 kg—ample room for oceanic monsters.',
    cost: 500,
    capacityKg: 160.0,
    locationUnlockedAt: 9,
  );

  // Rods
  static const rodBamboo = EquipmentItem(
    id: 'rod_bamboo',
    name: 'Handcrafted Bamboo Pole',
    type: EquipmentType.rod,
    icon: '🎋',
    description: 'A traditional, flexible cane pole. Simple and serene for lake and creek fishing.',
    cost: 0, // Starter rod
    strengthRating: 1.0,
    locationUnlockedAt: 1,
  );

  static const rodWillow = EquipmentItem(
    id: 'rod_willow',
    name: 'Flexible Willow Rod',
    type: EquipmentType.rod,
    icon: '🎣',
    description: 'Deep parabolic bend that absorbs aggressive headshakes, giving +25% wider tension sweet spot.',
    cost: 80,
    strengthRating: 1.3,
    locationUnlockedAt: 2,
  );

  static const rodCarbon = EquipmentItem(
    id: 'rod_carbon',
    name: 'Carbon Lake Master',
    type: EquipmentType.rod,
    icon: '🦯',
    description: 'Lightweight graphite rod with swift hook-setting snap and +30% casting distance.',
    cost: 240,
    strengthRating: 1.8,
    locationUnlockedAt: 4,
  );

  static const rodTitan = EquipmentItem(
    id: 'rod_titan',
    name: 'Titan Saltwater Heavy Rod',
    type: EquipmentType.rod,
    icon: '⚡',
    description: 'High-modulus carbon core designed to haul 40kg+ behemoths without buckling.',
    cost: 650,
    strengthRating: 3.0,
    locationUnlockedAt: 9,
  );

  // Lines
  static const lineMono = EquipmentItem(
    id: 'line_mono',
    name: 'Standard Monofilament Line',
    type: EquipmentType.line,
    icon: '🧵',
    description: 'Reliable nylon line with natural stretch. Good all-around line for common lake species.',
    cost: 0, // Starter line
    strengthRating: 1.0,
    locationUnlockedAt: 1,
  );

  static const lineFluoro = EquipmentItem(
    id: 'line_fluoro',
    name: 'Invisible Fluorocarbon Line',
    type: EquipmentType.line,
    icon: '✨',
    description: 'Virtually invisible refractive index in water. Shy trout and wary bass bite 30% faster.',
    cost: 95,
    strengthRating: 1.3,
    locationUnlockedAt: 3,
  );

  static const lineBraid = EquipmentItem(
    id: 'line_braid',
    name: 'Heavy Braided Line',
    type: EquipmentType.line,
    icon: '🧶',
    description: 'Zero stretch with supreme tensile strength. Extremely resistant to snapping on giant runs.',
    cost: 280,
    strengthRating: 2.5,
    locationUnlockedAt: 7,
  );

  // Baits
  static const baitEarthworms = EquipmentItem(
    id: 'earthworms',
    name: 'Nightcrawlers',
    type: EquipmentType.bait,
    icon: '🪱',
    description: 'Plump soil worms. Irresistible to Bluegill, Yellow Perch, Sunfish, and Bullheads.',
    cost: 5,
    locationUnlockedAt: 1,
  );

  static const baitBread = EquipmentItem(
    id: 'bread_dough',
    name: 'Sweet Bread Dough',
    type: EquipmentType.bait,
    icon: '🍞',
    description: 'Soft dough balls made of wheat flour and honey. Loved by Creek Chubs and Carp.',
    cost: 5,
    locationUnlockedAt: 1,
  );

  static const baitCorn = EquipmentItem(
    id: 'sweet_corn',
    name: 'Golden Sweet Corn',
    type: EquipmentType.bait,
    icon: '🌽',
    description: 'Sweet, bright yellow kernels. The classic food for Crucian Carp, Tench, and River Dace.',
    cost: 8,
    locationUnlockedAt: 2,
  );

  static const baitMinnows = EquipmentItem(
    id: 'live_minnows',
    name: 'Live River Minnows',
    type: EquipmentType.bait,
    icon: '🐟',
    description: 'Active small baitfish. Triggers predatory strikes from Largemouth Bass, Crappie, and Pike.',
    cost: 12,
    locationUnlockedAt: 1,
  );

  static const baitPoppers = EquipmentItem(
    id: 'surface_poppers',
    name: 'Topwater Floating Popper',
    type: EquipmentType.bait,
    icon: '🪰',
    description: 'Wooden surface lure that mimics struggling insects. Deadly for Rainbow Trout and Bass.',
    cost: 20,
    locationUnlockedAt: 3,
  );

  static const baitSpoons = EquipmentItem(
    id: 'metal_spoons',
    name: 'Silver Flasher Spoon',
    type: EquipmentType.bait,
    icon: '🥄',
    description: 'Fluttering chrome spoon reflecting bright light. The premier lure for Salmon and Mackerel.',
    cost: 25,
    locationUnlockedAt: 3,
  );

  static const baitCutBait = EquipmentItem(
    id: 'cut_bait',
    name: 'Fresh Cut Scent Bait',
    type: EquipmentType.bait,
    icon: '🥩',
    description: 'Strong-scented oily fish cutlets. Essential for deep-dwelling Catfish, Halibut, and Sturgeons.',
    cost: 18,
    locationUnlockedAt: 6,
  );

  static const List<EquipmentItem> allTools = [
    toolScaleTape,
    toolCamera,
    toolLogbook,
    toolDiary,
    toolWatch,
  ];

  static const List<EquipmentItem> allCoolers = [
    coolerWovenCreel,
    coolerPlasticPail,
    coolerCampIcebox,
    coolerMarineChest,
  ];

  static const List<EquipmentItem> allRods = [
    rodBamboo,
    rodWillow,
    rodCarbon,
    rodTitan,
  ];

  static const List<EquipmentItem> allLines = [
    lineMono,
    lineFluoro,
    lineBraid,
  ];

  static const List<EquipmentItem> allBaits = [
    baitEarthworms,
    baitBread,
    baitCorn,
    baitMinnows,
    baitPoppers,
    baitSpoons,
    baitCutBait,
  ];

  static EquipmentItem getItem(String id) {
    final all = [
      ...allTools,
      ...allCoolers,
      ...allRods,
      ...allLines,
      ...allBaits,
    ];
    return all.firstWhere((i) => i.id == id, orElse: () => toolScaleTape);
  }
}
