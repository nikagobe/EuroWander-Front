import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/document.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'document_viewer_page.dart';

class TripDocumentsScreen extends StatefulWidget {
  final SavedTrip trip;

  const TripDocumentsScreen({super.key, required this.trip});

  @override
  State<TripDocumentsScreen> createState() => _TripDocumentsScreenState();
}

class _TripDocumentsScreenState extends State<TripDocumentsScreen> {
  final ApiService _apiService = ApiService();
  List<TripDocument> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final docs = await _apiService.listDocuments(
        token: token,
        tripId: widget.trip.id,
      );
      if (mounted) setState(() { _documents = docs; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading documents: $e');
    }
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
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

    if (file.size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size exceeds 10MB limit')),
        );
      }
      return;
    }

    if (mounted) {
      _showUploadDialog(
        fileName: file.name,
        fileBytes: file.bytes!,
        contentType: contentType,
        sizeBytes: file.size,
      );
    }
  }

  void _showUploadDialog({
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
    required int sizeBytes,
  }) {
    String selectedCategory = 'other';
    String selectedVisibility = 'group';
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 20),
                Text(
                  'Upload Document',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fileName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Document Name (optional)',
                    labelStyle: GoogleFonts.poppins(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Category',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'boarding_pass',
                    'hotel_confirmation',
                    'passport',
                    'visa',
                    'insurance',
                    'ticket',
                    'other',
                  ].map((cat) {
                    final isSelected = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(_categoryLabel(cat)),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setSheetState(() => selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Visibility',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Group'),
                      selected: selectedVisibility == 'group',
                      selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: selectedVisibility == 'group'
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        fontWeight: selectedVisibility == 'group'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setSheetState(() => selectedVisibility = 'group');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Private'),
                      selected: selectedVisibility == 'private',
                      selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: selectedVisibility == 'private'
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        fontWeight: selectedVisibility == 'private'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setSheetState(() => selectedVisibility = 'private');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                        category: selectedCategory,
                        visibility: selectedVisibility,
                        name: nameController.text.trim().isEmpty
                            ? null
                            : nameController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Upload',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    required String category,
    required String visibility,
    String? name,
  }) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isUploading = true);

    try {
      // Step 1: Get presigned upload URL
      final uploadData = await _apiService.requestDocumentUploadUrl(
        token: token,
        tripId: widget.trip.id,
        fileName: fileName,
        contentType: contentType,
        sizeBytes: sizeBytes,
        category: category,
      );

      final uploadUrl = uploadData['upload_url'] as String;
      final fileKey = uploadData['file_key'] as String;

      // Step 2: Upload file to presigned URL
      await _apiService.uploadFileToPresignedUrl(
        uploadUrl: uploadUrl,
        fileBytes: fileBytes,
        contentType: contentType,
      );

      // Step 3: Confirm upload
      await _apiService.confirmDocumentUpload(
        token: token,
        tripId: widget.trip.id,
        fileKey: fileKey,
        fileName: fileName,
        contentType: contentType,
        sizeBytes: sizeBytes,
        category: category,
        visibility: visibility,
        name: name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }
      await _loadDocuments();
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

  Future<void> _deleteDocument(TripDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.displayName}"?'),
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
      await _apiService.deleteDocument(
        token: token,
        tripId: widget.trip.id,
        documentId: doc.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
      await _loadDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _openDocument(TripDocument doc) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final url = await _apiService.getDocumentDownloadUrl(
        token: token,
        tripId: widget.trip.id,
        documentId: doc.id,
      );
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentViewerPage(
              document: doc,
              downloadUrl: url,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open: $e')),
        );
      }
    }
  }

  String? _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
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

  String _categoryLabel(String category) {
    switch (category) {
      case 'boarding_pass':
        return 'Boarding Pass';
      case 'hotel_confirmation':
        return 'Hotel Confirmation';
      case 'passport':
        return 'Passport';
      case 'visa':
        return 'Visa';
      case 'insurance':
        return 'Insurance';
      case 'ticket':
        return 'Ticket';
      default:
        return 'Other';
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'boarding_pass':
        return Icons.flight_takeoff_rounded;
      case 'hotel_confirmation':
        return Icons.hotel_rounded;
      case 'passport':
        return Icons.badge_rounded;
      case 'visa':
        return Icons.verified_rounded;
      case 'insurance':
        return Icons.shield_rounded;
      case 'ticket':
        return Icons.confirmation_number_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'boarding_pass':
        return const Color(0xFF2196F3);
      case 'hotel_confirmation':
        return const Color(0xFFFF9800);
      case 'passport':
        return const Color(0xFF9C27B0);
      case 'visa':
        return const Color(0xFF4CAF50);
      case 'insurance':
        return const Color(0xFF00BCD4);
      case 'ticket':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F5FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _documents.isEmpty
                            ? _buildEmptyState()
                            : _buildDocumentList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Documents',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isUploading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: _uploadDocument,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.description_rounded,
              size: 40,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No documents yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload passports, tickets, and\nother travel documents',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _uploadDocument,
            icon: const Icon(Icons.upload_rounded),
            label: Text(
              'Upload Document',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    // Group documents by category
    final grouped = <String, List<TripDocument>>{};
    for (final doc in _documents) {
      grouped.putIfAbsent(doc.category, () => []).add(doc);
    }

    final categories = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final docs = grouped[category]!;
          return _buildCategorySection(category, docs);
        },
      ),
    );
  }

  Widget _buildCategorySection(String category, List<TripDocument> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            children: [
              Icon(
                _categoryIcon(category),
                size: 18,
                color: _categoryColor(category),
              ),
              const SizedBox(width: 8),
              Text(
                _categoryLabel(category),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _categoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${docs.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _categoryColor(category),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...docs.map((doc) => _buildDocumentCard(doc)),
      ],
    );
  }

  Widget _buildDocumentCard(TripDocument doc) {
    final color = _categoryColor(doc.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDocument(doc),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    doc.contentType == 'application/pdf'
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            doc.formattedSize,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '·',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, y').format(doc.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (doc.visibility == 'private') ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: Colors.red[400],
                  onPressed: () => _deleteDocument(doc),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
