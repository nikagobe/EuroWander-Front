import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/document.dart';
import '../../utils/pdf_viewer.dart' as pdf_viewer;

class DocumentViewerPage extends StatefulWidget {
  final TripDocument document;
  final String downloadUrl;

  const DocumentViewerPage({
    super.key,
    required this.document,
    required this.downloadUrl,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  late final String _viewType;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    if (widget.document.contentType == 'application/pdf') {
      _viewType = 'pdf-viewer-${widget.document.id}';
      pdf_viewer.registerPdfViewFactory(_viewType, widget.downloadUrl);
      _registered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content
          Positioned.fill(
            child: _buildContent(),
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.document.displayName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.document.categoryLabel} · ${widget.document.formattedSize}',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.document.contentType.startsWith('image/')) {
      return _buildImageViewer();
    } else if (widget.document.contentType == 'application/pdf' && _registered) {
      return _buildPdfViewer();
    }
    return _buildUnsupported();
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.downloadUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: AppTheme.primaryColor,
              ),
            );
          },
          errorBuilder: (_, __, ___) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: pdf_viewer.buildPdfView(_viewType),
    );
  }

  Widget _buildUnsupported() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded, color: Colors.white54, size: 64),
          SizedBox(height: 16),
          Text(
            'Preview not available for this file type',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
