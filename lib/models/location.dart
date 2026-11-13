class FishingLocation {
  final int id;
  final String name;
  final String subtitle;
  final String description;
  final int travelFee; // Starting area is 0 (FREE), others have fee
  final int requiredZenRank;
  final String environmentType; // lake, creek, river, bayou, ocean

  const FishingLocation({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.travelFee,
    required this.requiredZenRank,
    required this.environmentType,
  });

  bool get isFree => travelFee == 0;

  static const List<FishingLocation> all = [
    FishingLocation(
      id: 1,
      name: 'Whispering Willow Lake',
      subtitle: 'Tranquil Reeds & Water Lilies',
      description: 'A sunlit, placid freshwater haven. Perfect for learning line control, watching bobber twitches, and catching panfish and bass.',
      travelFee: 0, // FREE starter area!
      requiredZenRank: 1,
      environmentType: 'lake',
    ),
    FishingLocation(
      id: 2,
      name: "Old Miller's Creek",
      subtitle: 'Shaded Timbers & Stone Bridge',
      description: 'Gentle winding stream running past a historic wooden water wheel. Active schools of chubs, dace, and bullheads.',
      travelFee: 15,
      requiredZenRank: 1,
      environmentType: 'creek',
    ),
    FishingLocation(
      id: 3,
      name: 'Misty Pine River',
      subtitle: 'Alpine Rapids & Pebble Runs',
      description: 'Chilled mountain currents teeming with acrobatic rainbow trout, brook trout, and mighty migrating salmon.',
      travelFee: 25,
      requiredZenRank: 2,
      environmentType: 'river',
    ),
    FishingLocation(
      id: 4,
      name: 'Crystal Mirror Reservoir',
      subtitle: 'Glassy Highlands & Submerged Pines',
      description: 'Deep glacial mountain reservoir where trophy pike and golden perch patrol sunken tree lines.',
      travelFee: 40,
      requiredZenRank: 3,
      environmentType: 'lake',
    ),
    FishingLocation(
      id: 5,
      name: 'Twilight Lotus Pond',
      subtitle: 'Floating Blossoms & Firefly Dusk',
      description: 'An ancient serene water garden glowing with lantern reflections. Home to majestic Japanese Kohaku Koi and golden dragon arowana.',
      travelFee: 60,
      requiredZenRank: 4,
      environmentType: 'lake',
    ),
    FishingLocation(
      id: 6,
      name: 'Sunken Cypress Bayou',
      subtitle: 'Murky Waters & Spanish Moss',
      description: 'Tangled cypress knees and blackwater channels hiding heavy channel catfish and prehistoric armored gar.',
      travelFee: 80,
      requiredZenRank: 5,
      environmentType: 'bayou',
    ),
    FishingLocation(
      id: 7,
      name: 'Emerald Mountain Fjord',
      subtitle: 'Glacial Chasm & Cold Depths',
      description: 'Sheer granite cliffs descending into icy emerald waters where sea-run steelheads and sockeye salmon run.',
      travelFee: 100,
      requiredZenRank: 6,
      environmentType: 'river',
    ),
    FishingLocation(
      id: 8,
      name: 'Sunset Reed Marsh',
      subtitle: 'Golden Hour Delta Flats',
      description: 'Expansive golden wetlands where predatory pickerel and heavy river cats strike during the sunset feeding frenzy.',
      travelFee: 125,
      requiredZenRank: 7,
      environmentType: 'lake',
    ),
    FishingLocation(
      id: 9,
      name: 'Old Timber Harbor',
      subtitle: 'Weathered Piles & Salty Breakers',
      description: 'Historic seaport with bustling dock pilings that attract swift mackerel, flat flounder, and striped bass.',
      travelFee: 150,
      requiredZenRank: 8,
      environmentType: 'ocean',
    ),
    FishingLocation(
      id: 10,
      name: 'Starlit Ocean Pier',
      subtitle: 'Midnight Salt Swells & Lanterns',
      description: 'A peaceful wooden pier stretching out over midnight waves. Snappers and giant halibut cruise the sandy bottom.',
      travelFee: 180,
      requiredZenRank: 9,
      environmentType: 'ocean',
    ),
    FishingLocation(
      id: 11,
      name: 'Whispering Sea Cave',
      subtitle: 'Bioluminescent Grotto',
      description: 'A secluded cavern bathed in glowing azure tides. Lures elusive moonfish and deep saltwater swimmers.',
      travelFee: 220,
      requiredZenRank: 10,
      environmentType: 'ocean',
    ),
    FishingLocation(
      id: 12,
      name: 'The Abyssal Trench',
      subtitle: 'The Edge of the Open Sea',
      description: 'The ultimate deep-water expedition where only the heaviest braided lines can endure titanic armored sturgeons.',
      travelFee: 280,
      requiredZenRank: 12,
      environmentType: 'ocean',
    ),
  ];

  static FishingLocation getLocation(int id) {
    return all.firstWhere((loc) => loc.id == id, orElse: () => all.first);
  }
}
