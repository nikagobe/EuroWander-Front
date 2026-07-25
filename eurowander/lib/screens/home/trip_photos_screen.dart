import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../models/photo.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class TripPhotosScreen extends StatefulWidget {
  final SavedTrip trip;

  const TripPhotosScreen({super.key, required this.trip});

  @override
  State<TripPhotosScreen> createState() => _TripPhotosScreenState();
}

class _TripPhotosScreenState extends State<TripPhotosScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  List<TripPhoto> _photos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isUploading = false;
  bool _hasMore = true;
  int _skip = 0;
  final int _limit = 20;
  final Map<String, String> _downloadUrls = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMorePhotos();
    }
  }

  Future<void> _loadPhotos() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final result = await _apiService.listPhotos(
        token: token,
        tripId: widget.trip.id,
        skip: 0,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          _photos = result.items;
          _hasMore = result.hasMore;
          _skip = result.items.length;
          _isLoading = false;
        });
        _preloadUrls(result.items);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading photos: $e');
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoadingMore || !_hasMore) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isLoadingMore = true);
    try {
      final result = await _apiService.listPhotos(
        token: token,
        tripId: widget.trip.id,
        skip: _skip,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          _photos.addAll(result.items);
          _hasMore = result.hasMore;
          _skip += result.items.length;
          _isLoadingMore = false;
        });
        _preloadUrls(result.items);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _preloadUrls(List<TripPhoto> photos) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    for (final photo in photos) {
      if (_downloadUrls.containsKey(photo.id)) continue;
      try {
        final url = await _apiService.getPhotoDownloadUrl(
          token: token,
          tripId: widget.trip.id,
          photoId: photo.id,
        );
        if (mounted) {
          setState(() => _downloadUrls[photo.id] = url);
        }
      } catch (_) {}
    }
  }

  Future<void> _uploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final contentType = _getContentType(file.extension ?? '');
    if (contentType == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported file type')),
        );
      }
      return;
    }

    if (mounted) {
      _showCaptionDialog(
        fileName: file.name,
        fileBytes: file.bytes!,
        contentType: contentType,
        sizeBytes: file.size,
      );
    }
  }

  void _showCaptionDialog({
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
    required int sizeBytes,
  }) {
    final captionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.xl)),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Upload Photo',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                fileName,
                style: Theme.of(ctx).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: captionController,
                decoration: InputDecoration(
                  labelText: 'Caption (optional)',
                  labelStyle: GoogleFonts.poppins(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderMd,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _performUpload(
                      fileName: fileName,
                      fileBytes: fileBytes,
                      contentType: contentType,
                      sizeBytes: sizeBytes,
                      caption: captionController.text.trim().isEmpty
                          ? null
                          : captionController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMd,
                    ),
                  ),
                  child: Text(
                    'Upload',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performUpload({
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
    required int sizeBytes,
    String? caption,
  }) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isUploading = true);

    try {
      final uploadData = await _apiService.requestPhotoUploadUrl(
        token: token,
        tripId: widget.trip.id,
        fileName: fileName,
        contentType: contentType,
        sizeBytes: sizeBytes,
      );

      final uploadUrl = uploadData['upload_url'] as String;
      final fileKey = uploadData['file_key'] as String;

      await _apiService.uploadFileToPresignedUrl(
        uploadUrl: uploadUrl,
        fileBytes: fileBytes,
        contentType: contentType,
      );

      await _apiService.confirmPhotoUpload(
        token: token,
        tripId: widget.trip.id,
        fileKey: fileKey,
        fileName: fileName,
        contentType: contentType,
        sizeBytes: sizeBytes,
        caption: caption,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')),
        );
      }

      setState(() {
        _photos.clear();
        _skip = 0;
        _hasMore = true;
        _isLoading = true;
      });
      await _loadPhotos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(TripPhoto photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.deletePhoto(
        token: token,
        tripId: widget.trip.id,
        photoId: photo.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted')),
        );
        setState(() {
          _photos.removeWhere((p) => p.id == photo.id);
          _downloadUrls.remove(photo.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _openPhotoViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewerPage(
          photos: _photos,
          downloadUrls: _downloadUrls,
          initialIndex: index,
          onDelete: _deletePhoto,
        ),
      ),
    );
  }

  String? _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    final theme = Theme.of(context);

    return AppScaffold(
      child: Column(
        children: [
          EWAppBar(
            title: 'Photos',
            trailing: [
              if (_isUploading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                EWIconButton(
                  icon: Icons.add_photo_alternate_rounded,
                  onTap: _uploadPhoto,
                  backgroundColor: AppColors.brandPrimary,
                  iconColor: Colors.white,
                ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const ShimmerList()
                : _photos.isEmpty
                    ? EmptyState(
                        icon: Icons.photo_library_rounded,
                        title: 'No photos yet',
                        subtitle: 'Capture and share your\ntrip memories',
                        iconColor: AppColors.brandPrimary,
                        actionLabel: 'Upload Photo',
                        onAction: _uploadPhoto,
                      )
                    : _buildPhotoGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: AppSpacing.paddingHorizontalXl,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _photos.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _photos.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final photo = _photos[index];
        final url = _downloadUrls[photo.id];
        return GestureDetector(
          onTap: () => _openPhotoViewer(index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  )
                : const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _PhotoViewerPage extends StatefulWidget {
  final List<TripPhoto> photos;
  final Map<String, String> downloadUrls;
  final int initialIndex;
  final Future<void> Function(TripPhoto) onDelete;

  const _PhotoViewerPage({
    required this.photos,
    required this.downloadUrls,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              final url = widget.downloadUrls[photo.id];
              return Center(
                child: url != null
                    ? InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                      onPressed: () async {
                        final photo = widget.photos[_currentIndex];
                        await widget.onDelete(photo);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.photos[_currentIndex].caption != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    widget.photos[_currentIndex].caption!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (_currentIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 40),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          if (_currentIndex < widget.photos.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 40),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
