import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';

class PlaylistBuilderScreen extends StatefulWidget {
  final String? editPlaylistId;

  const PlaylistBuilderScreen({super.key, this.editPlaylistId});

  @override
  State<PlaylistBuilderScreen> createState() => _PlaylistBuilderScreenState();
}

class _PlaylistBuilderScreenState extends State<PlaylistBuilderScreen> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _coverPhotoController = TextEditingController();
  final _tagsController = TextEditingController();

  PlaylistVibe _vibe = PlaylistVibe.chill;
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
    _countryController.dispose();
    _coverPhotoController.dispose();
    _tagsController.dispose();
    _tabController?.dispose();
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
          _countryController.text = playlist.country;
          _coverPhotoController.text = playlist.coverPhotoUrl;
          _vibe = PlaylistVibe.fromString(playlist.vibe);
          _budgetTier = BudgetTier.fromString(playlist.budgetTier);
          _totalDays = playlist.totalDays;
          _isPublic = playlist.isPublic;
          _items = List.from(playlist.items);
          _tagsController.text = playlist.tags.join(', ');
          _tabController?.dispose();
          _tabController = TabController(length: _totalDays, vsync: this);
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      'country': _countryController.text,
      'cover_photo_url': _coverPhotoController.text,
      'vibe': _vibe.apiValue,
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

  void _addItem(int dayNumber) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _AddItemSheet(
        dayNumber: dayNumber,
        onAdd: (item) {
          setState(() => _items.add(item));
          Navigator.pop(context);
        },
      ),
    );
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
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Playlist' : 'Create Playlist'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetadataForm(),
            const SizedBox(height: 24),
            _buildDayTabs(),
          ],
        ),
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City *'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _coverPhotoController,
          decoration: const InputDecoration(labelText: 'Cover Photo URL'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<PlaylistVibe>(
                value: _vibe,
                decoration: const InputDecoration(labelText: 'Vibe'),
                items: PlaylistVibe.values.map((v) => DropdownMenuItem(
                  value: v,
                  child: Text('${v.icon} ${v.displayName}', style: const TextStyle(fontSize: 14)),
                )).toList(),
                onChanged: (v) { if (v != null) setState(() => _vibe = v); },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<BudgetTier>(
                value: _budgetTier,
                decoration: const InputDecoration(labelText: 'Budget'),
                items: BudgetTier.values.map((b) => DropdownMenuItem(
                  value: b,
                  child: Text('${b.icon} ${b.displayName}', style: const TextStyle(fontSize: 14)),
                )).toList(),
                onChanged: (b) { if (b != null) setState(() => _budgetTier = b); },
              ),
            ),
          ],
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
                      // Update order
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
        leading: Icon(
          item.itemType == 'attraction' ? Icons.attractions_rounded
              : item.itemType == 'restaurant' ? Icons.restaurant_rounded
              : Icons.push_pin_rounded,
          color: item.itemType == 'attraction' ? Colors.deepOrange
              : item.itemType == 'restaurant' ? Colors.green
              : Colors.amber.shade700,
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

  Widget _buildTimeSlotDropdown(int index) {
    return DropdownButton<String>(
      value: _items[index].timeSlot,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 'morning', child: Text('🌅', style: TextStyle(fontSize: 14))),
        DropdownMenuItem(value: 'midday', child: Text('☀️', style: TextStyle(fontSize: 14))),
        DropdownMenuItem(value: 'evening', child: Text('🌆', style: TextStyle(fontSize: 14))),
        DropdownMenuItem(value: 'night', child: Text('🌙', style: TextStyle(fontSize: 14))),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _items[index] = _items[index].copyWith(timeSlot: v));
      },
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final int dayNumber;
  final void Function(PlaylistItem item) onAdd;

  const _AddItemSheet({required this.dayNumber, required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String _type = 'custom';
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  String _timeSlot = 'morning';
  int _duration = 60;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Item — Day ${widget.dayNumber}',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Type selector
            Row(
              children: [
                _buildTypeChip('Custom', 'custom', Icons.push_pin_rounded),
                const SizedBox(width: 8),
                _buildTypeChip('Attraction', 'attraction', Icons.attractions_rounded),
                const SizedBox(width: 8),
                _buildTypeChip('Restaurant', 'restaurant', Icons.restaurant_rounded),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (tips/warnings)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Time: '),
                DropdownButton<String>(
                  value: _timeSlot,
                  items: const [
                    DropdownMenuItem(value: 'morning', child: Text('🌅 Morning')),
                    DropdownMenuItem(value: 'midday', child: Text('☀️ Midday')),
                    DropdownMenuItem(value: 'evening', child: Text('🌆 Evening')),
                    DropdownMenuItem(value: 'night', child: Text('🌙 Night')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _timeSlot = v); },
                ),
                const Spacer(),
                const Text('Duration: '),
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () { if (_duration > 15) setState(() => _duration -= 15); },
                ),
                Text('${_duration}min'),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => setState(() => _duration += 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isEmpty) return;
                  widget.onAdd(PlaylistItem(
                    itemType: _type,
                    name: _nameController.text,
                    dayNumber: widget.dayNumber,
                    timeSlot: _timeSlot,
                    order: 0,
                    category: _categoryController.text,
                    note: _noteController.text,
                    suggestedDurationMinutes: _duration,
                  ));
                },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, IconData icon) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
