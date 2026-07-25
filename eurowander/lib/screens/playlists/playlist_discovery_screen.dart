import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/widgets.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
    return AppScaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaylistBuilderScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          const EWAppBar(title: 'Discover Playlists'),
          _buildSearchBar(),
          _buildFilterRow(),
          _buildSortRow(),
          Expanded(child: _buildPlaylistGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by city, country or keyword...',
          prefixIcon: Icon(Icons.search, color: context.ew.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: BorderSide.none),
          filled: true,
          fillColor: context.ew.cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        ),
        onSubmitted: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Vibe dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.ew.cardColor,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: _selectedVibe != null ? AppColors.brandPrimary : Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PlaylistVibe?>(
                  value: _selectedVibe,
                  hint: Text('Vibe', style: Theme.of(context).textTheme.bodySmall),
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  items: [
                    DropdownMenuItem<PlaylistVibe?>(
                      value: null,
                      child: Text('All Vibes', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    ...PlaylistVibe.values.map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.displayName, style: Theme.of(context).textTheme.bodySmall),
                    )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedVibe = v);
                    _applyFilters();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Budget dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.ew.cardColor,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: _selectedBudgetTier != null ? AppColors.brandPrimary : Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BudgetTier?>(
                  value: _selectedBudgetTier,
                  hint: Text('Budget', style: Theme.of(context).textTheme.bodySmall),
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  items: [
                    DropdownMenuItem<BudgetTier?>(
                      value: null,
                      child: Text('All Budgets', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    ...BudgetTier.values.map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(b.displayName, style: Theme.of(context).textTheme.bodySmall),
                    )),
                  ],
                  onChanged: (b) {
                    setState(() => _selectedBudgetTier = b);
                    _applyFilters();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
      child: Row(
        children: [
          _buildSortChip('Popular', 'popular'),
          const SizedBox(width: AppSpacing.xs),
          _buildSortChip('Newest', 'newest'),
          const SizedBox(width: AppSpacing.xs),
          _buildSortChip('Top Rated', 'top_rated'),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : context.ew.cardColor,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: isSelected ? AppColors.brandPrimary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : context.ew.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistGrid() {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        if (provider.isSearching && provider.searchResults.isEmpty) {
          return const ShimmerList();
        }
        if (provider.searchResults.isEmpty) {
          return EmptyState(
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
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PlaylistCard(
                playlist: provider.searchResults[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistDetailScreen(playlistId: provider.searchResults[index].id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final PlaylistSummary playlist;
  final VoidCallback onTap;

  const PlaylistCard({super.key, required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vibe = PlaylistVibe.fromString(playlist.vibe);
    final budget = BudgetTier.fromString(playlist.budgetTier);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderLg,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.borderLg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              playlist.coverPhotoUrl.isNotEmpty
                  ? Image.network(playlist.coverPhotoUrl, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.brandPrimary.withOpacity(0.3),
                        child: const Icon(Icons.playlist_play, size: 48, color: Colors.white),
                      ),
                    )
                  : Container(
                      color: AppColors.brandPrimary.withOpacity(0.3),
                      child: const Icon(Icons.playlist_play, size: 48, color: Colors.white),
                    ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              // Top badges
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    _buildBadge(vibe.displayName, AppColors.brandPrimary.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    _buildBadge(budget.displayName, Colors.amber.shade700.withOpacity(0.9)),
                  ],
                ),
              ),
              // Bottom info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${playlist.city}, ${playlist.country}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStat(Icons.favorite, playlist.likeCount.toString()),
                        const SizedBox(width: 12),
                        _buildStat(Icons.download_rounded, playlist.importCount.toString()),
                        const SizedBox(width: 12),
                        _buildStat(Icons.star_rounded, playlist.averageRating.toStringAsFixed(1)),
                        const Spacer(),
                        _buildBadge('${playlist.totalDays}-Day', Colors.white.withOpacity(0.2)),
                        const SizedBox(width: 6),
                        _buildBadge('${playlist.itemCount} spots', Colors.white.withOpacity(0.2)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.borderMd),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 3),
        Text(value, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
