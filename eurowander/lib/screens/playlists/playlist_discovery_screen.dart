import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/widgets.dart';
import 'my_playlists_screen.dart';
import 'playlist_detail_screen.dart';
import 'playlist_builder_screen.dart';

class PlaylistDiscoveryScreen extends StatefulWidget {
  const PlaylistDiscoveryScreen({super.key});

  @override
  State<PlaylistDiscoveryScreen> createState() => _PlaylistDiscoveryScreenState();
}

class _PlaylistDiscoveryScreenState extends State<PlaylistDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PlaylistVibe? _selectedVibe;
  BudgetTier? _selectedBudgetTier;
  String _sortBy = 'popular';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<PlaylistProvider>();
    provider.loadCities(token: token);
    provider.searchPlaylists(token: token, refresh: true);
  }

  void _loadMore() {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    context.read<PlaylistProvider>().searchPlaylists(token: token);
  }

  void _applyFilters() {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<PlaylistProvider>();
    provider.setFilters(
      vibe: _selectedVibe?.apiValue,
      budgetTier: _selectedBudgetTier?.apiValue,
      keyword: _searchController.text.isNotEmpty ? _searchController.text : null,
      sortBy: _sortBy,
    );
    provider.searchPlaylists(token: token, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    return AppScaffold(
      child: Column(
        children: [
          // Header with back + title + My Playlists + Create
          EWAppBar(
            title: 'Discover Playlists',
            trailing: [
              _buildHeaderAction(
                icon: Icons.library_music_rounded,
                label: 'Mine',
                color: AppColors.brandPrimary,
                onTap: () => Navigator.push(context, EWPageRoute(page: const MyPlaylistsScreen())),
              ),
              _buildHeaderAction(
                icon: Icons.add_rounded,
                label: 'Create',
                color: AppColors.success,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistBuilderScreen())),
              ),
            ],
          ),

          // Hero search
          _buildHeroSearch(ew),

          const SizedBox(height: AppSpacing.sm),

          // Vibe + Budget filters
          _buildFilterChips(ew),

          const SizedBox(height: AppSpacing.xs),

          // Sort + count
          _buildSortRow(ew),

          // Playlist grid
          Expanded(child: _buildPlaylistGrid(ew)),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSearch(EuroWanderTheme ew) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandPrimary.withOpacity(0.08),
            AppColors.info.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.explore_rounded, size: 20, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Text(
                'Curated city guides from travelers',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ew.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by city, country or keyword...',
              hintStyle: TextStyle(fontSize: 13, color: ew.textTertiary),
              prefixIcon: Icon(Icons.search_rounded, color: ew.textSecondary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 18, color: ew.textTertiary),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: ew.cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _applyFilters(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(EuroWanderTheme ew) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          // Vibe chips
          ...PlaylistVibe.values.map((v) {
            final isSelected = _selectedVibe == v;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedVibe = isSelected ? null : v);
                  _applyFilters();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _vibeColor(v.apiValue) : ew.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _vibeColor(v.apiValue) : ew.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: _vibeColor(v.apiValue).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Text(
                    v.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : ew.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Budget divider
          Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), color: ew.border),
          // Budget chips
          ...BudgetTier.values.map((b) {
            final isSelected = _selectedBudgetTier == b;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedBudgetTier = isSelected ? null : b);
                  _applyFilters();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.success : ew.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.success : ew.border),
                  ),
                  child: Text(
                    b.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : ew.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSortRow(EuroWanderTheme ew) {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: Row(
            children: [
              Text(
                '${provider.searchResults.length} playlists',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ew.textTertiary),
              ),
              const Spacer(),
              _buildSortChip('Popular', 'popular', ew),
              const SizedBox(width: 6),
              _buildSortChip('Newest', 'newest', ew),
              const SizedBox(width: 6),
              _buildSortChip('Top Rated', 'top_rated', ew),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortChip(String label, String value, EuroWanderTheme ew) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.brandPrimary : ew.border),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : ew.textSecondary),
        ),
      ),
    );
  }

  Widget _buildPlaylistGrid(EuroWanderTheme ew) {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        if (provider.isSearching && provider.searchResults.isEmpty) {
          return const ShimmerList();
        }
        if (provider.searchResults.isEmpty) {
          return const EmptyState(
            icon: Icons.playlist_play_rounded,
            title: 'No playlists found',
            subtitle: 'Try adjusting your filters',
          );
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          itemCount: provider.searchResults.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.searchResults.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
              );
            }

            final playlist = provider.searchResults[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 350 + (index.clamp(0, 10) * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
              ),
              child: _buildEnhancedPlaylistCard(playlist, ew),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedPlaylistCard(PlaylistSummary p, EuroWanderTheme ew) {
    final vibeCol = _vibeColor(p.vibe);

    return GestureDetector(
      onTap: () => Navigator.push(context, EWPageRoute(page: PlaylistDetailScreen(playlistId: p.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: vibeCol.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            p.coverPhotoUrl.isNotEmpty
                ? Image.network(p.coverPhotoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [vibeCol, vibeCol.withOpacity(0.7)]),
                      ),
                      child: Icon(Icons.queue_music_rounded, size: 48, color: Colors.white.withOpacity(0.4)),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [vibeCol, vibeCol.withOpacity(0.6)],
                      ),
                    ),
                    child: Icon(Icons.queue_music_rounded, size: 48, color: Colors.white.withOpacity(0.4)),
                  ),

            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.7)],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),

            // Top badges
            Positioned(
              top: 12, left: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: vibeCol.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(p.vibe, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(p.budgetTier, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
            ),

            // Days badge top-right
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('${p.totalDays}d', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),

            // Bottom info
            Positioned(
              bottom: 14, left: 14, right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text(
                        '${p.city}, ${p.country}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStat(Icons.favorite_rounded, '${p.likeCount}'),
                      const SizedBox(width: 10),
                      _buildStat(Icons.download_rounded, '${p.importCount}'),
                      if (p.averageRating > 0) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFF9800)),
                        const SizedBox(width: 2),
                        Text(p.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text('${p.itemCount} spots', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tap arrow
            Positioned(
              right: 14, top: 0, bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white.withOpacity(0.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 3),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
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
}
