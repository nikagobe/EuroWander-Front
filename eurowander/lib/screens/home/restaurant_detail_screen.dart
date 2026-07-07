import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/restaurant.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
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

  // Photo gallery state
  final ScrollController _photoScrollController = ScrollController();

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

  @override
  void dispose() {
    _photoScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    try {
      final details = await _apiService.getRestaurantDetails(
        contentId: widget.contentId,
      );
      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _details = null;
          _isLoading = false;
        });
      }
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
      bottomNavigationBar: (!_isLoading && _details != null)
          ? _buildAddToTripBar()
          : null,
    );
  }

  Widget _buildAddToTripBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ElevatedButton.icon(
            onPressed: _showAddToTripSheet,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: Text(
              'Add to Trip',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              elevation: 4,
              shadowColor: AppTheme.primaryColor.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToTripSheet() {
    final restaurant = _details!;
    DateTime? tripStart;
    DateTime? tripEnd;
    if (widget.trip.outboundFlight != null) {
      try {
        tripStart = DateTime.parse(widget.trip.outboundFlight!.departureTime.replaceAll(' ', 'T'));
      } catch (_) {}
    }
    if (widget.trip.returnFlight != null) {
      try {
        tripEnd = DateTime.parse(widget.trip.returnFlight!.arrivalTime.replaceAll(' ', 'T'));
      } catch (_) {}
    }
    tripStart ??= DateTime.now();
    tripEnd ??= DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RestaurantAddToTripSheet(
        tripStart: tripStart!,
        tripEnd: tripEnd!,
        onConfirm: (dayDate, timeSlot) async {
          Navigator.pop(ctx);
          await _saveRestaurantToTrip(restaurant, dayDate, timeSlot);
        },
      ),
    );
  }

  Future<void> _saveRestaurantToTrip(RestaurantDetail restaurant, String dayDate, String timeSlot) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.addRestaurantToTrip(
        token: token,
        tripId: widget.trip.id,
        restaurantData: {
          'location_id': restaurant.contentId,
          'name': restaurant.name,
          'cuisine': restaurant.cuisines.join(', '),
          'photo_url': restaurant.photos.isNotEmpty ? restaurant.photos.first.url : '',
          'latitude': restaurant.latitude,
          'longitude': restaurant.longitude,
          'address': restaurant.address,
          'rating': restaurant.rating,
          'num_reviews': restaurant.numReviews,
          'price_level': restaurant.priceLevel,
          'day_date': dayDate,
          'time_slot': timeSlot,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${restaurant.name} added to trip!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('CONFLICT')
            ? 'Already added to this trip'
            : 'Failed to add to trip';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
        );
      }
    }
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
      child: Stack(
        children: [
          ListView.builder(
            controller: _photoScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurant.photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openPhotoViewer(restaurant.photos, index),
                child: Container(
                  width: 320,
                  margin: EdgeInsets.only(right: index < restaurant.photos.length - 1 ? 10 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      restaurant.photos[index].url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Left arrow
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _photoScrollController.animateTo(
                  (_photoScrollController.offset - 330).clamp(0, _photoScrollController.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          // Right arrow
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _photoScrollController.animateTo(
                  (_photoScrollController.offset + 330).clamp(0, _photoScrollController.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          // Photo count
          if (restaurant.photos.length > 1)
            Positioned(
              bottom: 10,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${restaurant.photos.length} photos',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
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

// ─── "Add to Trip" bottom sheet for restaurants ─────────────────────────

class _RestaurantAddToTripSheet extends StatefulWidget {
  final DateTime tripStart;
  final DateTime tripEnd;
  final Future<void> Function(String dayDate, String timeSlot) onConfirm;

  const _RestaurantAddToTripSheet({
    required this.tripStart,
    required this.tripEnd,
    required this.onConfirm,
  });

  @override
  State<_RestaurantAddToTripSheet> createState() => _RestaurantAddToTripSheetState();
}

class _RestaurantAddToTripSheetState extends State<_RestaurantAddToTripSheet> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  bool _saving = false;

  List<DateTime> get _tripDays {
    final days = <DateTime>[];
    var current = DateTime(widget.tripStart.year, widget.tripStart.month, widget.tripStart.day);
    final end = DateTime(widget.tripEnd.year, widget.tripEnd.month, widget.tripEnd.day);
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _tripDays;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add to Schedule',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text('Pick a day', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == day.year &&
                    _selectedDate!.month == day.month &&
                    _selectedDate!.day == day.day;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(day),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(day),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text('Pick a time slot', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSlotChip('morning', 'Morning', Icons.wb_sunny_rounded),
              _buildSlotChip('midday', 'Midday', Icons.light_mode_rounded),
              _buildSlotChip('evening', 'Evening', Icons.wb_twilight_rounded),
              _buildSlotChip('night', 'Night', Icons.nightlight_round),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedDate != null && _selectedSlot != null && !_saving)
                  ? () async {
                      setState(() => _saving = true);
                      final dayStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
                      await widget.onConfirm(dayStr, _selectedSlot!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Confirm', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSlotChip(String value, String label, IconData icon) {
    final isSelected = _selectedSlot == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedSlot = value),
      selectedColor: AppTheme.primaryColor,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
    );
  }
}
