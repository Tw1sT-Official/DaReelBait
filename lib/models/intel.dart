class IntelTip {
  final String id;
  final String title;
  final String content;
  final int locationId;
  final String? speciesId;
  final int cost;
  final bool isDetailed;

  const IntelTip({
    required this.id,
    required this.title,
    required this.content,
    required this.locationId,
    this.speciesId,
    required this.cost,
    this.isDetailed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'locationId': locationId,
        'speciesId': speciesId,
        'cost': cost,
        'isDetailed': isDetailed,
      };

  factory IntelTip.fromJson(Map<String, dynamic> json) => IntelTip(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        locationId: json['locationId'] as int,
        speciesId: json['speciesId'] as String?,
        cost: json['cost'] as int,
        isDetailed: json['isDetailed'] as bool? ?? false,
      );
}

class IntelDatabase {
  static const List<IntelTip> allTips = [
    // Location 1: Whispering Willow Lake
    IntelTip(
      id: 'tip_lake_feeding',
      title: "Old Pete's Water Rhythm",
      content: 'The shallows around Whispering Willow Lake come alive between 5:00 PM and 7:30 PM. Surface fish gorge on evening mayflies.',
      locationId: 1,
      cost: 15,
      isDetailed: false,
    ),
    IntelTip(
      id: 'tip_lake_bluegill',
      title: 'Panfish Habitats',
      content: 'Bluegills and Sunfish cluster tightly around lily pad edges. Simple Nightcrawlers or Bread Dough will entice them in seconds.',
      locationId: 1,
      cost: 15,
      isDetailed: false,
    ),
    IntelTip(
      id: 'dossier_solar_bass',
      title: 'Dossier: The Grand Solar Bass',
      content: 'Habitat: Whispering Willow Lake weed edges.\nPeak Hours: 17:00 – 19:30 (Sunset only).\nDepth: Surface.\nPreferred Bait: Live Minnows or Floating Poppers.\nBehavior: Explosive strikes followed by aerial leaps. Counter-steer immediately when it surges!',
      locationId: 1,
      speciesId: 'grand_solar_bass',
      cost: 85,
      isDetailed: true,
    ),

    // Location 2: Old Miller's Creek
    IntelTip(
      id: 'tip_creek_timber',
      title: 'Miller Mill Shadows',
      content: 'Yellow Bullheads avoid the bright sunlight and nest right beneath the sunken mill timbers. Switch to bottom bait past 6:00 PM.',
      locationId: 2,
      cost: 20,
      isDetailed: false,
    ),

    // Location 3: Misty Pine River
    IntelTip(
      id: 'tip_river_currents',
      title: 'Current Seams & Eddies',
      content: 'Trout don’t fight the main current—they sit in the quiet foam seams waiting for drifting food. Flasher Spoons work wonders here.',
      locationId: 3,
      cost: 25,
      isDetailed: false,
    ),
    IntelTip(
      id: 'dossier_king_chinook',
      title: 'Dossier: River King Chinook',
      content: 'Habitat: Misty Pine River gravel bends.\nPeak Hours: Early morning (05:00–07:00) & Dusk (18:00–20:00).\nDepth: Deep river trenches.\nPreferred Bait: Silver Flasher Spoons or Live Minnows.\nWarning: Titanic pulling power. Keep your drag flexible and never hold the reel during a downstream run!',
      locationId: 3,
      speciesId: 'river_king_chinook',
      cost: 120,
      isDetailed: true,
    ),

    // Location 5: Twilight Lotus Pond
    IntelTip(
      id: 'tip_lotus_blossoms',
      title: 'Lotus Garden Feeding',
      content: 'Crucian Carp and Kohaku Koi have delicate mouths. Sweet corn kernels dropped near floating blossoms produce the gentlest, sweetest bites.',
      locationId: 5,
      cost: 30,
      isDetailed: false,
    ),
    IntelTip(
      id: 'dossier_dragon_arowana',
      title: 'Dossier: Golden Dragon Arowana',
      content: 'Habitat: Twilight Lotus Pond surface shallows.\nPeak Hours: 18:00 – 22:00 (Evening to late night).\nDepth: Surface.\nPreferred Bait: Live Minnows or Surface Poppers.\nBehavior: Patrols like a torpedo right under the surface film. Sets the hook firmly with an upward flick!',
      locationId: 5,
      speciesId: 'golden_dragon_arowana',
      cost: 150,
      isDetailed: true,
    ),

    // Location 10: Starlit Ocean Pier
    IntelTip(
      id: 'tip_pier_lanterns',
      title: 'Pier Lantern Halos',
      content: 'Mackerel school right beneath the dock lanterns at midnight, feeding on small squid and baitfish attracted to the beam.',
      locationId: 10,
      cost: 35,
      isDetailed: false,
    ),
    IntelTip(
      id: 'dossier_abyssal_sturgeon',
      title: 'Dossier: Abyssal Armored Sturgeon',
      content: 'Habitat: The Abyssal Trench floor.\nPeak Hours: 22:00 – 03:00 (Midnight ocean).\nDepth: Abyssal Bottom.\nPreferred Bait: Fresh Cut Scent Bait.\nWarning: Can exceed 50 kg. Only Heavy Braided Line and high-test rods will withstand its bottom anchor runs!',
      locationId: 12,
      speciesId: 'abyssal_armored_sturgeon',
      cost: 200,
      isDetailed: true,
    ),
  ];

  static List<IntelTip> getTipsForLocation(int locationId) {
    return allTips.where((t) => t.locationId == locationId).toList();
  }
}
