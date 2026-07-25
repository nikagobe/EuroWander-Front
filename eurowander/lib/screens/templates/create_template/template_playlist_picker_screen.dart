import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/playlist.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/playlist_service.dart';
import '../../playlists/playlist_builder_screen.dart';

/// Lightweight playlist picker for template creation.
/// Returns {'id': playlistId, 'name': playlistTitle} on selection.
class TemplatePlaylistPickerScreen extends StatefulWidget {
  final String? city;

  const TemplatePlaylistPickerScreen({super.key, this.city});

  @override
  State<TemplatePlaylistPickerScreen> createState() => _TemplatePlaylistPickerScreenState();
}

class _TemplatePlaylistPickerScreenState extends State<TemplatePlaylistPickerScreen> {
  final PlaylistService _service = PlaylistService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<PlaylistSummary> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Auto-search by city if provided
    if (widget.city != null && widget.city!.isNotEmpty) {
      _searchController.text = widget.city!;
      _search(city: widget.city);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(keyword: query));
  }

  Future<void> _search({String? city, String? keyword}) async {
    final token = context.read<AuthProvider>().token ?? '';
    setState(() { _isLoading = true; _hasSearched = true; });
    try {
      final results = await _service.searchPlaylists(
        token: token,
        city: city,
        keyword: keyword,
        limit: 30,
      );
      if (mounted) setState(() => _results = results);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createNew() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PlaylistBuilderScreen()),
    );
    if (result != null && mounted) {
      // Reload playlists to find the newly created one
      final token = context.read<AuthProvider>().token ?? '';
      final myPlaylists = await _service.getMyPlaylists(token: token);
      if (myPlaylists.isNotEmpty && mounted) {
        // The newest playlist should be the one just created
        final newest = myPlaylists.first;
        Navigator.pop(context, {'id': newest.id, 'name': newest.title});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)])),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Attach Playlist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                  ]),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search playlists by city or keyword...',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.primaryColor),
                      suffixIcon: _isLoading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))) : null,
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Create new button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _createNew,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create new playlist'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Results
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                      : !_hasSearched
                          ? Center(child: Text('Search for playlists or create a new one', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)))
                          : _results.isEmpty
                              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.playlist_play_rounded, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text('No playlists found', style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary)),
                                ]))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _results.length,
                                  itemBuilder: (_, i) => _buildPlaylistCard(_results[i]),
                                ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(PlaylistSummary playlist) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, {'id': playlist.id, 'name': playlist.title}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: playlist.coverPhotoUrl.isNotEmpty
                ? Image.network(playlist.coverPhotoUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(playlist.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${playlist.city}${playlist.country.isNotEmpty ? ", ${playlist.country}" : ""} • ${playlist.itemCount} items', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Row(children: [
              if (playlist.averageRating > 0) ...[
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(playlist.averageRating.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
              ],
              Text('❤️ ${playlist.likeCount}', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              Text('📥 ${playlist.importCount}', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ])),
          const Icon(Icons.chevron_right_rounded, size: 22, color: AppTheme.textSecondary),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.playlist_play_rounded, color: AppTheme.primaryColor, size: 24),
  );
}
