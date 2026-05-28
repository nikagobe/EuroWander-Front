class City {
  final String wikidataId;
  final String name;
  final String description;
  final String country;
  final String freebaseId;
  final double? lat;
  final double? lng;

  City({
    required this.wikidataId,
    required this.name,
    required this.description,
    required this.country,
    required this.freebaseId,
    this.lat,
    this.lng,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      wikidataId: json['wikidata_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      country: json['country'] as String,
      freebaseId: json['freebase_id'] as String,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  /// Returns lat/lng from API response, or falls back to hardcoded lookup.
  (double lat, double lng)? get coordinates {
    if (lat != null && lng != null) return (lat!, lng!);
    return _cityCoordinates[freebaseId] ?? _cityCoordinatesByName[name.toLowerCase()];
  }
}

const Map<String, (double, double)> _cityCoordinates = {
  '/m/05qtj': (48.8566, 2.3522),   // Paris
  '/m/01f62': (41.3874, 2.1686),   // Barcelona
  '/m/04jpl': (51.5074, -0.1278),  // London
  '/m/02j9z': (52.5200, 13.4050),  // Berlin
  '/m/06c62': (41.9028, 12.4964),  // Rome
  '/m/0156q': (40.4168, -3.7038),  // Madrid
  '/m/0fhzf': (38.7223, -9.1393),  // Lisbon
  '/m/0k3p': (47.4979, 19.0402),   // Budapest
  '/m/05ywg': (50.0755, 14.4378),  // Prague
  '/m/07dfk': (48.2082, 16.3738),  // Vienna
  '/m/0947l': (59.3293, 18.0686),  // Stockholm
  '/m/01lfy': (55.6761, 12.5683),  // Copenhagen
  '/m/0b90_r': (52.3676, 4.9041),  // Amsterdam
  '/m/07bcn': (46.2044, 6.1432),   // Geneva
  '/m/08966': (47.3769, 8.5417),   // Zurich
  '/m/056_y': (45.4642, 9.1900),   // Milan
  '/m/02cft': (43.7102, 7.2620),   // Nice
  '/m/0dlwj': (43.2965, 5.3698),   // Marseille
  '/m/018dh4': (45.7640, 4.8357),  // Lyon
  '/m/06mkj': (53.3498, -6.2603),  // Dublin
  '/m/01nh3y': (37.9838, 23.7275), // Athens
  '/m/0fhzy': (50.8503, 4.3517),   // Brussels
  '/m/06wxw': (59.9139, 10.7522),  // Oslo
  '/m/02hrh0_': (60.1699, 24.9384),// Helsinki
  '/m/081m_': (44.4268, 26.1025),  // Bucharest
  '/m/0fn7r': (42.6977, 23.3219),  // Sofia
  '/m/09949m': (50.0647, 19.9450), // Krakow
  '/m/0845v': (52.2297, 21.0122),  // Warsaw
};

const Map<String, (double, double)> _cityCoordinatesByName = {
  'paris': (48.8566, 2.3522),
  'barcelona': (41.3874, 2.1686),
  'london': (51.5074, -0.1278),
  'berlin': (52.5200, 13.4050),
  'rome': (41.9028, 12.4964),
  'madrid': (40.4168, -3.7038),
  'lisbon': (38.7223, -9.1393),
  'budapest': (47.4979, 19.0402),
  'prague': (50.0755, 14.4378),
  'vienna': (48.2082, 16.3738),
  'stockholm': (59.3293, 18.0686),
  'copenhagen': (55.6761, 12.5683),
  'amsterdam': (52.3676, 4.9041),
  'geneva': (46.2044, 6.1432),
  'zurich': (47.3769, 8.5417),
  'milan': (45.4642, 9.1900),
  'nice': (43.7102, 7.2620),
  'marseille': (43.2965, 5.3698),
  'lyon': (45.7640, 4.8357),
  'dublin': (53.3498, -6.2603),
  'athens': (37.9838, 23.7275),
  'brussels': (50.8503, 4.3517),
  'oslo': (59.9139, 10.7522),
  'helsinki': (60.1699, 24.9384),
  'bucharest': (44.4268, 26.1025),
  'sofia': (42.6977, 23.3219),
  'krakow': (50.0647, 19.9450),
  'warsaw': (52.2297, 21.0122),
  'tbilisi': (41.7151, 44.8271),
  'kutaisi': (42.2679, 42.6946),
  'batumi': (41.6168, 41.6367),
  'istanbul': (41.0082, 28.9784),
  'ankara': (39.9334, 32.8597),
  'munich': (48.1351, 11.5820),
  'hamburg': (53.5511, 9.9937),
  'frankfurt': (50.1109, 8.6821),
  'porto': (41.1579, -8.6291),
  'naples': (40.8518, 14.2681),
  'florence': (43.7696, 11.2558),
  'venice': (45.4408, 12.3155),
};
