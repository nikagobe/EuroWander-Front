import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/city.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService();
  late final TextEditingController _bioController;
  late final TextEditingController _homeCityController;
  late final TextEditingController _baseAirportController;
  late List<String> _selectedLanguages;
  late List<String> _selectedTags;

  static const List<String> _availableTags = [
    'Budget',
    'Backpacker',
    'Foodie',
    'Adventure',
    'Luxury',
    'Cultural',
    'Solo',
    'Family',
  ];

  static const List<String> _availableLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Japanese',
    'Korean',
    'Mandarin',
    'Arabic',
    'Russian',
    'Dutch',
    'Turkish',
    'Georgian',
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.currentProfile.bio);
    _homeCityController =
        TextEditingController(text: widget.currentProfile.homeCity);
    _baseAirportController =
        TextEditingController(text: widget.currentProfile.baseAirport);
    _selectedLanguages =
        List.from(widget.currentProfile.preferredLanguages);
    _selectedTags = List.from(widget.currentProfile.travelStyleTags);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _homeCityController.dispose();
    _baseAirportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.lightTextPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, provider, _) {
              return TextButton(
                onPressed: provider.isSaving ? null : _handleSave,
                child: provider.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandPrimary,
                        ),
                      )
                    : Text(
                        'Save',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.brandPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile photo section
            _buildPhotoSection(),
            const SizedBox(height: AppSpacing.xxl),

            // Bio
            _buildSectionLabel('Bio'),
            const SizedBox(height: AppSpacing.xs),
            _buildBioField(),
            const SizedBox(height: AppSpacing.xl),

            // Home City
            _buildSectionLabel('Home City'),
            const SizedBox(height: AppSpacing.xs),
            _buildCityAutocomplete(),
            const SizedBox(height: AppSpacing.xl),

            // Base Airport
            _buildSectionLabel('Base Airport'),
            const SizedBox(height: AppSpacing.xs),
            _buildAirportAutocomplete(),
            const SizedBox(height: AppSpacing.xl),

            // Travel Style Tags
            _buildSectionLabel('Travel Style'),
            const SizedBox(height: AppSpacing.xs),
            _buildTagSelector(),
            const SizedBox(height: AppSpacing.xl),

            // Preferred Languages
            _buildSectionLabel('Languages'),
            const SizedBox(height: AppSpacing.xs),
            _buildLanguageSelector(),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          final coverUrl = provider.coverPhotoUrl;
          final profileUrl = provider.profilePhotoUrl;
          final isUploading = provider.isUploadingPhoto;

          return Column(
            children: [
              // Cover photo
              GestureDetector(
                onTap: isUploading ? null : _pickCoverPhoto,
                onLongPress: coverUrl != null ? () => _confirmDeletePhoto('cover') : null,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandPrimary.withOpacity(0.6),
                        AppColors.brandSecondary.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (coverUrl != null && coverUrl.isNotEmpty)
                          Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        Container(
                          color: Colors.black.withOpacity(0.2),
                          child: Center(
                            child: isUploading
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Change Cover',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Profile photo
              GestureDetector(
                onTap: isUploading ? null : _pickProfilePhoto,
                onLongPress: profileUrl != null ? () => _confirmDeletePhoto('profile') : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.lightSurfaceVariant,
                      backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                          ? NetworkImage(profileUrl)
                          : null,
                      child: profileUrl == null || profileUrl.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 36,
                              color: AppColors.lightTextTertiary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.lightTextSecondary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildBioField() {
    return TextField(
      controller: _bioController,
      maxLines: 4,
      maxLength: 300,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.lightTextPrimary,
          ),
      decoration: InputDecoration(
        hintText: 'Tell others about your travel style...',
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightTextTertiary,
            ),
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.lightBorder.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.lightBorder.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        counterStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.lightTextTertiary,
            ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.words,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.lightTextPrimary,
          ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightTextTertiary,
            ),
        prefixIcon: Icon(icon, color: AppColors.lightTextTertiary, size: 20),
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.lightBorder.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.lightBorder.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        counterText: '',
      ),
    );
  }

  InputDecoration _autocompleteDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.lightTextTertiary,
          ),
      prefixIcon: Icon(icon, color: AppColors.lightTextTertiary, size: 20),
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: AppColors.lightBorder.withOpacity(0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: AppColors.lightBorder.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(
          color: AppColors.brandPrimary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    );
  }

  Widget _buildCityAutocomplete() {
    return Autocomplete<City>(
      initialValue: TextEditingValue(text: _homeCityController.text),
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.length < 2) return const Iterable<City>.empty();
        try {
          return await _apiService.searchCities(query, limit: 6);
        } catch (_) {
          return const Iterable<City>.empty();
        }
      },
      displayStringForOption: (city) => '${city.name}, ${city.country}',
      onSelected: (city) {
        _homeCityController.text = '${city.name}, ${city.country}';
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextPrimary,
              ),
          decoration: _autocompleteDecoration(
            hint: 'Where do you call home?',
            icon: Icons.location_city_rounded,
          ),
          onChanged: (value) {
            _homeCityController.text = value;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: AppColors.lightSurface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 220,
                maxWidth: 420,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.lightBorder.withOpacity(0.3),
                ),
                itemBuilder: (context, index) {
                  final city = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.brandPrimary.withOpacity(0.7),
                    ),
                    title: Text(
                      city.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    subtitle: Text(
                      city.country,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightTextTertiary,
                          ),
                    ),
                    onTap: () => onSelected(city),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAirportAutocomplete() {
    return Autocomplete<Map<String, String>>(
      initialValue: TextEditingValue(text: _baseAirportController.text),
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<Map<String, String>>.empty();
        try {
          return await _apiService.searchAirports(query, limit: 6);
        } catch (_) {
          return const Iterable<Map<String, String>>.empty();
        }
      },
      displayStringForOption: (airport) {
        final iata = airport['iata'] ?? '';
        final name = airport['name'] ?? '';
        if (iata.isNotEmpty && name.isNotEmpty) return '$iata - $name';
        return iata.isNotEmpty ? iata : name;
      },
      onSelected: (airport) {
        final iata = airport['iata'] ?? '';
        _baseAirportController.text = iata;
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.characters,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextPrimary,
              ),
          decoration: _autocompleteDecoration(
            hint: 'Search airport (e.g. TBS, JFK)',
            icon: Icons.flight_rounded,
          ),
          onChanged: (value) {
            _baseAirportController.text = value;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: AppColors.lightSurface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 220,
                maxWidth: 420,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.lightBorder.withOpacity(0.3),
                ),
                itemBuilder: (context, index) {
                  final airport = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.flight_rounded,
                      size: 18,
                      color: AppColors.brandPrimary.withOpacity(0.7),
                    ),
                    title: Text(
                      '${airport['iata']} - ${airport['name']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    subtitle: Text(
                      airport['city'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightTextTertiary,
                          ),
                    ),
                    onTap: () => onSelected(airport),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagSelector() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _availableTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTags.remove(tag);
              } else {
                _selectedTags.add(tag);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.brandPrimary
                  : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isSelected
                    ? AppColors.brandPrimary
                    : AppColors.lightBorder,
              ),
            ),
            child: Text(
              tag,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppColors.lightTextSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageSelector() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _availableLanguages.map((lang) {
        final isSelected = _selectedLanguages.contains(lang);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedLanguages.remove(lang);
              } else {
                _selectedLanguages.add(lang);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.brandSecondary
                  : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isSelected
                    ? AppColors.brandSecondary
                    : AppColors.lightBorder,
              ),
            ),
            child: Text(
              lang,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppColors.lightTextSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleSave() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final fields = <String, dynamic>{};

    if (_bioController.text != widget.currentProfile.bio) {
      fields['bio'] = _bioController.text;
    }
    if (_homeCityController.text != widget.currentProfile.homeCity) {
      fields['home_city'] = _homeCityController.text;
    }
    if (_baseAirportController.text != widget.currentProfile.baseAirport) {
      fields['base_airport'] = _baseAirportController.text;
    }
    if (!_listEquals(_selectedTags, widget.currentProfile.travelStyleTags)) {
      fields['travel_style_tags'] = _selectedTags;
    }
    if (!_listEquals(
        _selectedLanguages, widget.currentProfile.preferredLanguages)) {
      fields['preferred_languages'] = _selectedLanguages;
    }

    if (fields.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final success = await context.read<ProfileProvider>().updateProfile(
          token: token,
          fields: fields,
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save profile'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = List<String>.from(a)..sort();
    final sortedB = List<String>.from(b)..sort();
    for (var i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  void _pickProfilePhoto() {
    _pickAndUploadPhoto('profile');
  }

  void _pickCoverPhoto() {
    _pickAndUploadPhoto('cover');
  }

  Future<void> _pickAndUploadPhoto(String photoType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    // Validate size (5 MB max)
    if (file.size > 5242880) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image must be under 5 MB'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
      return;
    }

    final contentType = _mimeType(file.extension ?? '');
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final success = await context.read<ProfileProvider>().uploadPhoto(
          token: token,
          photoType: photoType,
          fileName: file.name,
          bytes: file.bytes!,
          contentType: contentType,
        );

    if (mounted && !success) {
      final error = context.read<ProfileProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Upload failed'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeletePhoto(String photoType) async {
    final label = photoType == 'profile' ? 'profile photo' : 'cover photo';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('Remove $label?'),
        content: Text('This will permanently delete your $label.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final success = await context.read<ProfileProvider>().deletePhoto(
          token: token,
          photoType: photoType,
        );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to remove photo'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
    }
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
