import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
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
  String? _selectedCity;
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
      city: _selectedCity,
      vibe: _selectedVibe?.apiValue,
      budgetTier: _selectedBudgetTier?.apiValue,
      keyword: _searchController.text.isNotEmpty ? _searchController.text : null,
      sortBy: _sortBy,
    );
    provider.searchPlaylists(token: token, refresh: true);
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
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilterChips(),
              _buildSortRow(),
              Expanded(child: _buildPlaylistGrid()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaylistBuilderScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            'Discover Playlists',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search playlists...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Vibe chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: PlaylistVibe.values.map((vibe) {
                  final isSelected = _selectedVibe == vibe;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${vibe.icon} ${vibe.displayName}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedVibe = selected ? vibe : null);
                        _applyFilters();
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Budget tier chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // City dropdown
                  if (provider.cities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedCity != null ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCity,
                            hint: const Text('City', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Cities')),
                              ...provider.cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedCity = v);
                              _applyFilters();
                            },
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ...BudgetTier.values.map((tier) {
                    final isSelected = _selectedBudgetTier == tier;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('${tier.icon} ${tier.displayName}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedBudgetTier = selected ? tier : null);
                          _applyFilters();
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildSortChip('Popular', 'popular'),
          const SizedBox(width: 8),
          _buildSortChip('Newest', 'newest'),
          const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistGrid() {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        if (provider.isSearching && provider.searchResults.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        if (provider.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.playlist_play_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No playlists found', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Text('Try adjusting your filters', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: provider.searchResults.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.searchResults.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              playlist.coverPhotoUrl.isNotEmpty
                  ? Image.network(playlist.coverPhotoUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        child: const Icon(Icons.playlist_play, size: 48, color: Colors.white),
                      ),
                    )
                  : Container(
                      color: AppTheme.primaryColor.withOpacity(0.3),
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
                    _buildBadge('${vibe.icon} ${vibe.displayName}', AppTheme.primaryColor.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    _buildBadge(budget.icon, Colors.amber.shade700.withOpacity(0.9)),
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
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${playlist.city}, ${playlist.country}',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStat('❤️', playlist.likeCount.toString()),
                        const SizedBox(width: 12),
                        _buildStat('📥', playlist.importCount.toString()),
                        const SizedBox(width: 12),
                        _buildStat('⭐', playlist.averageRating.toStringAsFixed(1)),
                        const Spacer(),
                        _buildBadge('${playlist.totalDays}-Day Plan', Colors.white.withOpacity(0.2)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStat(String icon, String value) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(value, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
