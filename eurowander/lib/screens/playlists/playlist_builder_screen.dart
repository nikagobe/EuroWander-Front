import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
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
        Navigator.pop(context);
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetadataForm(),
                          const SizedBox(height: 24),
                          _buildDayTabs(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isEditing ? 'Edit Playlist' : 'Create Playlist',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
          if (_isSaving)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
          else
            GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Save', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Title *'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City *',
            prefixIcon: Icon(Icons.location_city, size: 20),
          ),
          onChanged: _onCityChanged,
        ),
        if (_citySuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _citySuggestions.length,
              itemBuilder: (_, i) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primaryColor),
                  title: Text(_citySuggestions[i], style: const TextStyle(fontSize: 14)),
                  onTap: () => _selectCity(_citySuggestions[i]),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Text('Vibes', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlaylistVibe.values.map((v) {
            final isSelected = _selectedVibes.contains(v);
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                ),
                child: Text(
                  v.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BudgetTier>(
          value: _budgetTier,
          decoration: const InputDecoration(labelText: 'Budget'),
          items: BudgetTier.values.map((b) => DropdownMenuItem(
            value: b,
            child: Text(b.displayName, style: const TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: (b) { if (b != null) setState(() => _budgetTier = b); },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tagsController,
          decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Total Days:', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _updateTotalDays(_totalDays - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$_totalDays', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => _updateTotalDays(_totalDays + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
            const Spacer(),
            Row(
              children: [
                Text(_isPublic ? 'Public' : 'Private', style: const TextStyle(fontSize: 13)),
                Switch(
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayTabs() {
    return Column(
      children: [
        if (_totalDays > 1 && _tabController != null)
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: List.generate(_totalDays, (i) => Tab(text: 'Day ${i + 1}')),
          ),
        const SizedBox(height: 12),
        if (_tabController != null)
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_totalDays, (dayIndex) => _buildDayItemList(dayIndex + 1)),
            ),
          )
        else
          _buildDayItemList(1),
      ],
    );
  }

  Widget _buildDayItemList(int dayNumber) {
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
                  child: Text('No items for Day $dayNumber\nTap + to add',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary)),
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => _addItem(dayNumber),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Item'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableItemCard(PlaylistItem item, int globalIndex) {
    final isCustom = item.itemType == 'custom';
    return Card(
      key: ValueKey('${item.name}_${item.dayNumber}_${item.order}_$globalIndex'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isCustom ? Colors.amber.shade50 : null,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40, height: 40,
            child: item.photoUrl.isNotEmpty
                ? Image.network(item.photoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _itemIcon(item))
                : _itemIcon(item),
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            _buildTimeSlotDropdown(globalIndex),
            const SizedBox(width: 8),
            Text('${item.suggestedDurationMinutes}min', style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.note_alt_outlined, size: 18, color: item.note.isNotEmpty ? Colors.orange : Colors.grey),
              onPressed: () => _editItemNote(globalIndex),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _removeItem(globalIndex),
            ),
          ],
        ),
      ),
    );
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

