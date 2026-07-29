import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/widgets.dart';
import 'playlist_builder_screen.dart';
import 'import_wizard_sheet.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<PlaylistProvider>();
    provider.loadPlaylist(token: token, id: widget.playlistId);
    provider.loadReviews(token: token, playlistId: widget.playlistId, refresh: true);
  }

  Color _vibeColor(String vibe) {
    switch (vibe.toLowerCase()) {
      case 'adventure': return const Color(0xFFE65100);
      case 'romantic': return const Color(0xFFE91E63);
      case 'cultural': return const Color(0xFF7B1FA2);
      case 'foodie': return const Color(0xFFF57C00);
      case 'luxury': return const Color(0xFFFF9800);
      case 'budget': return const Color(0xFF4CAF50);
      case 'party': return const Color(0xFFE040FB);
      default: return AppColors.brandPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDetail) {
            return Container(
              decoration: BoxDecoration(gradient: context.ew.surfaceGradient),
              child: const Center(child: ShimmerList()),
            );
          }
          if (provider.detailError != null) {
            return Container(
              decoration: BoxDecoration(gradient: context.ew.surfaceGradient),
              child: Center(child: EmptyState(icon: Icons.error_outline, title: 'Something went wrong', subtitle: provider.detailError)),
            );
          }
          final playlist = provider.currentPlaylist;
          if (playlist == null) return const SizedBox.shrink();

          return Container(
            decoration: BoxDecoration(gradient: context.ew.surfaceGradient),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeroCover(playlist),
                    SliverToBoxAdapter(child: _buildInfoSection(playlist)),
                    SliverToBoxAdapter(child: _buildActionButtons(playlist)),
                    SliverToBoxAdapter(child: _buildTagsSection(playlist)),
                    ..._buildDayItemsList(playlist),
                    SliverToBoxAdapter(child: _buildReviewsSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // â”€â”€â”€ Hero Cover â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHeroCover(Playlist playlist) {
    final vibeCol = _vibeColor(playlist.vibes.isNotEmpty ? playlist.vibes.first : 'chill');

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: vibeCol,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            if (playlist.coverPhotoUrl.isNotEmpty)
              Image.network(playlist.coverPhotoUrl, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _gradientCover(vibeCol))
            else
              _gradientCover(vibeCol),

            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),

            // Top-right badges
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: vibeCol.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      playlist.vibes.isNotEmpty ? playlist.vibes.first : 'Chill',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${playlist.totalDays}d', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ],
              ),
            ),

            // Bottom content overlay
            Positioned(
              bottom: 16, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    playlist.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${playlist.city}, ${playlist.country}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Stats chips
                  Row(
                    children: [
                      _coverStat(Icons.favorite_rounded, '${playlist.likeCount}'),
                      const SizedBox(width: 8),
                      _coverStat(Icons.download_rounded, '${playlist.importCount}'),
                      if (playlist.averageRating > 0) ...[
                        const SizedBox(width: 8),
                        _coverStat(Icons.star_rounded, playlist.averageRating.toStringAsFixed(1)),
                      ],
                      const SizedBox(width: 8),
                      _coverStat(Icons.place_rounded, '${playlist.items.length} spots'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientCover(Color vibeCol) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [vibeCol, vibeCol.withOpacity(0.6)],
        ),
      ),
      child: Center(child: Icon(Icons.queue_music_rounded, size: 64, color: Colors.white.withOpacity(0.3))),
    );
  }

  Widget _coverStat(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }

  // â”€â”€â”€ Info Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildInfoSection(Playlist playlist) {
    final ew = context.ew;
    final vibeCol = _vibeColor(playlist.vibes.isNotEmpty ? playlist.vibes.first : 'chill');
    final budget = BudgetTier.fromString(playlist.budgetTier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator row
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [vibeCol, vibeCol.withOpacity(0.6)]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${playlist.creatorFirstName.isNotEmpty ? playlist.creatorFirstName[0] : ''}${playlist.creatorLastName.isNotEmpty ? playlist.creatorLastName[0] : ''}'.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${playlist.creatorFirstName} ${playlist.creatorLastName}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ew.textPrimary),
                  ),
                  Text('Creator', style: TextStyle(fontSize: 11, color: ew.textTertiary)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(budget.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          if (playlist.description.isNotEmpty) ...[
            Text(playlist.description, style: TextStyle(fontSize: 14, height: 1.5, color: ew.textPrimary)),
            const SizedBox(height: 16),
          ],

          // Vibe badges
          if (playlist.vibes.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: playlist.vibes.map((v) {
                final col = _vibeColor(v);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: col.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: col)),
                  ]),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // â”€â”€â”€ Action Buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildActionButtons(Playlist playlist) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isOwner = currentUserId == playlist.creatorId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: playlist.isLikedByMe ? Icons.favorite : Icons.favorite_border,
              label: playlist.isLikedByMe ? 'Liked' : 'Like',
              color: Colors.red,
              onTap: () async {
                final token = context.read<AuthProvider>().token;
                if (token == null) return;
                await context.read<PlaylistProvider>().toggleLike(token: token, id: playlist.id);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.download_rounded,
              label: 'Import',
              color: AppColors.brandPrimary,
              onTap: () => _showImportWizard(playlist),
            ),
          ),
          const SizedBox(width: 8),
          if (isOwner)
            Expanded(
              child: _ActionButton(
                icon: Icons.edit_rounded,
                label: 'Edit',
                color: AppColors.brandAmber,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlaylistBuilderScreen(editPlaylistId: playlist.id)),
                  );
                  _loadData();
                },
              ),
            )
          else
            Expanded(
              child: _ActionButton(
                icon: Icons.fork_right_rounded,
                label: 'Fork',
                color: AppColors.success,
                onTap: () async {
                  final token = context.read<AuthProvider>().token;
                  if (token == null) return;
                  final forked = await context.read<PlaylistProvider>().forkPlaylist(token: token, id: playlist.id);
                  if (forked != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Forked "${forked.title}" to your playlists!')),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showImportWizard(Playlist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImportWizardSheet(playlist: playlist),
    );
  }

  // â”€â”€â”€ Tags Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTagsSection(Playlist playlist) {
    if (playlist.tags.isEmpty) return const SizedBox.shrink();
    final ew = context.ew;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: playlist.tags.map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.brandPrimary.withOpacity(0.1)),
          ),
          child: Text('#$tag', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: ew.textSecondary)),
        )).toList(),
      ),
    );
  }

  // â”€â”€â”€ Day Items List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<Widget> _buildDayItemsList(Playlist playlist) {
    final slivers = <Widget>[];
    final ew = context.ew;

    for (int day = 1; day <= playlist.totalDays; day++) {
      final dayItems = playlist.items.where((i) => i.dayNumber == day).toList();
      dayItems.sort((a, b) {
        final slotOrder = ['morning', 'midday', 'evening', 'night'];
        final cmp = slotOrder.indexOf(a.timeSlot).compareTo(slotOrder.indexOf(b.timeSlot));
        return cmp != 0 ? cmp : a.order.compareTo(b.order);
      });

      // Day header
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('$day', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 10),
              Text('Day $day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ew.textPrimary)),
              const Spacer(),
              Text('${dayItems.length} spots', style: TextStyle(fontSize: 12, color: ew.textTertiary)),
            ],
          ),
        ),
      ));

      for (final slot in ['morning', 'midday', 'evening', 'night']) {
        final slotItems = dayItems.where((i) => i.timeSlot == slot).toList();
        if (slotItems.isEmpty) continue;

        // Time slot header
        slivers.add(SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _timeSlotColor(slot).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_timeSlotIconData(slot), size: 14, color: _timeSlotColor(slot)),
                ),
                const SizedBox(width: 8),
                Text(_timeSlotLabel(slot), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _timeSlotColor(slot))),
              ],
            ),
          ),
        ));

        slivers.add(SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildItemCard(slotItems[index], index),
            childCount: slotItems.length,
          ),
        ));
      }
    }
    return slivers;
  }

  Widget _buildItemCard(PlaylistItem item, int index) {
    final ew = context.ew;
    final isCustom = item.itemType == 'custom';
    final itemColor = _itemTypeColor(item.itemType);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isCustom ? Colors.amber.shade200 : ew.borderSubtle),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo with colored border
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: itemColor.withOpacity(0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56, height: 56,
                    child: item.photoUrl.isNotEmpty
                        ? Image.network(item.photoUrl, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholderIcon(item))
                        : _buildPlaceholderIcon(item),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isCustom) Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.push_pin_rounded, size: 13, color: Colors.amber.shade700),
                        ),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ew.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (item.category.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: itemColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(item.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: itemColor)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (item.rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFF9800)),
                          const SizedBox(width: 2),
                          Text('${item.rating}', style: TextStyle(fontSize: 11, color: ew.textSecondary)),
                          const SizedBox(width: 6),
                        ],
                        if (item.priceIndicator.isNotEmpty)
                          Text(item.priceIndicator, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
              // Duration badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ew.borderSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${item.suggestedDurationMinutes}m', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ew.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(PlaylistItem item) {
    final color = _itemTypeColor(item.itemType);
    IconData icon;
    switch (item.itemType) {
      case 'attraction': icon = Icons.attractions_rounded;
      case 'restaurant': icon = Icons.restaurant_rounded;
      default: icon = Icons.push_pin_rounded;
    }
    return Container(color: color.withOpacity(0.1), child: Icon(icon, color: color, size: 26));
  }

  // â”€â”€â”€ Reviews â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildReviewsSection() {
    final ew = context.ew;
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Separator
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, ew.border, Colors.transparent],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rate_review_rounded, size: 18, color: Color(0xFFFF9800)),
                  ),
                  const SizedBox(width: 10),
                  Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ew.textPrimary)),
                  if (provider.reviews.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: ew.borderSubtle, borderRadius: BorderRadius.circular(10)),
                      child: Text('${provider.reviews.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ew.textSecondary)),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddReviewSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_rounded, size: 14, color: AppColors.brandPrimary),
                        SizedBox(width: 4),
                        Text('Write', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandPrimary)),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (provider.reviews.isEmpty && !provider.isLoadingReviews)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ew.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ew.borderSubtle),
                  ),
                  child: Center(
                    child: Column(children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 28, color: ew.textTertiary),
                      const SizedBox(height: 8),
                      Text('No reviews yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ew.textSecondary)),
                      Text('Be the first to share your thoughts!', style: TextStyle(fontSize: 11, color: ew.textTertiary)),
                    ]),
                  ),
                ),

              ...provider.reviews.map((review) => _buildReviewCard(review)),

              if (provider.isLoadingReviews)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.brandPrimary),
                )),
              if (provider.hasMoreReviews && !provider.isLoadingReviews)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      final token = context.read<AuthProvider>().token;
                      if (token == null) return;
                      provider.loadReviews(token: token, playlistId: widget.playlistId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Load more reviews', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brandPrimary)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(PlaylistReview review) {
    final ew = context.ew;
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ew.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${review.userFirstName.isNotEmpty ? review.userFirstName[0] : ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${review.userFirstName} ${review.userLastName}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ew.textPrimary)),
                    Text(_formatDate(review.createdAt), style: TextStyle(fontSize: 10, color: ew.textTertiary)),
                  ],
                ),
              ),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14,
                  color: i < review.rating ? const Color(0xFFFF9800) : ew.textTertiary,
                )),
              ),
              if (currentUserId == review.userId)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final token = context.read<AuthProvider>().token;
                    if (token == null) return;
                    await context.read<PlaylistProvider>().deleteReview(
                      token: token, playlistId: widget.playlistId, reviewId: review.id,
                    );
                  },
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment, style: TextStyle(fontSize: 13, height: 1.4, color: ew.textPrimary)),
          ],
        ],
      ),
    );
  }

  void _showAddReviewSheet() {
    int rating = 5;
    final commentController = TextEditingController();
    final ew = context.ew;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ew.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Write a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setSheetState(() => rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFFF9800),
                      size: 36,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  hintStyle: TextStyle(color: ew.textTertiary),
                  filled: true,
                  fillColor: ew.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Submit Review',
                  onTap: () async {
                    final token = context.read<AuthProvider>().token;
                    if (token == null) return;
                    try {
                      await context.read<PlaylistProvider>().addReview(
                        token: token, playlistId: widget.playlistId,
                        rating: rating, comment: commentController.text,
                      );
                      if (mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Color _itemTypeColor(String itemType) {
    switch (itemType) {
      case 'attraction': return Colors.deepOrange;
      case 'restaurant': return const Color(0xFF4CAF50);
      default: return Colors.amber.shade700;
    }
  }

  Color _timeSlotColor(String slot) {
    switch (slot) {
      case 'morning': return const Color(0xFFFF9800);
      case 'midday': return const Color(0xFF2196F3);
      case 'evening': return const Color(0xFF9C27B0);
      case 'night': return const Color(0xFF3F51B5);
      default: return AppColors.brandPrimary;
    }
  }

  IconData _timeSlotIconData(String slot) {
    switch (slot) {
      case 'morning': return Icons.wb_sunny_rounded;
      case 'midday': return Icons.light_mode_rounded;
      case 'evening': return Icons.wb_twilight_rounded;
      case 'night': return Icons.nightlight_round;
      default: return Icons.schedule_rounded;
    }
  }

  String _timeSlotLabel(String slot) {
    switch (slot) {
      case 'morning': return 'Morning';
      case 'midday': return 'Midday';
      case 'evening': return 'Evening';
      case 'night': return 'Night';
      default: return slot;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

