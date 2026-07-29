import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/widgets.dart';
import 'playlist_item_picker_screen.dart';

class PlaylistBuilderScreen extends StatefulWidget {
  final String? editPlaylistId;

  const PlaylistBuilderScreen({super.key, this.editPlaylistId});

  @override
  State<PlaylistBuilderScreen> createState() => _PlaylistBuilderScreenState();
}

class _PlaylistBuilderScreenState extends State<PlaylistBuilderScreen> with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedCountry = '';
  List<String> _citySuggestions = [];
  Timer? _cityDebounce;

  Set<PlaylistVibe> _selectedVibes = {PlaylistVibe.chill};
  BudgetTier _budgetTier = BudgetTier.budget;
  int _totalDays = 1;
  bool _isPublic = true;
  List<PlaylistItem> _items = [];
  bool _isLoading = false;
  bool _isSaving = false;
  TabController? _tabController;

  bool get isEditing => widget.editPlaylistId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _totalDays, vsync: this);
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylist());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _tagsController.dispose();
    _tabController?.dispose();
    _cityDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final provider = context.read<PlaylistProvider>();
      await provider.loadPlaylist(token: token, id: widget.editPlaylistId!);
      final playlist = provider.currentPlaylist;
      if (playlist != null && mounted) {
        setState(() {
          _titleController.text = playlist.title;
          _descriptionController.text = playlist.description;
          _cityController.text = playlist.city;
          _selectedCountry = playlist.country;
          _selectedVibes = playlist.vibes.map((v) => PlaylistVibe.fromString(v)).toSet();
          if (_selectedVibes.isEmpty) _selectedVibes = {PlaylistVibe.chill};
          _budgetTier = BudgetTier.fromString(playlist.budgetTier);
          _totalDays = playlist.totalDays;
          _isPublic = playlist.isPublic;
          _items = List.from(playlist.items);
          _tagsController.text = playlist.tags.join(', ');
          _tabController?.dispose();
          _tabController = TabController(length: _totalDays, vsync: this);
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _coverPhotoUrl {
    final firstWithPhoto = _items.where((i) => i.photoUrl.isNotEmpty).toList();
    return firstWithPhoto.isNotEmpty ? firstWithPhoto.first.photoUrl : '';
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and City are required')),
      );
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isSaving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final data = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'city': _cityController.text,
      'country': _selectedCountry,
      'cover_photo_url': _coverPhotoUrl,
      'vibe': _selectedVibes.map((v) => v.apiValue).join(','),
      'budget_tier': _budgetTier.apiValue,
      'total_days': _totalDays,
      'is_public': _isPublic,
      'tags': tags,
      'items': _items.map((i) => i.toJson()).toList(),
    };

    try {
      final provider = context.read<PlaylistProvider>();
      if (isEditing) {
        await provider.updatePlaylist(token: token, id: widget.editPlaylistId!, data: data);
      } else {
        await provider.createPlaylist(token: token, data: data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Playlist updated!' : 'Playlist created!')),
        );
        // Pop with the playlist title so callers can use it
        Navigator.pop(context, _titleController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _updateTotalDays(int days) {
    if (days < 1) days = 1;
    if (days > 14) days = 14;
    setState(() {
      _totalDays = days;
      _tabController?.dispose();
      _tabController = TabController(length: days, vsync: this);
    });
  }

  void _onCityChanged(String query) {
    _cityDebounce?.cancel();
    if (query.length < 2) {
      setState(() => _citySuggestions = []);
      return;
    }
    _cityDebounce = Timer(const Duration(milliseconds: 400), () async {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final results = await context.read<PlaylistProvider>().searchCities(token: token, query: query);
      if (mounted) setState(() => _citySuggestions = results);
    });
  }

  void _selectCity(String city) {
    setState(() {
      _cityController.text = city;
      _citySuggestions = [];
    });
  }

  Future<void> _addItem(int dayNumber) async {
    final results = await Navigator.push<List<PlaylistItem>>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistItemPickerScreen(
          dayNumber: dayNumber,
          totalDays: _totalDays,
          initialCity: _cityController.text,
        ),
      ),
    );
    if (results != null && results.isNotEmpty && mounted) {
      setState(() => _items.addAll(results));
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _editItemNote(int index) {
    final controller = TextEditingController(text: _items[index].note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Tips, warnings, or notes...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _items[index] = _items[index].copyWith(note: controller.text);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    if (_isLoading) {
      return AppScaffold(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.brandPrimary),
              const SizedBox(height: 16),
              Text('Loading playlist...', style: TextStyle(color: ew.textSecondary)),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _buildMetadataForm(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildDayTabs(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return EWAppBar(
      title: isEditing ? 'Edit Playlist' : 'Create Playlist',
      trailing: [
        if (_isSaving)
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary))
        else
          GestureDetector(
            onTap: _save,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Text('Save', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
            ),
          ),
      ],
    );
  }

  Widget _buildMetadataForm() {
    final ew = context.ew;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Section: Basic Info ─────────────────────────────────
        _buildSectionCard(
          icon: Icons.edit_rounded,
          title: 'Basic Info',
          color: AppColors.brandPrimary,
          child: Column(
            children: [
              _buildStyledField(
                controller: _titleController,
                label: 'Playlist Title',
                hint: 'e.g. "Best of Barcelona"',
                icon: Icons.title_rounded,
                required: true,
              ),
              const SizedBox(height: 14),
              _buildStyledField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'What makes this playlist special?',
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ─── Section: Location ──────────────────────────────────
        _buildSectionCard(
          icon: Icons.location_on_rounded,
          title: 'Location',
          color: AppColors.info,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStyledField(
                controller: _cityController,
                label: 'City',
                hint: 'Start typing a city...',
                icon: Icons.location_city_rounded,
                required: true,
                onChanged: _onCityChanged,
              ),
              if (_citySuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: ew.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ew.border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _citySuggestions.length,
                    itemBuilder: (_, i) => InkWell(
                      onTap: () => _selectCity(_citySuggestions[i]),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: AppColors.brandPrimary.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            Text(_citySuggestions[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ew.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ─── Section: Vibe & Budget ─────────────────────────────
        _buildSectionCard(
          icon: Icons.palette_rounded,
          title: 'Vibe & Budget',
          color: const Color(0xFFE91E63),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select vibes (multi-select)', style: TextStyle(fontSize: 12, color: ew.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PlaylistVibe.values.map((v) {
                  final isSelected = _selectedVibes.contains(v);
                  final vibeCol = _vibeColor(v.apiValue);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          if (_selectedVibes.length > 1) _selectedVibes.remove(v);
                        } else {
                          _selectedVibes.add(v);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? vibeCol : ew.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? vibeCol : ew.border, width: isSelected ? 1.5 : 1),
                        boxShadow: isSelected
                            ? [BoxShadow(color: vibeCol.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Text(
                        v.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : ew.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Budget tier', style: TextStyle(fontSize: 12, color: ew.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: BudgetTier.values.map((b) {
                  final isSelected = _budgetTier == b;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _budgetTier = b),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.success : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? AppColors.success : ew.border),
                        ),
                        child: Text(
                          b.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : ew.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ─── Section: Settings ──────────────────────────────────
        _buildSectionCard(
          icon: Icons.settings_rounded,
          title: 'Settings',
          color: AppColors.brandAmber,
          child: Column(
            children: [
              // Tags
              _buildStyledField(
                controller: _tagsController,
                label: 'Tags',
                hint: 'food, nightlife, culture...',
                icon: Icons.tag_rounded,
              ),
              const SizedBox(height: 14),
              // Days + Public toggle
              Row(
                children: [
                  // Days counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ew.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ew.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: ew.textSecondary),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _updateTotalDays(_totalDays - 1),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: _totalDays > 1 ? AppColors.brandPrimary.withOpacity(0.1) : ew.borderSubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.remove_rounded, size: 16, color: _totalDays > 1 ? AppColors.brandPrimary : ew.textTertiary),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('$_totalDays ${_totalDays == 1 ? 'day' : 'days'}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ew.textPrimary)),
                        ),
                        GestureDetector(
                          onTap: () => _updateTotalDays(_totalDays + 1),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded, size: 16, color: AppColors.brandPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Public toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isPublic ? AppColors.success.withOpacity(0.08) : ew.inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _isPublic ? AppColors.success.withOpacity(0.3) : ew.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPublic ? Icons.public_rounded : Icons.lock_rounded,
                          size: 16,
                          color: _isPublic ? AppColors.success : ew.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPublic ? 'Public' : 'Private',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _isPublic ? AppColors.success : ew.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 36, height: 20,
                          child: Switch(
                            value: _isPublic,
                            onChanged: (v) => setState(() => _isPublic = v),
                            activeColor: AppColors.success,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    final ew = context.ew;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ew.borderSubtle),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ew.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    final ew = context.ew;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: ew.textPrimary),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(fontSize: 13, color: ew.textSecondary),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: ew.textTertiary),
        prefixIcon: Icon(icon, size: 18, color: ew.textSecondary),
        filled: true,
        fillColor: ew.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ew.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ew.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
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
      case 'chill': return const Color(0xFF00BCD4);
      default: return AppColors.brandPrimary;
    }
  }

  Widget _buildDayTabs() {
    final ew = context.ew;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.view_timeline_rounded, size: 16, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: 8),
            Text('Itinerary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ew.textPrimary)),
            const Spacer(),
            Text('${_items.length} items', style: TextStyle(fontSize: 12, color: ew.textTertiary)),
          ],
        ),
        const SizedBox(height: 12),
        if (_totalDays > 1 && _tabController != null)
          Container(
            decoration: BoxDecoration(
              color: ew.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ew.borderSubtle),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.brandPrimary,
              unselectedLabelColor: ew.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              dividerHeight: 0,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.all(3),
              tabs: List.generate(_totalDays, (i) => Tab(text: 'Day ${i + 1}')),
            ),
          ),
        const SizedBox(height: 12),
        if (_tabController != null)
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_totalDays, (dayIndex) => _buildDayItemList(dayIndex + 1)),
            ),
          )
        else
          SizedBox(
            height: 420,
            child: _buildDayItemList(1),
          ),
      ],
    );
  }

  Widget _buildDayItemList(int dayNumber) {
    final ew = context.ew;
    final dayItems = _items.where((i) => i.dayNumber == dayNumber).toList();
    dayItems.sort((a, b) {
      final slotOrder = ['morning', 'midday', 'evening', 'night'];
      final cmp = slotOrder.indexOf(a.timeSlot).compareTo(slotOrder.indexOf(b.timeSlot));
      return cmp != 0 ? cmp : a.order.compareTo(b.order);
    });

    return Column(
      children: [
        Expanded(
          child: dayItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.playlist_add_rounded, size: 40, color: ew.textTertiary),
                      const SizedBox(height: 10),
                      Text('No items for Day $dayNumber', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ew.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Add attractions and restaurants', style: TextStyle(fontSize: 12, color: ew.textTertiary)),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: dayItems.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    setState(() {
                      final globalOld = _items.indexOf(dayItems[oldIndex]);
                      final globalNew = _items.indexOf(dayItems[newIndex]);
                      final item = _items.removeAt(globalOld);
                      _items.insert(globalNew, item);
                      for (int i = 0; i < _items.length; i++) {
                        if (_items[i].dayNumber == dayNumber) {
                          _items[i] = _items[i].copyWith(order: i);
                        }
                      }
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = dayItems[index];
                    final globalIndex = _items.indexOf(item);
                    return _buildEditableItemCard(item, globalIndex);
                  },
                ),
        ),
        // Add item button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => _addItem(dayNumber),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.brandPrimary.withOpacity(0.2), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, size: 20, color: AppColors.brandPrimary),
                  const SizedBox(width: 8),
                  Text('Add Places', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.brandPrimary)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableItemCard(PlaylistItem item, int globalIndex) {
    final ew = context.ew;
    final isCustom = item.itemType == 'custom';
    final itemColor = _itemTypeColor(item.itemType);

    return Container(
      key: ValueKey('${item.name}_${item.dayNumber}_${item.order}_$globalIndex'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCustom ? Colors.amber.shade200 : ew.borderSubtle),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          // Drag handle
          Icon(Icons.drag_indicator_rounded, size: 18, color: ew.textTertiary),
          const SizedBox(width: 8),
          // Photo
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: itemColor.withOpacity(0.3), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                width: 40, height: 40,
                child: item.photoUrl.isNotEmpty
                    ? Image.network(item.photoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _itemIcon(item))
                    : _itemIcon(item),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ew.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildTimeSlotDropdown(globalIndex),
                    const SizedBox(width: 8),
                    Text('${item.suggestedDurationMinutes}min', style: TextStyle(fontSize: 11, color: ew.textTertiary)),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.sticky_note_2_rounded, size: 12, color: Colors.orange.shade400),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Actions
          GestureDetector(
            onTap: () => _editItemNote(globalIndex),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.note_alt_outlined, size: 16, color: item.note.isNotEmpty ? Colors.orange : ew.textTertiary),
            ),
          ),
          GestureDetector(
            onTap: () => _removeItem(globalIndex),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 16, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Color _itemTypeColor(String itemType) {
    switch (itemType) {
      case 'attraction': return Colors.deepOrange;
      case 'restaurant': return const Color(0xFF4CAF50);
      default: return Colors.amber.shade700;
    }
  }

  Widget _itemIcon(PlaylistItem item) {
    IconData icon;
    Color color;
    switch (item.itemType) {
      case 'attraction':
        icon = Icons.attractions_rounded;
        color = Colors.deepOrange;
        break;
      case 'restaurant':
        icon = Icons.restaurant_rounded;
        color = Colors.green;
        break;
      default:
        icon = Icons.push_pin_rounded;
        color = Colors.amber.shade700;
    }
    return Container(color: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20));
  }

  Widget _buildTimeSlotDropdown(int index) {
    return DropdownButton<String>(
      value: _items[index].timeSlot,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 'morning', child: Text('Morning', style: TextStyle(fontSize: 12))),
        DropdownMenuItem(value: 'midday', child: Text('Midday', style: TextStyle(fontSize: 12))),
        DropdownMenuItem(value: 'evening', child: Text('Evening', style: TextStyle(fontSize: 12))),
        DropdownMenuItem(value: 'night', child: Text('Night', style: TextStyle(fontSize: 12))),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _items[index] = _items[index].copyWith(timeSlot: v));
      },
    );
  }
}

