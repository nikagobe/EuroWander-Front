import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Full-width immersive destination spotlight card.
/// Features a curated destination with parallax-like layered design.
class DestinationSpotlight extends StatelessWidget {
  const DestinationSpotlight({
    super.key,
    required this.cityName,
    required this.country,
    required this.tagline,
    required this.imageUrl,
    this.onTap,
    this.tags = const [],
  });

  final String cityName;
  final String country;
  final String tagline;
  final String imageUrl;
  final VoidCallback? onTap;
  final List<String> tags;

  /// Curated spotlight destinations — rotates based on day of year
  static DestinationSpotlight seasonal({VoidCallback? onTap}) {
    const destinations = [
      _SpotlightData(
        cityName: 'Santorini',
        country: 'Greece',
        tagline: 'Where sunsets paint the sky',
        imageUrl: 'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=800&q=80',
        tags: ['Romantic', 'Summer', 'Islands'],
      ),
      _SpotlightData(
        cityName: 'Prague',
        country: 'Czech Republic',
        tagline: 'The city of a hundred spires',
        imageUrl: 'https://images.unsplash.com/photo-1519677100203-a0e668c92439?w=800&q=80',
        tags: ['Cultural', 'Architecture', 'History'],
      ),
      _SpotlightData(
        cityName: 'Amalfi Coast',
        country: 'Italy',
        tagline: 'Where mountains meet the Mediterranean',
        imageUrl: 'https://images.unsplash.com/photo-1534113414509-0eec2bfb493f?w=800&q=80',
        tags: ['Scenic', 'Coastal', 'Luxury'],
      ),
      _SpotlightData(
        cityName: 'Amsterdam',
        country: 'Netherlands',
        tagline: 'Canals, culture & charm',
        imageUrl: 'https://images.unsplash.com/photo-1534351590666-13e3e96b5017?w=800&q=80',
        tags: ['Culture', 'Nightlife', 'Art'],
      ),
      _SpotlightData(
        cityName: 'Dubrovnik',
        country: 'Croatia',
        tagline: 'Pearl of the Adriatic',
        imageUrl: 'https://images.unsplash.com/photo-1555990793-da11153b2473?w=800&q=80',
        tags: ['Historic', 'Coastal', 'Adventure'],
      ),
    ];

    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final data = destinations[dayOfYear % destinations.length];
    return DestinationSpotlight(
      cityName: data.cityName,
      country: data.country,
      tagline: data.tagline,
      imageUrl: data.imageUrl,
      tags: data.tags,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandPrimary.withOpacity(0.3),
                          AppColors.brandSecondary.withOpacity(0.3),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                    ),
                  ),
                ),
              ),

              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
              ),

              // "Spotlight" label (top-left)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brandAmber.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Spotlight',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content (bottom-left)
              Positioned(
                left: 16,
                bottom: 16,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      country,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tagline,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow indicator (right)
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightData {
  final String cityName;
  final String country;
  final String tagline;
  final String imageUrl;
  final List<String> tags;

  const _SpotlightData({
    required this.cityName,
    required this.country,
    required this.tagline,
    required this.imageUrl,
    this.tags = const [],
  });
}
