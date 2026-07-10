import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDetail) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (provider.detailError != null) {
            return Center(child: Text('Error: ${provider.detailError}'));
          }
          final playlist = provider.currentPlaylist;
          if (playlist == null) return const SizedBox.shrink();
          return CustomScrollView(
            slivers: [
              _buildHeroAppBar(playlist),
              SliverToBoxAdapter(child: _buildInfoSection(playlist)),
              SliverToBoxAdapter(child: _buildActionButtons(playlist)),
              SliverToBoxAdapter(child: _buildTagsSection(playlist)),
              ..._buildDayItemsList(playlist),
              SliverToBoxAdapter(child: _buildReviewsSection()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroAppBar(Playlist playlist) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          playlist.title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            playlist.coverPhotoUrl.isNotEmpty
                ? Image.network(playlist.coverPhotoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryColor))
                : Container(color: AppTheme.primaryColor),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(Playlist playlist) {
    final vibe = PlaylistVibe.fromString(playlist.vibe);
    final budget = BudgetTier.fromString(playlist.budgetTier);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator
          Text(
            'By ${playlist.creatorFirstName} ${playlist.creatorLastName}',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          // Description
          if (playlist.description.isNotEmpty)
            Text(playlist.description, style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          // Badges
          Row(
            children: [
              _buildChip('${vibe.icon} ${vibe.displayName}', AppTheme.primaryColor),
              const SizedBox(width: 8),
              _buildChip('${budget.icon} ${budget.displayName}', Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _buildStatItem('❤️', '${playlist.likeCount} likes'),
              const SizedBox(width: 16),
              _buildStatItem('📥', '${playlist.importCount} imports'),
              const SizedBox(width: 16),
              _buildStatItem('⭐', '${playlist.averageRating.toStringAsFixed(1)} (${playlist.reviewCount})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Playlist playlist) {
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
              color: AppTheme.primaryColor,
              onTap: () => _showImportWizard(playlist),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.fork_right_rounded,
              label: 'Fork',
              color: Colors.teal,
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

  Widget _buildTagsSection(Playlist playlist) {
    if (playlist.tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: playlist.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('#$tag', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildDayItemsList(Playlist playlist) {
    final slivers = <Widget>[];
    for (int day = 1; day <= playlist.totalDays; day++) {
      final dayItems = playlist.items.where((i) => i.dayNumber == day).toList();
      dayItems.sort((a, b) {
        final slotOrder = ['morning', 'midday', 'evening', 'night'];
        final cmp = slotOrder.indexOf(a.timeSlot).compareTo(slotOrder.indexOf(b.timeSlot));
        return cmp != 0 ? cmp : a.order.compareTo(b.order);
      });

      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            'Day $day',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ),
      ));

      for (final slot in ['morning', 'midday', 'evening', 'night']) {
        final slotItems = dayItems.where((i) => i.timeSlot == slot).toList();
        if (slotItems.isEmpty) continue;
        slivers.add(SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Text(_timeSlotIcon(slot), style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  _timeSlotLabel(slot),
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ));
        slivers.add(SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildItemCard(slotItems[index]),
            childCount: slotItems.length,
          ),
        ));
      }
    }
    return slivers;
  }

  Widget _buildItemCard(PlaylistItem item) {
    final isCustom = item.itemType == 'custom';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isCustom ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCustom ? Border.all(color: Colors.amber.shade200) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: item.photoUrl.isNotEmpty
                    ? Image.network(item.photoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderIcon(item))
                    : _buildPlaceholderIcon(item),
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
                      if (isCustom) const Text('📌 ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          item.name,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (item.category.isNotEmpty)
                    Text(item.category, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.priceIndicator.isNotEmpty)
                        Text(item.priceIndicator, style: const TextStyle(fontSize: 11, color: Colors.green)),
                      if (item.priceIndicator.isNotEmpty) const SizedBox(width: 8),
                      Text('~${item.suggestedDurationMinutes}min',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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

  Widget _buildPlaceholderIcon(PlaylistItem item) {
    IconData icon;
    Color color;
    switch (item.itemType) {
      case 'attraction':
        icon = Icons.attractions_rounded;
        color = Colors.deepOrange;
        break;
      case 'restaurant':
        icon = Icons.restaurant_rounded;
        color = Colors.green;
        break;
      default:
        icon = Icons.push_pin_rounded;
        color = Colors.amber.shade700;
    }
    return Container(color: color.withOpacity(0.1), child: Icon(icon, color: color, size: 28));
  }

  Widget _buildReviewsSection() {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Reviews', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddReviewSheet(),
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Write'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (provider.reviews.isEmpty && !provider.isLoadingReviews)
                const Text('No reviews yet. Be the first!', style: TextStyle(color: AppTheme.textSecondary)),
              ...provider.reviews.map((review) => _buildReviewCard(review)),
              if (provider.isLoadingReviews)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                )),
              if (provider.hasMoreReviews && !provider.isLoadingReviews)
                Center(
                  child: TextButton(
                    onPressed: () {
                      final token = context.read<AuthProvider>().token;
                      if (token == null) return;
                      provider.loadReviews(token: token, playlistId: widget.playlistId);
                    },
                    child: const Text('Load more'),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(PlaylistReview review) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${review.userFirstName} ${review.userLastName}',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              ...List.generate(5, (i) => Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                size: 14,
                color: Colors.amber,
              )),
              if (currentUserId == review.userId)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () async {
                    final token = context.read<AuthProvider>().token;
                    if (token == null) return;
                    await context.read<PlaylistProvider>().deleteReview(
                      token: token,
                      playlistId: widget.playlistId,
                      reviewId: review.id,
                    );
                  },
                ),
            ],
          ),
          if (review.comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(review.comment, style: const TextStyle(fontSize: 13)),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatDate(review.createdAt),
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReviewSheet() {
    int rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Write a Review', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setSheetState(() => rating = i + 1),
                )),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final token = context.read<AuthProvider>().token;
                    if (token == null) return;
                    try {
                      await context.read<PlaylistProvider>().addReview(
                        token: token,
                        playlistId: widget.playlistId,
                        rating: rating,
                        comment: commentController.text,
                      );
                      if (mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildStatItem(String icon, String text) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  String _timeSlotIcon(String slot) {
    switch (slot) {
      case 'morning': return '🌅';
      case 'midday': return '☀️';
      case 'evening': return '🌆';
      case 'night': return '🌙';
      default: return '⏰';
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
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
