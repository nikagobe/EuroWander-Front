import 'dart:ui';

/// Maps European city names to curated Unsplash photo URLs for visual enrichment.
/// Used in template itineraries, spotlight features, and city cards.
abstract final class CityPhotos {
  static const Map<String, String> _photos = {
    // France
    'paris': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600&q=80',
    'nice': 'https://images.unsplash.com/photo-1491166617655-0723a0999cfc?w=600&q=80',
    'lyon': 'https://images.unsplash.com/photo-1524396309943-e03f5249f002?w=600&q=80',
    'marseille': 'https://images.unsplash.com/photo-1589098474421-58176929cf00?w=600&q=80',
    'bordeaux': 'https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?w=600&q=80',
    'strasbourg': 'https://images.unsplash.com/photo-1575408264798-4cb8982f0deb?w=600&q=80',

    // Italy
    'rome': 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=600&q=80',
    'venice': 'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=600&q=80',
    'florence': 'https://images.unsplash.com/photo-1543429257-3eb0b65d9c58?w=600&q=80',
    'milan': 'https://images.unsplash.com/photo-1520440229-6469a149ac59?w=600&q=80',
    'naples': 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=600&q=80',
    'amalfi': 'https://images.unsplash.com/photo-1534113414509-0eec2bfb493f?w=600&q=80',

    // Spain
    'barcelona': 'https://images.unsplash.com/photo-1549144511-f099e773c147?w=600&q=80',
    'madrid': 'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=600&q=80',
    'seville': 'https://images.unsplash.com/photo-1515443961218-a51367888e4b?w=600&q=80',
    'valencia': 'https://images.unsplash.com/photo-1599922407444-0b02dc2a6fdc?w=600&q=80',
    'malaga': 'https://images.unsplash.com/photo-1564221710304-0b37c8b9d729?w=600&q=80',

    // UK
    'london': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=600&q=80',
    'edinburgh': 'https://images.unsplash.com/photo-1506377585622-bedcbb5f7f0e?w=600&q=80',
    'manchester': 'https://images.unsplash.com/photo-1515586838455-8f8f940d6853?w=600&q=80',

    // Germany
    'berlin': 'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=600&q=80',
    'munich': 'https://images.unsplash.com/photo-1595867818082-083862f3d630?w=600&q=80',
    'hamburg': 'https://images.unsplash.com/photo-1560611588-163f295eb145?w=600&q=80',
    'frankfurt': 'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=600&q=80',
    'cologne': 'https://images.unsplash.com/photo-1515404929826-76fff9fef6fe?w=600&q=80',

    // Netherlands
    'amsterdam': 'https://images.unsplash.com/photo-1534351590666-13e3e96b5017?w=600&q=80',
    'rotterdam': 'https://images.unsplash.com/photo-1543872084-c7bd3822856f?w=600&q=80',

    // Belgium
    'brussels': 'https://images.unsplash.com/photo-1559113202-c916b8e44373?w=600&q=80',
    'bruges': 'https://images.unsplash.com/photo-1491557345352-5929e343eb89?w=600&q=80',

    // Portugal
    'lisbon': 'https://images.unsplash.com/photo-1536663815808-535e2280d2c2?w=600&q=80',
    'porto': 'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=600&q=80',

    // Austria
    'vienna': 'https://images.unsplash.com/photo-1516550893923-42d28e5677af?w=600&q=80',
    'salzburg': 'https://images.unsplash.com/photo-1609838030039-6b7e0ea9d5ad?w=600&q=80',
    'innsbruck': 'https://images.unsplash.com/photo-1573599852326-2d4da0bbe613?w=600&q=80',

    // Switzerland
    'zurich': 'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=600&q=80',
    'geneva': 'https://images.unsplash.com/photo-1583849215706-09d38c78d0cd?w=600&q=80',
    'interlaken': 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?w=600&q=80',

    // Greece
    'athens': 'https://images.unsplash.com/photo-1555993539-1732b0258235?w=600&q=80',
    'santorini': 'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=600&q=80',
    'mykonos': 'https://images.unsplash.com/photo-1601581875309-fafbf2d3ed3a?w=600&q=80',

    // Croatia
    'dubrovnik': 'https://images.unsplash.com/photo-1555990793-da11153b2473?w=600&q=80',
    'split': 'https://images.unsplash.com/photo-1556636530-6b7482d80e3d?w=600&q=80',
    'zagreb': 'https://images.unsplash.com/photo-1558271736-cd043ef2e855?w=600&q=80',

    // Czech Republic
    'prague': 'https://images.unsplash.com/photo-1519677100203-a0e668c92439?w=600&q=80',

    // Hungary
    'budapest': 'https://images.unsplash.com/photo-1541343672885-9be56236302a?w=600&q=80',

    // Poland
    'krakow': 'https://images.unsplash.com/photo-1558271736-a91c867d3ea6?w=600&q=80',
    'warsaw': 'https://images.unsplash.com/photo-1519197924294-4ba991a11128?w=600&q=80',

    // Scandinavia
    'copenhagen': 'https://images.unsplash.com/photo-1513622470522-26c3c8a854bc?w=600&q=80',
    'stockholm': 'https://images.unsplash.com/photo-1509356843151-3e7bd6f50ac0?w=600&q=80',
    'oslo': 'https://images.unsplash.com/photo-1527004013197-933c4bb611b3?w=600&q=80',
    'helsinki': 'https://images.unsplash.com/photo-1538332576228-eb5b4c4de6f5?w=600&q=80',
    'reykjavik': 'https://images.unsplash.com/photo-1504829857797-ddff29c27927?w=600&q=80',

    // Turkey
    'istanbul': 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=600&q=80',

    // Ireland
    'dublin': 'https://images.unsplash.com/photo-1549918864-48ac978761a4?w=600&q=80',

    // Georgia
    'tbilisi': 'https://images.unsplash.com/photo-1565008576549-57569a49371d?w=600&q=80',
    'batumi': 'https://images.unsplash.com/photo-1588520903122-b7e9caff253f?w=600&q=80',
  };

  /// Returns a curated photo URL for the given city, or null if not in our database.
  static String? getPhotoUrl(String city) {
    if (city.isEmpty) return null;
    return _photos[city.toLowerCase().trim()];
  }

  /// Returns a list of gradient colors as fallback for cities without photos.
  static List<Color> getFallbackGradient(String city) {
    final hash = city.toLowerCase().hashCode;
    final gradients = [
      [const Color(0xFF6C3CE0), const Color(0xFF8B5CF6)],
      [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      [const Color(0xFFEC4899), const Color(0xFFF472B6)],
      [const Color(0xFFE65100), const Color(0xFFFF9800)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
      [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
    ];
    return gradients[hash.abs() % gradients.length];
  }
}
