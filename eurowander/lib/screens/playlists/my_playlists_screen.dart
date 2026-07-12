import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import 'playlist_builder_screen.dart';
import 'playlist_detail_screen.dart';

class MyPlaylistsScreen extends StatefulWidget {
  const MyPlaylistsScreen({super.key});

  @override
  State<MyPlaylistsScreen> createState() => _MyPlaylistsScreenState();
}

class _MyPlaylistsScreenState extends State<MyPlaylistsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    context.read<PlaylistProvider>().loadMyPlaylists(token: token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistBuilderScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Consumer<PlaylistProvider>(
            builder: (context, provider, _) {
          if (provider.isLoadingMine) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (provider.myPlaylists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("You haven't created any playlists yet",
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlaylistBuilderScreen()),
                      );
                      _loadData();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Playlist'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = provider.myPlaylists[index];
              return _buildPlaylistTile(playlist);
            },
          );
        },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(PlaylistSummary playlist) {
    final vibe = PlaylistVibe.fromString(playlist.vibe);

    return Dismissible(
      key: Key(playlist.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Playlist'),
            content: Text('Are you sure you want to delete "${playlist.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        final token = context.read<AuthProvider>().token;
        if (token == null) return;
        try {
          await context.read<PlaylistProvider>().deletePlaylist(token: token, id: playlist.id);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: $e')),
            );
            _loadData();
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: playlist.id)),
            );
            _loadData();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: playlist.coverPhotoUrl.isNotEmpty
                        ? Image.network(playlist.coverPhotoUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              child: const Icon(Icons.playlist_play, color: AppTheme.primaryColor),
                            ))
                        : Container(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            child: const Icon(Icons.playlist_play, color: AppTheme.primaryColor),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(playlist.title,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${playlist.city} • ${vibe.displayName}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('❤️ ${playlist.likeCount}', style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 10),
                          Icon(
                            playlist.id.isNotEmpty ? Icons.public : Icons.lock,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
