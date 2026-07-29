// ignore_for_file: unused_element, unused_local_variable
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../models/template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/template_provider.dart';
import '../../services/playlist_service.dart';
import '../../widgets/widgets.dart';
import '../../widgets/templates/author_tip_box.dart';
import '../../utils/page_transitions.dart';
import '../playlists/playlist_detail_screen.dart';
import 'fork_wizard/fork_wizard_screen.dart';

class TemplateDetailScreen extends StatefulWidget {
  final String templateId;
  const TemplateDetailScreen({super.key, required this.templateId});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().loadTemplateDetail(widget.templateId);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TemplateProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDetail) {
            return Container(
              decoration: BoxDecoration(gradient: context.ew.surfaceGradient),
              child: const Center(child: ShimmerList()),
            );
          }
          final template = provider.currentTemplate;
          if (template == null) {
            return Container(
              decoration: BoxDecoration(gradient: context.ew.surfaceGradient),
              child: const Center(child: EmptyState(icon: Icons.description_outlined, title: 'Template not found')),
            );
          }

          // Start animations once data loads
          if (!_animController.isCompleted) _animController.forward();

          final userId = context.read<AuthProvider>().user?.id ?? '';
          final isLiked = provider.isLiked(template.id);

          return Container(
            decoration: BoxDecoration(gradient: context.ew.surfaceGradient),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(children: [
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildSliverCover(template, isLiked, provider, userId),
                        SliverToBoxAdapter(child: FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp,
                            child: _buildBody(template),
                          ),
                        )),
                      ],
                    ),
                  ),
                  _buildBottomCta(template),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Cover with SliverAppBar ──────────────────────────────────────

  Widget _buildSliverCover(TemplateResponse template, bool isLiked, TemplateProvider provider, String userId) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.brandPrimary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: IconButton(
              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 20, color: isLiked ? Colors.red.shade300 : Colors.white),
              onPressed: () => provider.toggleLike(templateId: template.id, userId: userId),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (template.coverPhotoUrl.isNotEmpty)
              Image.network(template.coverPhotoUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _gradientCover(template))
            else
              _gradientCover(template),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            // Title overlay at bottom
            Positioned(
              bottom: 16, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    _coverChip(Icons.calendar_today_rounded, '${template.totalDays} days'),
                    const SizedBox(width: 8),
                    _coverChip(Icons.location_on_rounded, template.legs.map((l) => l.city).join(' \u2022 ')),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _gradientCover(TemplateResponse template) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.brandSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.travel_explore_rounded, size: 64, color: Colors.white.withOpacity(0.3)),
      ),
    );
  }

  // ─── Body content ─────────────────────────────────────────────────

  Widget _buildBody(TemplateResponse template) {
    final theme = Theme.of(context);
    final ew = context.ew;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats row
        _buildStatsRow(template),
        const SizedBox(height: 20),

        // Description
        if (template.description.isNotEmpty) ...[
          Text(
            template.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, color: ew.textPrimary),
          ),
          const SizedBox(height: 20),
        ],

        // Budget card
        if (template.estimatedBudgetMin != null) ...[
          _buildBudgetCard(template),
          const SizedBox(height: 20),
        ],

        // Tags
        if (template.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: template.tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.brandPrimary.withOpacity(0.12)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5, decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.5), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('#$t', style: const TextStyle(fontSize: 12, color: AppColors.brandPrimary, fontWeight: FontWeight.w500)),
              ]),
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Itinerary header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route_rounded, size: 20, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: 10),
            Text('Itinerary', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${template.legs.length} cities', style: TextStyle(fontSize: 13, color: ew.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),

        // Timeline legs
        ...template.legs.asMap().entries.map((entry) =>
          _buildTimelineLeg(entry.value, isLast: entry.key == template.legs.length - 1, index: entry.key),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ─── Stats row ────────────────────────────────────────────────────

  Widget _buildStatsRow(TemplateResponse template) {
    final ew = context.ew;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ew.borderSubtle),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _statPill(Icons.calendar_today_rounded, '${template.totalDays}', 'days', AppColors.brandAmber),
          const SizedBox(width: 8),
          _statPill(Icons.location_on_rounded, '${template.legs.length}', 'cities', AppColors.brandPrimary),
          const SizedBox(width: 8),
          _statPill(Icons.fork_right_rounded, '${template.forkCount}', 'forks', AppColors.info),
          const SizedBox(width: 8),
          _statPill(Icons.favorite_rounded, '${template.likeCount}', 'likes', Colors.red.shade400),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: context.ew.textTertiary)),
          ],
        ),
      ),
    );
  }

  // ─── Budget card ──────────────────────────────────────────────────

  Widget _buildBudgetCard(TemplateResponse template) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.success.withOpacity(0.06), AppColors.success.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, size: 24, color: AppColors.success),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Estimated Budget', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.ew.textSecondary)),
          const SizedBox(height: 4),
          Text(
            '${template.currency} ${template.estimatedBudgetMin!.toInt()} – ${template.estimatedBudgetMax?.toInt() ?? ''}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.success),
          ),
        ])),
        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.success),
      ]),
    );
  }

  // ─── Timeline leg ─────────────────────────────────────────────────

  Widget _buildTimelineLeg(TemplateLeg leg, {required bool isLast, required int index}) {
    final theme = Theme.of(context);
    final ew = context.ew;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline connector
            SizedBox(
              width: 36,
              child: Column(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandSecondary]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Center(child: Text('${leg.order}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.brandPrimary.withOpacity(0.5), AppColors.brandPrimary.withOpacity(0.1)],
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 12),
            // Content card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ew.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // City header
                  Row(children: [
                    Expanded(
                      child: Text('${leg.city}, ${leg.country}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('${leg.days} days', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brandPrimary)),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Hotels
                  if (leg.hotelRecommendations != null && leg.hotelRecommendations!.primaryPicks.isNotEmpty)
                    _buildExpandableHotels(leg),

                  // Playlist
                  if (leg.playlistId.isNotEmpty)
                    _buildExpandablePlaylist(leg),

                  // Restaurants
                  if (leg.restaurantIds.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _legSectionHeader(Icons.restaurant_rounded, 'Restaurants', '${leg.restaurantIds.length} spots'),
                  ],

                  // Author notes
                  if (leg.authorNotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    AuthorTipBox(tip: leg.authorNotes),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legSectionHeader(IconData icon, String title, String subtitle) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.brandPrimary),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const Spacer(),
      Text(subtitle, style: TextStyle(fontSize: 11, color: context.ew.textSecondary)),
    ]);
  }

  // ─── Expandable Hotels ────────────────────────────────────────────

  Widget _buildExpandableHotels(TemplateLeg leg) {
    final picks = leg.hotelRecommendations!.primaryPicks;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4),
        initiallyExpanded: false,
        leading: const Icon(Icons.hotel_rounded, size: 18, color: Color(0xFFFF9800)),
        title: Text('Hotels', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${picks.length} picks', style: TextStyle(fontSize: 11, color: context.ew.textSecondary)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: context.ew.textSecondary),
          ],
        ),
        children: picks.map((pick) => _buildHotelPickItem(pick)).toList(),
      ),
    );
  }

  // ─── Expandable Playlist ──────────────────────────────────────────

  Widget _buildExpandablePlaylist(TemplateLeg leg) {
    return _PlaylistPreviewSection(playlistId: leg.playlistId);
  }

  Widget _buildHotelPickItem(HotelPick pick) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: pick.photoUrl.isNotEmpty
                ? Image.network(pick.photoUrl, width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _hotelPlaceholder())
                : _hotelPlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(pick.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              ...List.generate(pick.stars, (_) => const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFF9800))),
            ]),
            if (pick.authorReview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('"${pick.authorReview}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.lightTextSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            if (pick.pricePaid != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('${pick.currency}${pick.pricePaid!.toInt()}/night', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFF9800))),
              ),
          ])),
          if (pick.priority == 1)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFFF9800).withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFF9800)),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.withOpacity(0.4)),
        ],
      ),
    );
  }

  Widget _hotelPlaceholder() {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.hotel_rounded, size: 20, color: Color(0xFFFF9800)),
    );
  }

  // ─── Bottom CTA ───────────────────────────────────────────────────

  Widget _buildBottomCta(TemplateResponse template) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: context.ew.cardColor,
        border: Border(top: BorderSide(color: context.ew.borderSubtle)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity, height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, EWPageRoute(page: ForkWizardScreen(templateId: widget.templateId))),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 10),
                  Text('USE THIS TEMPLATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Playlist Preview (stateful, loads items) ─────────────────────────

class _PlaylistPreviewSection extends StatefulWidget {
  final String playlistId;
  const _PlaylistPreviewSection({required this.playlistId});

  @override
  State<_PlaylistPreviewSection> createState() => _PlaylistPreviewSectionState();
}

class _PlaylistPreviewSectionState extends State<_PlaylistPreviewSection> {
  final PlaylistService _playlistService = PlaylistService();
  Playlist? _playlist;
  bool _isLoading = false;
  bool _isExpanded = false;

  Future<void> _loadPlaylist() async {
    if (_playlist != null || _isLoading) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isLoading = true);
    try {
      final playlist = await _playlistService.getPlaylist(token: token, id: widget.playlistId);
      if (mounted) setState(() => _playlist = playlist);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4),
        initiallyExpanded: false,
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
          if (expanded) _loadPlaylist();
        },
        leading: const Icon(Icons.attractions_rounded, size: 18, color: AppColors.brandPrimary),
        title: const Text('Attractions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Playlist', style: TextStyle(fontSize: 11, color: ew.textSecondary)),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more, size: 18, color: ew.textSecondary),
            ),
          ],
        ),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary))),
            )
          else if (_playlist != null) ...[
            // Playlist header
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                if (_playlist!.coverPhotoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_playlist!.coverPhotoUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, _, _) => _playlistIcon()),
                  )
                else
                  _playlistIcon(),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_playlist!.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${_playlist!.items.length} places \u2022 ${_playlist!.totalDays} days', style: TextStyle(fontSize: 11, color: ew.textSecondary)),
                ])),
              ]),
            ),
            const SizedBox(height: 8),
            // Preview items (first 3)
            ..._playlist!.items.take(3).map((item) => _buildPlaylistItemPreview(item)),
            if (_playlist!.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+${_playlist!.items.length - 3} more places', style: TextStyle(fontSize: 11, color: ew.textSecondary, fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 10),
            // View full button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, EWPageRoute(page: PlaylistDetailScreen(playlistId: widget.playlistId)));
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('View full playlist'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                  side: const BorderSide(color: AppColors.brandPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Could not load playlist', style: TextStyle(fontSize: 12, color: ew.textSecondary)),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItemPreview(PlaylistItem item) {
    final ew = context.ew;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: item.photoUrl.isNotEmpty
              ? Image.network(item.photoUrl, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_, _, _) => _itemPlaceholder(item))
              : _itemPlaceholder(item),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(children: [
            if (item.category.isNotEmpty) Text(item.category, style: TextStyle(fontSize: 10, color: ew.textSecondary)),
            if (item.category.isNotEmpty && item.rating > 0) Text(' \u2022 ', style: TextStyle(fontSize: 10, color: ew.textSecondary)),
            if (item.rating > 0) ...[
              const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFF9800)),
              Text(' ${item.rating}', style: TextStyle(fontSize: 10, color: ew.textSecondary)),
            ],
          ]),
        ])),
        Text('~${item.suggestedDurationMinutes}min', style: TextStyle(fontSize: 10, color: ew.textSecondary)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, size: 18, color: ew.textSecondary.withOpacity(0.5)),
      ]),
    );
  }

  Widget _playlistIcon() {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.queue_music_rounded, size: 20, color: AppColors.brandPrimary),
    );
  }

  Widget _itemPlaceholder(PlaylistItem item) {
    final isAttraction = item.itemType == 'attraction';
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: (isAttraction ? Colors.deepOrange : Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        isAttraction ? Icons.attractions_rounded : Icons.restaurant_rounded,
        size: 16,
        color: isAttraction ? Colors.deepOrange : Colors.green,
      ),
    );
  }
}





