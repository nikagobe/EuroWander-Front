import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Inspirational hero banner with auto-rotating destination imagery.
/// Replaces the plain greeting header with an immersive, emotional intro.
class HeroBanner extends StatefulWidget {
  const HeroBanner({
    super.key,
    required this.greeting,
    required this.userName,
    required this.onPlanTrip,
    required this.onProfileTap,
    required this.profileInitials,
    this.destinationPhotos = const [],
  });

  final String greeting;
  final String userName;
  final VoidCallback onPlanTrip;
  final VoidCallback onProfileTap;
  final String profileInitials;
  final List<String> destinationPhotos;

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _shimmerController;
  late final AnimationController _pulseController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  // Curated fallback images — iconic European destinations
  static const _fallbackImages = [
    'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80', // Paris
    'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800&q=80', // Venice
    'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80', // London
    'https://images.unsplash.com/photo-1549144511-f099e773c147?w=800&q=80', // Barcelona
  ];

  List<String> get _images =>
      widget.destinationPhotos.isNotEmpty ? widget.destinationPhotos : _fallbackImages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _images.length <= 1) return;
      _currentPage = (_currentPage + 1) % _images.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          // Background image carousel
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => _buildImageSlide(_images[index]),
          ),

          // Gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Content overlay
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Greeting
                Text(
                  widget.greeting,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userName.isNotEmpty
                      ? 'Hey, ${widget.userName}!'
                      : 'Welcome back!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getInspirationText(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.75),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Plan Trip CTA with shimmer
                    Expanded(
                      child: _buildShimmerCta(),
                    ),
                    const SizedBox(width: 12),
                    // Page indicators
                    if (_images.length > 1) _buildPageDots(),
                  ],
                ),
              ],
            ),
          ),

          // Profile avatar (top right)
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.profileInitials.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlide(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 220,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.brandPrimary, AppColors.brandSecondary],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.landscape_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCta() {
    return GestureDetector(
      onTap: widget.onPlanTrip,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shimmerController, _pulseController]),
        builder: (context, child) {
          final pulseValue = Curves.easeInOut.transform(_pulseController.value);
          final scale = 1.0 + (0.025 * pulseValue);
          final glowOpacity = 0.1 + (0.2 * pulseValue);
          final glowBlur = 8.0 + (8.0 * pulseValue);

          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2 + (0.08 * pulseValue)),
                    Colors.white.withOpacity(0.12 + (0.05 * pulseValue)),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35 + (0.15 * pulseValue)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(glowOpacity),
                    blurRadius: glowBlur,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: AppColors.brandPrimary.withOpacity(glowOpacity * 0.5),
                    blurRadius: glowBlur * 1.5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.5),
                          Colors.white,
                        ],
                        stops: [
                          (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                          _shimmerController.value.clamp(0.0, 1.0),
                          (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Plan New Trip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
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

  Widget _buildPageDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_images.length, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(left: 4),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
          ),
        );
      }),
    );
  }

  String _getInspirationText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '"Every morning is a new journey"';
    if (hour < 17) return '"Collect moments, not things"';
    return '"Adventure awaits around every corner"';
  }
}
