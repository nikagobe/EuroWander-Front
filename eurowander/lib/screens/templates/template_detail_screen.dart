// ignore_for_file: unused_element, unused_local_variable
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/template_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/templates/author_tip_box.dart';
import 'fork_wizard/fork_wizard_screen.dart';

class TemplateDetailScreen extends StatefulWidget {
  final String templateId;
  const TemplateDetailScreen({super.key, required this.templateId});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().loadTemplateDetail(widget.templateId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Consumer<TemplateProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDetail) {
            return const Center(child: ShimmerList());
          }
          final template = provider.currentTemplate;
          if (template == null) {
            return const EmptyState(
              icon: Icons.description_outlined,
              title: 'Template not found',
            );
          }

          final userId = context.read<AuthProvider>().user?.id ?? '';
          final isLiked = provider.isLiked(template.id);

          return Column(children: [
            EWAppBar(
              title: 'Template',
              trailing: [
                EWIconButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  iconColor: isLiked ? Colors.red : null,
                  onTap: () => provider.toggleLike(templateId: template.id, userId: userId),
                ),
              ],
            ),
            Expanded(
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(child: _buildContent(template)),
              ]),
            ),
            _buildBottomCta(),
          ]);
        },
      ),
    );
  }

  Widget _buildContent(TemplateResponse template) {
    final theme = Theme.of(context);
    final ew = context.ew;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cover photo
        if (template.coverPhotoUrl.isNotEmpty)
          ClipRRect(
            borderRadius: AppRadius.borderLg,
            child: Image.network(template.coverPhotoUrl, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholderCover(template)),
          )
        else
          _placeholderCover(template),
        const SizedBox(height: AppSpacing.md),

        // Title & stats
        Text(template.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xxs),
        Row(children: [
          Text('🍴 ${template.forkCount} forks', style: theme.textTheme.bodyMedium),
          const SizedBox(width: AppSpacing.md),
          Text('❤️ ${template.likeCount}', style: theme.textTheme.bodyMedium),
        ]),
        const SizedBox(height: AppSpacing.sm),

        // Budget & duration chips
        Row(children: [
          _infoChip(Icons.calendar_today, '${template.totalDays} days'),
          const SizedBox(width: AppSpacing.xs),
          if (template.estimatedBudgetMin != null)
            _infoChip(Icons.account_balance_wallet, '${template.currency}${template.estimatedBudgetMin!.toInt()} – ${template.estimatedBudgetMax?.toInt() ?? ''}'),
        ]),
        const SizedBox(height: AppSpacing.sm),

        // Description
        if (template.description.isNotEmpty) ...[
          Text(template.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Tags
        if (template.tags.isNotEmpty) ...[
          Wrap(spacing: AppSpacing.xs, runSpacing: 6, children: template.tags.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.1), borderRadius: AppRadius.borderLg),
            child: Text(t, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brandPrimary, fontWeight: FontWeight.w500)),
          )).toList()),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Itinerary section
        _sectionHeader('ITINERARY'),
        const SizedBox(height: AppSpacing.sm),

        // Legs
        ...template.legs.map((leg) => _buildLegCard(leg)),
      ]),
    );
  }

  Widget _buildLegCard(TemplateLeg leg) {
    final theme = Theme.of(context);
    final ew = context.ew;
    return EWCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📍', style: TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text('${leg.order}. ${leg.city}, ${leg.country} (${leg.days} days)', style: theme.textTheme.titleMedium)),
        ]),
        const SizedBox(height: AppSpacing.sm),

        // Hotels
        if (leg.hotelRecommendations != null && leg.hotelRecommendations!.primaryPicks.isNotEmpty) ...[
          Text('🏨 Hotels (${leg.hotelRecommendations!.primaryPicks.length} picks):', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          ...leg.hotelRecommendations!.primaryPicks.map((pick) => Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xxs),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (pick.priority == 1) const Text('⭐ ', style: TextStyle(fontSize: 14)),
                Expanded(child: Text('${pick.name} ${'★' * pick.stars}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
              ]),
              if (pick.authorReview.isNotEmpty)
                Padding(padding: const EdgeInsets.only(left: AppSpacing.lg), child: Text('"${pick.authorReview}"', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: ew.textSecondary))),
              if (pick.pricePaid != null)
                Padding(padding: const EdgeInsets.only(left: AppSpacing.lg), child: Text('Author paid: ${pick.currency}${pick.pricePaid!.toInt()}/night', style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary))),
            ]),
          )),
        ],

        // Playlist
        if (leg.playlistId.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('🎵 Attractions playlist attached', style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary)),
        ],

        // Restaurants
        if (leg.restaurantIds.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text('🍽 ${leg.restaurantIds.length} restaurants recommended', style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary)),
        ],

        // Author notes
        if (leg.authorNotes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          AuthorTipBox(tip: leg.authorNotes),
        ],
      ]),
    );
  }

  Widget _placeholderCover(TemplateResponse template) {
    return Container(
      height: 160, width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: AppRadius.borderLg,
      ),
      child: Center(child: Text(template.title, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
    );
  }

  Widget _sectionHeader(String title) {
    final ew = context.ew;
    return Row(children: [
      Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ew.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
      Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
    ]);
  }

  Widget _infoChip(IconData icon, String text) {
    final ew = context.ew;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: ew.cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.brandPrimary),
        const SizedBox(width: AppSpacing.xxs),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildBottomCta() {
    final ew = context.ew;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: context.ew.cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForkWizardScreen(templateId: widget.templateId))),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg), elevation: 0),
            child: const Text('🚀  USE THIS TEMPLATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }
}





