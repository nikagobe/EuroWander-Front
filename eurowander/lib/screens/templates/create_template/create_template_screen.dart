import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/city.dart';
import '../../../models/template.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/template_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/template_service.dart';
import '../../../services/playlist_service.dart';
import '../../../widgets/widgets.dart';
import '../../playlists/playlist_builder_screen.dart';
import '../../playlists/playlist_detail_screen.dart';
import 'template_hotel_picker_screen.dart';
import 'template_playlist_picker_screen.dart';

class CreateTemplateScreen extends StatefulWidget {
  final String? editTemplateId;
  const CreateTemplateScreen({super.key, this.editTemplateId});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final ApiService _apiService = ApiService();
  final _templateService = TemplateService();

  // Basic info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _coverPhotoUrl = '';
  Uint8List? _coverPhotoBytes;
  String? _coverPhotoFileName;
  String? _coverPhotoContentType;
  bool _isUploadingCover = false;
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  List<String> _tags = [];
  String _currency = 'EUR';

  // Legs
  List<_LegDraft> _legs = [];

  bool get _isEditing => widget.editTemplateId != null;
  bool _isSaving = false;

  static const _availableTags = [
    'budget', 'luxury', 'backpacking', 'romantic', 'family',
    '7-day', '14-day', 'weekend', 'adventure', 'cultural', 'beach', 'city-break',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final provider = context.read<TemplateProvider>();
    await provider.loadTemplateDetail(widget.editTemplateId!);
    final t = provider.currentTemplate;
    if (t != null && mounted) {
      setState(() {
        _titleController.text = t.title;
        _descriptionController.text = t.description;
        _coverPhotoUrl = t.coverPhotoUrl;
        _budgetMinController.text = t.estimatedBudgetMin?.toInt().toString() ?? '';
        _budgetMaxController.text = t.estimatedBudgetMax?.toInt().toString() ?? '';
        _tags = List.from(t.tags);
        _currency = t.currency;
        _legs = t.legs.map((l) => _LegDraft(
          city: l.city, country: l.country, days: l.days,
          hotelPicks: l.hotelRecommendations?.primaryPicks ?? [],
          playlistId: l.playlistId.isNotEmpty ? l.playlistId : null,
          playlistName: l.playlistId.isNotEmpty ? 'Attached playlist' : '',
          authorNotes: l.authorNotes,
        )).toList();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    for (final leg in _legs) {
      leg.cityController.dispose();
      leg.notesController.dispose();
    }
    super.dispose();
  }

  void _addLeg() {
    setState(() => _legs.add(_LegDraft()));
  }

  void _removeLeg(int index) {
    setState(() {
      _legs[index].cityController.dispose();
      _legs[index].notesController.dispose();
      _legs.removeAt(index);
    });
  }

  List<CreateTemplateLeg> _buildLegs() {
    return _legs.asMap().entries.map((e) {
      final i = e.key;
      final leg = e.value;
      return CreateTemplateLeg(
        order: i + 1, city: leg.city, country: leg.country, days: leg.days,
        hotelRecommendations: leg.hotelPicks.isNotEmpty ? HotelRecommendations(
          city: leg.city, country: leg.country, primaryPicks: leg.hotelPicks,
          fallbackNeighborhood: '', fallbackStarMin: 1, fallbackStarMax: 5,
        ) : null,
        playlistId: leg.playlistId,
        restaurantIds: [], authorNotes: leg.notesController.text,
      );
    }).toList();
  }

  Future<void> _save({bool publish = false}) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_legs.isEmpty || _legs.first.city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one city')));
      return;
    }

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final provider = context.read<TemplateProvider>();
    final legs = _buildLegs();

    try {
      // Upload cover photo if a new file was picked
      if (_coverPhotoBytes != null && _coverPhotoFileName != null) {
        final token = context.read<AuthProvider>().token ?? '';
        final url = await _uploadCoverPhoto(token);
        if (url != null) _coverPhotoUrl = url;
      }

      TemplateResponse? result;
      if (_isEditing) {
        result = await provider.updateTemplate(templateId: widget.editTemplateId!, userId: userId, request: UpdateTemplateRequest(
          title: _titleController.text, description: _descriptionController.text, coverPhotoUrl: _coverPhotoUrl,
          tags: _tags, legs: legs, estimatedBudgetMin: double.tryParse(_budgetMinController.text),
          estimatedBudgetMax: double.tryParse(_budgetMaxController.text), currency: _currency,
        ));
      } else {
        result = await provider.createTemplate(CreateTemplateRequest(
          authorId: userId, title: _titleController.text, description: _descriptionController.text,
          coverPhotoUrl: _coverPhotoUrl, tags: _tags, legs: legs,
          estimatedBudgetMin: double.tryParse(_budgetMinController.text),
          estimatedBudgetMax: double.tryParse(_budgetMaxController.text), currency: _currency,
        ));
      }
      if (publish && result != null) {
        await provider.publishTemplate(templateId: result.id, userId: userId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(publish ? 'Template published!' : 'Template saved as draft')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isSaving = false);
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.label_rounded, size: 20, color: AppColors.brandPrimary),
                      const SizedBox(width: 8),
                      Text('Select Tags', style: Theme.of(ctx).textTheme.headlineSmall),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _availableTags.map((tag) {
                      final isSelected = _tags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            isSelected ? _tags.remove(tag) : _tags.add(tag);
                          });
                          setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.brandPrimary.withOpacity(0.15) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.brandPrimary : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_circle, size: 16, color: AppColors.brandPrimary),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? AppColors.brandPrimary : AppColors.lightTextPrimary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _viewPlaylist(String playlistId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: playlistId)),
    );
  }

  Future<void> _openHotelPicker(int legIndex) async {
    final leg = _legs[legIndex];
    if (leg.city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a city first')));
      return;
    }
    final result = await Navigator.push<List<HotelPick>>(
      context,
      MaterialPageRoute(builder: (_) => TemplateHotelPickerScreen(city: leg.city, days: leg.days, existingPicks: leg.hotelPicks)),
    );
    if (result != null && mounted) {
      setState(() {
        // Preserve existing tips when picks come back
        final oldTips = <int, String>{};
        for (final p in leg.hotelPicks) {
          if (p.authorReview.isNotEmpty) oldTips[p.bookingHotelId] = p.authorReview;
        }
        _legs[legIndex].hotelPicks = result.map((p) => HotelPick(
          bookingHotelId: p.bookingHotelId, name: p.name, city: p.city,
          neighborhood: p.neighborhood, stars: p.stars, photoUrl: p.photoUrl,
          authorReview: oldTips[p.bookingHotelId] ?? p.authorReview,
          priority: p.priority, pricePaid: p.pricePaid, currency: p.currency,
        )).toList();
      });
    }
  }

  Future<void> _openPlaylistPicker(int legIndex) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => TemplatePlaylistPickerScreen(city: _legs[legIndex].city)),
    );
    if (result != null && mounted) {
      setState(() {
        _legs[legIndex].playlistId = result['id'];
        _legs[legIndex].playlistName = result['name'] ?? 'Playlist';
      });
    }
  }

  Future<void> _createPlaylistForLeg(int legIndex) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PlaylistBuilderScreen()),
    );
    if (result != null && mounted) {
      // result is the playlist title; reload my playlists to get the ID
      final token = context.read<AuthProvider>().token ?? '';
      final service = PlaylistService();
      final myPlaylists = await service.getMyPlaylists(token: token);
      if (myPlaylists.isNotEmpty && mounted) {
        final newest = myPlaylists.first;
        setState(() {
          _legs[legIndex].playlistId = newest.id;
          _legs[legIndex].playlistName = newest.title;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(children: [
        EWAppBar(title: _isEditing ? 'Edit Template' : 'Create Template'),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // ─── GENERAL INFO ────────────────────────────
                      _sectionTitle('GENERAL INFO'),
                      const SizedBox(height: 12),

                      _label('Title *'),
                      TextField(controller: _titleController, decoration: _inputDeco('e.g. 7 Days in Spain')),
                      const SizedBox(height: 14),

                      _label('Description'),
                      TextField(controller: _descriptionController, maxLines: 3, decoration: _inputDeco('Describe your trip template...')),
                      const SizedBox(height: 14),

                      _label('Cover Photo'),
                      _buildCoverPhotoPicker(),
                      const SizedBox(height: 14),

                      // Tags
                      _label('Tags'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _showTagPicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: _tags.isEmpty
                              ? Text('Select tags...', style: TextStyle(fontSize: 14, color: Colors.grey.shade500))
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _tags.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(tag, style: const TextStyle(fontSize: 12, color: AppColors.brandPrimary, fontWeight: FontWeight.w500)),
                                  )).toList(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Budget
                      _label('Estimated Budget'),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.3))),
                          child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _currency, items: ['EUR', 'USD', 'GBP', 'GEL'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(), onChanged: (v) { if (v != null) setState(() => _currency = v); })),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _budgetMinController, keyboardType: TextInputType.number, decoration: _inputDeco('Min'))),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('–')),
                        Expanded(child: TextField(controller: _budgetMaxController, keyboardType: TextInputType.number, decoration: _inputDeco('Max'))),
                      ]),

                      const SizedBox(height: 28),

                      // ─── CITIES ─────────────────────────────────
                      _sectionTitle('CITIES'),
                      const SizedBox(height: 12),

                      ..._legs.asMap().entries.map((e) => _buildLegCard(e.key)),

                      // Add city button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addLeg,
                          icon: const Icon(Icons.add, size: 18), label: const Text('Add city'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.brandPrimary, side: BorderSide(color: AppColors.brandPrimary.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ─── SAVE BUTTONS ───────────────────────────
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : () => _save(publish: false),
                          icon: const Icon(Icons.save_outlined, size: 18), label: const Text('Save as Draft'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.brandPrimary, side: const BorderSide(color: AppColors.brandPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _save(publish: true),
                          icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.rocket_launch, size: 18),
                          label: Text(_isSaving ? 'Saving...' : 'Publish'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ]),
    );
  }

  Widget _buildLegCard(int index) {
    final leg = _legs[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
          Row(children: [
            const Icon(Icons.location_on, size: 18, color: AppColors.brandPrimary),
            const SizedBox(width: 4),
            Text('City ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const Spacer(),
          if (_legs.length > 1) GestureDetector(onTap: () => _removeLeg(index), child: Icon(Icons.delete_outline, size: 20, color: Colors.red.withOpacity(0.7))),
        ]),
        const SizedBox(height: 10),

        // City search
        _CitySearchField(
          controller: leg.cityController,
          apiService: _apiService,
          onCitySelected: (city) {
            setState(() { leg.city = city.name; leg.country = city.country; });
          },
        ),
        if (leg.country.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(leg.country, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary))),
        const SizedBox(height: 10),

        // Days
        Row(children: [
          const Text('Days: ', style: TextStyle(fontSize: 14)),
          SizedBox(width: 60, child: TextField(
            keyboardType: TextInputType.number, textAlign: TextAlign.center,
            decoration: _inputDeco(''), controller: TextEditingController(text: leg.days.toString()),
            onChanged: (v) { final d = int.tryParse(v); if (d != null && d > 0) setState(() => leg.days = d); },
          )),
        ]),
        const SizedBox(height: 12),

        // Hotels - collapsible section
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 6),
            initiallyExpanded: leg.hotelPicks.isEmpty,
            title: Row(children: [
              const Icon(Icons.hotel, size: 16, color: Color(0xFFFF9800)),
              const SizedBox(width: 4),
              const Text('Hotels', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (leg.hotelPicks.isNotEmpty) Text('${leg.hotelPicks.length} recommended', style: const TextStyle(fontSize: 12, color: Color(0xFFFF9800), fontWeight: FontWeight.w500)),
            ]),
            children: [
              // Show picks with collapsible tip
              if (leg.hotelPicks.isNotEmpty) ...[
                ...leg.hotelPicks.asMap().entries.map((entry) {
                  final pickIdx = entry.key;
                  final pick = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3))),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        dense: true,
                        iconColor: AppColors.lightTextSecondary,
                        collapsedIconColor: AppColors.lightTextSecondary,
                        title: Row(children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFF9800)),
                          const SizedBox(width: 2),
                          Expanded(child: Row(children: [
                            Flexible(child: Text(pick.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            const SizedBox(width: 4),
                            ...List.generate(pick.stars, (_) => const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFF9800))),
                          ])),
                          if (pick.pricePaid != null) Text('${pick.currency}${pick.pricePaid!.toInt()}/n', style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
                        ]),
                        subtitle: pick.authorReview.isNotEmpty
                            ? Row(children: [
                                const Icon(Icons.lightbulb_outline, size: 12, color: AppColors.lightTextSecondary),
                                const SizedBox(width: 4),
                                Expanded(child: Text(pick.authorReview, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ])
                            : const Text('Tap to add tip', style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
                        children: [
                          TextField(
                            decoration: _inputDeco('Add tip for this hotel...').copyWith(fillColor: Colors.white, prefixIcon: const Icon(Icons.lightbulb_outline, size: 16)),
                            style: const TextStyle(fontSize: 12),
                            controller: TextEditingController(text: pick.authorReview),
                            onChanged: (v) {
                              _legs[index].hotelPicks[pickIdx] = HotelPick(
                                bookingHotelId: pick.bookingHotelId, name: pick.name, city: pick.city,
                                neighborhood: pick.neighborhood, stars: pick.stars, photoUrl: pick.photoUrl,
                                authorReview: v, priority: pick.priority, pricePaid: pick.pricePaid, currency: pick.currency,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              // Search hotels button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openHotelPicker(index),
                  icon: const Icon(Icons.search, size: 16), label: Text(leg.hotelPicks.isEmpty ? 'Search & recommend hotels' : 'Change hotel picks'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.brandPrimary, side: BorderSide(color: AppColors.brandPrimary.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Playlist
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 6, bottom: 4),
            initiallyExpanded: leg.playlistId == null,
            title: Row(children: [
              const Icon(Icons.queue_music_rounded, size: 16, color: Color(0xFF4CAF50)),
              const SizedBox(width: 4),
              const Text('Playlist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (leg.playlistId != null) Text(leg.playlistName, style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF50), fontWeight: FontWeight.w500)),
            ]),
            children: [
              if (leg.playlistId != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withOpacity(0.2))),
                  child: Row(children: [
                    const Icon(Icons.playlist_play_rounded, size: 20, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(leg.playlistName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    GestureDetector(
                      onTap: () => _viewPlaylist(leg.playlistId!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() { leg.playlistId = null; leg.playlistName = ''; }),
                      child: const Icon(Icons.close, size: 18, color: AppColors.lightTextSecondary),
                    ),
                  ]),
                ),
              if (leg.playlistId != null) const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _openPlaylistPicker(index),
                  icon: const Icon(Icons.search, size: 16), label: Text(leg.playlistId != null ? 'Change' : 'Find playlist'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.brandPrimary, side: BorderSide(color: AppColors.brandPrimary.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _createPlaylistForLeg(index),
                  icon: const Icon(Icons.add, size: 16), label: const Text('Create new'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.brandPrimary, side: BorderSide(color: AppColors.brandPrimary.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                )),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Author notes
        TextField(controller: leg.notesController, maxLines: 2, decoration: _inputDeco('Tips for travelers in ${leg.city.isNotEmpty ? leg.city : "this city"}...').copyWith(prefixIcon: const Icon(Icons.edit_note, size: 18))),
      ]),
    );
  }

  // ─── Cover photo picker ──────────────────────────────────────────

  Widget _buildCoverPhotoPicker() {
    final hasImage = _coverPhotoBytes != null || _coverPhotoUrl.isNotEmpty;

    return GestureDetector(
      onTap: _isUploadingCover ? null : _pickCoverPhoto,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasImage ? AppColors.brandPrimary.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
          image: _coverPhotoBytes != null
              ? DecorationImage(image: MemoryImage(_coverPhotoBytes!), fit: BoxFit.cover)
              : _coverPhotoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_coverPhotoUrl),
                      fit: BoxFit.cover,
                      onError: (_, _) {},
                    )
                  : null,
        ),
        child: _isUploadingCover
            ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
            : !hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Tap to upload cover photo', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  )
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Change', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Future<void> _pickCoverPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final contentType = _getContentType(file.extension ?? '');
    if (contentType == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported file type. Use JPG, PNG, or WebP.')),
        );
      }
      return;
    }

    setState(() {
      _coverPhotoBytes = file.bytes;
      _coverPhotoFileName = file.name;
      _coverPhotoContentType = contentType;
    });
  }

  Future<String?> _uploadCoverPhoto(String token) async {
    if (_coverPhotoBytes == null || _coverPhotoFileName == null || _coverPhotoContentType == null) return null;

    setState(() => _isUploadingCover = true);
    try {
      final uploadData = await _templateService.requestCoverUploadUrl(
        token: token,
        fileName: _coverPhotoFileName!,
        contentType: _coverPhotoContentType!,
        sizeBytes: _coverPhotoBytes!.length,
      );

      final uploadUrl = uploadData['upload_url'] as String;
      final fileKey = uploadData['file_key'] as String;

      await _templateService.uploadFileToPresignedUrl(
        uploadUrl: uploadUrl,
        fileBytes: _coverPhotoBytes!,
        contentType: _coverPhotoContentType!,
      );

      final publicUrl = await _templateService.confirmCoverUpload(
        token: token,
        fileKey: fileKey,
        fileName: _coverPhotoFileName!,
        contentType: _coverPhotoContentType!,
        sizeBytes: _coverPhotoBytes!.length,
      );

      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cover upload failed: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
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
      default:
        return null;
    }
  }

  Widget _sectionTitle(String title) {
    return Row(children: [
      Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary, letterSpacing: 1.5))),
      Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
    ]);
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.brandPrimary)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ─── Leg Draft ──────────────────────────────────────────────────

class _LegDraft {
  String city;
  String country;
  int days;
  List<HotelPick> hotelPicks;
  String? playlistId;
  String playlistName;
  final TextEditingController cityController;
  final TextEditingController notesController;

  _LegDraft({this.city = '', this.country = '', this.days = 1, this.hotelPicks = const [], this.playlistId, this.playlistName = '', String authorNotes = ''})
      : cityController = TextEditingController(text: city),
        notesController = TextEditingController(text: authorNotes);
}

// ─── City Search Field ──────────────────────────────────────────

class _CitySearchField extends StatefulWidget {
  final TextEditingController controller;
  final ApiService apiService;
  final ValueChanged<City> onCitySelected;

  const _CitySearchField({required this.controller, required this.apiService, required this.onCitySelected});

  @override
  State<_CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<_CitySearchField> {
  List<City> _suggestions = [];
  bool _isSearching = false;

  Future<void> _onChanged(String query) async {
    if (query.length < 2) { setState(() => _suggestions = []); return; }
    setState(() => _isSearching = true);
    try {
      final results = await widget.apiService.searchCities(query, limit: 6);
      if (mounted) setState(() { _suggestions = results; _isSearching = false; });
    } catch (_) { if (mounted) setState(() => _isSearching = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: 'Search city...', filled: true, fillColor: const Color(0xFFF8F5FF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: _isSearching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary))) : const Icon(Icons.search, color: AppColors.lightTextSecondary, size: 20),
        ),
        onChanged: _onChanged,
      ),
      if (_suggestions.isNotEmpty)
        Container(
          constraints: const BoxConstraints(maxHeight: 200), margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.2)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))]),
          child: ListView.separated(
            shrinkWrap: true, padding: EdgeInsets.zero, itemCount: _suggestions.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
            itemBuilder: (_, i) {
              final city = _suggestions[i];
              return ListTile(
                dense: true, visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.brandPrimary),
                title: Text(city.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(city.country, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                onTap: () {
                  widget.controller.text = city.name;
                  widget.onCitySelected(city);
                  setState(() => _suggestions = []);
                },
              );
            },
          ),
        ),
    ]);
  }
}
