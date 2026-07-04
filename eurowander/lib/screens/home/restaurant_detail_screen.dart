import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/restaurant.dart';
import '../../models/saved_trip.dart';
import '../../services/api_service.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String contentId;
  final SavedTrip trip;

  const RestaurantDetailScreen({
    super.key,
    required this.contentId,
    required this.trip,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final ApiService _apiService = ApiService();
  RestaurantDetail? _details;
  bool _isLoading = true;

  // Expandable reviews state
  bool _reviewsExpanded = false;
  bool _reviewsLoading = false;
  List<RestaurantReview> _reviews = [];

  // Expandable nearby state
  bool _nearbyExpanded = false;
  bool _nearbyLoading = false;
  List<NearbyRestaurant> _nearbyRestaurants = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _apiService.getRestaurantDetails(
      contentId: widget.contentId,
    );
    if (mounted) {
      setState(() {
        _details = details;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    if (_reviewsLoading || _reviews.isNotEmpty) return;
    setState(() => _reviewsLoading = true);
    final reviews = await _apiService.getRestaurantReviews(contentId: widget.contentId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
      });
    }
  }

  Future<void> _loadNearby() async {
    if (_nearbyLoading || _nearbyRestaurants.isNotEmpty) return;
    setState(() => _nearbyLoading = true);
    final nearby = await _apiService.getRestaurantNearby(contentId: widget.contentId);
    if (mounted) {
      setState(() {
        _nearbyRestaurants = nearby;
        _nearbyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : _details == null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Failed to load restaurant details', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Go Back', style: GoogleFonts.poppins(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final restaurant = _details!;
    return Column(
      children: [
        _buildAppBar(restaurant),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoGallery(restaurant),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(restaurant),
                          const SizedBox(height: 20),
                          _buildInfoCard(restaurant),
                          const SizedBox(height: 20),
                          _buildMap(restaurant),
                          if (restaurant.description.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildDescription(restaurant),
                          ],
                          if (restaurant.cuisines.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildCuisines(restaurant),
                          ],
                          if (restaurant.features.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildFeatures(restaurant),
                          ],
                          const SizedBox(height: 20),
                          _buildReviewsExpander(),
                          const SizedBox(height: 12),
                          _buildNearbyExpander(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(RestaurantDetail restaurant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              restaurant.name,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(RestaurantDetail restaurant) {
    if (restaurant.photos.isEmpty) {
      return Container(
        height: 220,
        color: Colors.grey.shade200,
        child: Center(child: Icon(Icons.restaurant_rounded, size: 56, color: Colors.grey.shade400)),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: restaurant.photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openPhotoViewer(restaurant.photos, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                restaurant.photos[index].url,
                width: 300,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 300,
                  height: 220,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey.shade400),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPhotoViewer(List<RestaurantPhoto> photos, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, _, __) => _PhotoViewerPage(
          photos: photos.map((p) => p.url).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildHeader(RestaurantDetail restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant.name,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade600),
            const SizedBox(width: 4),
            Text('${restaurant.rating}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text('(${restaurant.numReviews} reviews)', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
            if (restaurant.priceLevel.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(restaurant.priceLevel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
              ),
            ],
          ],
        ),
        if (restaurant.ranking.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            restaurant.ranking,
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(RestaurantDetail restaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          if (restaurant.address.isNotEmpty)
            _buildInfoRow(Icons.location_on_rounded, restaurant.address),
          if (restaurant.hoursStatus.isNotEmpty)
            _buildInfoRow(Icons.access_time_rounded, restaurant.hoursStatus),
          if (restaurant.todaySchedule.isNotEmpty)
            _buildInfoRow(Icons.schedule_rounded, restaurant.todaySchedule.join(', ')),
          if (restaurant.serving.isNotEmpty)
            _buildInfoRow(Icons.dinner_dining_rounded, 'Serves: ${restaurant.serving.join(', ')}'),
          if (restaurant.phone.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:${restaurant.phone}')),
              child: _buildInfoRow(Icons.phone_rounded, restaurant.phone),
            ),
          if (restaurant.website.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(restaurant.website), mode: LaunchMode.externalApplication),
              child: _buildInfoRow(Icons.language_rounded, 'Visit Website', isLink: true),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isLink ? AppTheme.primaryColor : AppTheme.textPrimary,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(RestaurantDetail restaurant) {
    if (restaurant.latitude == 0 && restaurant.longitude == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(restaurant.latitude, restaurant.longitude),
                initialZoom: 15,
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(restaurant.latitude, restaurant.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(RestaurantDetail restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(
          restaurant.description,
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildCuisines(RestaurantDetail restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuisines', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: restaurant.cuisines.map((cuisine) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(cuisine, style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade800)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatures(RestaurantDetail restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Features', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: restaurant.features.map((feature) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(feature, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryColor)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsExpander() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(Icons.rate_review_rounded, color: AppTheme.primaryColor, size: 22),
          title: Text('Reviews', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          subtitle: Text('${_details?.numReviews ?? 0} reviews', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          initiallyExpanded: _reviewsExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _reviewsExpanded = expanded);
            if (expanded) _loadReviews();
          },
          children: [
            if (_reviewsLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
              )
            else if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No reviews available', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
              )
            else
              ..._reviews.map((review) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          Icons.star_rounded, size: 14,
                          color: i < review.rating ? Colors.amber.shade600 : Colors.grey.shade300,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: Text(review.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(review.text, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.4), maxLines: 4, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(review.author, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                        const Spacer(),
                        Text(review.publishedDate, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyExpander() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(Icons.near_me_rounded, color: AppTheme.primaryColor, size: 22),
          title: Text('Nearby Restaurants', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          subtitle: Text('Discover places nearby', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          initiallyExpanded: _nearbyExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _nearbyExpanded = expanded);
            if (expanded) _loadNearby();
          },
          children: [
            if (_nearbyLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
              )
            else if (_nearbyRestaurants.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No nearby restaurants found', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
              )
            else
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _nearbyRestaurants.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final nearby = _nearbyRestaurants[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => RestaurantDetailScreen(
                            contentId: nearby.contentId,
                            trip: widget.trip,
                          ),
                        ));
                      },
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nearby.name, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Text(nearby.cuisine, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.star_rounded, size: 12, color: Colors.amber.shade600),
                              Text(' ${nearby.rating}', style: GoogleFonts.poppins(fontSize: 11)),
                              const Spacer(),
                              Text(nearby.distance, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary)),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewerPage extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoViewerPage({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.photos[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
              ),
            ),
          );
        },
      ),
    );
  }
}
