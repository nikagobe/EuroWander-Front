// ignore_for_file: unused_element, unused_local_variable
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/widgets.dart';
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
                  'Upload Document',
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
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Document Name (optional)',
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
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Category',
                  style: Theme.of(ctx).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
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
                      selectedColor: AppColors.brandPrimary.withOpacity(0.15),
                      labelStyle: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                        color: isSelected ? AppColors.brandPrimary : context.ew.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setSheetState(() => selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Visibility',
                  style: Theme.of(ctx).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Group'),
                      selected: selectedVisibility == 'group',
                      selectedColor: AppColors.brandPrimary.withOpacity(0.15),
                      labelStyle: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                        color: selectedVisibility == 'group'
                            ? AppColors.brandPrimary
                            : context.ew.textSecondary,
                        fontWeight: selectedVisibility == 'group'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setSheetState(() => selectedVisibility = 'group');
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      label: const Text('Private'),
                      selected: selectedVisibility == 'private',
                      selectedColor: AppColors.brandPrimary.withOpacity(0.15),
                      labelStyle: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                        color: selectedVisibility == 'private'
                            ? AppColors.brandPrimary
                            : context.ew.textSecondary,
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
                        category: selectedCategory,
                        visibility: selectedVisibility,
                        name: nameController.text.trim().isEmpty
                            ? null
                            : nameController.text.trim(),
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

      await _apiService.uploadFileToPresignedUrl(
        uploadUrl: uploadUrl,
        fileBytes: fileBytes,
        contentType: contentType,
      );

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
    return AppScaffold(
      child: Column(
        children: [
          EWAppBar(
            title: 'Documents',
            trailing: [
              if (_isUploading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                EWIconButton(
                  icon: Icons.add_rounded,
                  onTap: _uploadDocument,
                  backgroundColor: AppColors.brandPrimary,
                  iconColor: Colors.white,
                ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const ShimmerList()
                : _documents.isEmpty
                    ? EmptyState(
                        icon: Icons.description_rounded,
                        title: 'No documents yet',
                        subtitle: 'Upload passports, tickets, and\nother travel documents',
                        iconColor: const Color(0xFF2196F3),
                        actionLabel: 'Upload Document',
                        onAction: _uploadDocument,
                      )
                    : _buildDocumentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    final grouped = <String, List<TripDocument>>{};
    for (final doc in _documents) {
      grouped.putIfAbsent(doc.category, () => []).add(doc);
    }

    final categories = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: AppSpacing.paddingHorizontalXl,
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
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                _categoryIcon(category),
                size: 18,
                color: _categoryColor(category),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _categoryLabel(category),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.ew.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _categoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${docs.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _categoryColor(category),
                    fontWeight: FontWeight.w600,
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
    final ew = context.ew;
    final theme = Theme.of(context);
    final color = _categoryColor(doc.category);

    return EWCard(
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderLg,
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: () => _openDocument(doc),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Icon(
                    doc.contentType == 'application/pdf'
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.displayName,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Text(
                            doc.formattedSize,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '\u00b7',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            DateFormat('MMM d, y').format(doc.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (doc.visibility == 'private') ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: context.ew.textSecondary,
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




