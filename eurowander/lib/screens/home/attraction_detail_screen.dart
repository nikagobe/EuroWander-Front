import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attraction.dart';
import '../../models/saved_trip.dart';
import '../../services/api_service.dart';
import 'restaurant_detail_screen.dart';

class AttractionDetailScreen extends StatefulWidget {
  final String contentId;
  final String startDate;
  final String endDate;
  final SavedTrip trip;

  const AttractionDetailScreen({
    super.key,
    required this.contentId,
    required this.startDate,
    required this.endDate,
    required this.trip,
  });

  @override
  State<AttractionDetailScreen> createState() => _AttractionDetailScreenState();
}

class _AttractionDetailScreenState extends State<AttractionDetailScreen> {
  final ApiService _apiService = ApiService();
  AttractionDetail? _details;
  bool _isLoading = true;

  // Expandable sections state
  bool _reviewsExpanded = false;
  bool _reviewsLoading = false;
  List<AttractionReview> _reviews = [];

  bool _nearbyExpanded = false;
  bool _nearbyLoading = false;
  List<NearbyAttractionCard> _nearbyAttractions = [];
  List<NearbyRestaurantCard> _nearbyRestaurants = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _apiService.getAttractionDetails(
      contentId: widget.contentId,
      startDate: widget.startDate,
      endDate: widget.endDate,
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
    final reviews = await _apiService.getAttractionReviews(contentId: widget.contentId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
      });
    }
  }

  Future<void> _loadNearby() async {
    if (_nearbyLoading || _nearbyAttractions.isNotEmpty || _nearbyRestaurants.isNotEmpty) return;
    setState(() => _nearbyLoading = true);
    final data = await _apiService.getAttractionNearby(contentId: widget.contentId);
    if (mounted) {
      setState(() {
        if (data['nearby_attractions'] is List) {
          _nearbyAttractions = (data['nearby_attractions'] as List)
              .map((e) => NearbyAttractionCard.fromJson(e))
              .toList();
        }
        if (data['nearby_restaurants'] is List) {
          _nearbyRestaurants = (data['nearby_restaurants'] as List)
              .map((e) => NearbyRestaurantCard.fromJson(e))
              .toList();
        }
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
          Text('Failed to load attraction details', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary)),
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
    final attraction = _details!;
    return Column(
      children: [
        _buildAppBar(attraction),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoGallery(attraction),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(attraction),
                          const SizedBox(height: 20),
                          _buildInfoCard(attraction),
                          const SizedBox(height: 20),
                          _buildMap(attraction),
                          if (attraction.description.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildDescription(attraction),
                          ],
                          if (attraction.aboutItems.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildAboutItems(attraction),
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

  Widget _buildAppBar(AttractionDetail attraction) {
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
              attraction.name,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(AttractionDetail attraction) {
    if (attraction.photos.isEmpty) {
      return Container(
        height: 220,
        color: Colors.grey.shade200,
        child: Center(child: Icon(Icons.attractions_rounded, size: 56, color: Colors.grey.shade400)),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: attraction.photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openPhotoViewer(attraction.photos, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                attraction.photos[index].url,
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

  void _openPhotoViewer(List<AttractionPhoto> photos, int initialIndex) {
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

  Widget _buildHeader(AttractionDetail attraction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          attraction.name,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade600),
            const SizedBox(width: 4),
            Text('${attraction.rating}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text('(${attraction.numReviews} reviews)', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          attraction.category,
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
        ),
        if (attraction.ranking.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            attraction.ranking,
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(AttractionDetail attraction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          if (attraction.address.isNotEmpty)
            _buildInfoRow(Icons.location_on_rounded, attraction.address),
          if (attraction.hoursStatus.isNotEmpty)
            _buildInfoRow(Icons.access_time_rounded, attraction.hoursStatus),
          if (attraction.todaySchedule.isNotEmpty)
            _buildInfoRow(Icons.schedule_rounded, attraction.todaySchedule.join(', ')),
          if (attraction.phone.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:${attraction.phone}')),
              child: _buildInfoRow(Icons.phone_rounded, attraction.phone),
            ),
          if (attraction.website.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(attraction.website), mode: LaunchMode.externalApplication),
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

  Widget _buildMap(AttractionDetail attraction) {
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
                initialCenter: LatLng(attraction.latitude, attraction.longitude),
                initialZoom: 15,
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(attraction.latitude, attraction.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.attractions_rounded, color: Colors.white, size: 20),
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

  Widget _buildDescription(AttractionDetail attraction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(
          attraction.description,
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildAboutItems(AttractionDetail attraction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: attraction.aboutItems.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(item, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryColor)),
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
          title: Text('Nearby Places', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          subtitle: Text('Attractions & restaurants nearby', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
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
            else ...[
              if (_nearbyAttractions.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Attractions', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyAttractions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final nearby = _nearbyAttractions[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AttractionDetailScreen(
                              contentId: nearby.contentId,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
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
                              Text(nearby.category, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary), maxLines: 1),
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
                const SizedBox(height: 12),
              ],
              if (_nearbyRestaurants.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Restaurants', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
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
              if (_nearbyAttractions.isEmpty && _nearbyRestaurants.isEmpty && !_nearbyLoading)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No nearby places found', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                ),
            ],
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
