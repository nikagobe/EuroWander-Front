import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/template_provider.dart';
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<TemplateProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDetail) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final template = provider.currentTemplate;
          if (template == null) {
            return const Center(child: Text('Template not found'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(template, provider),
              SliverToBoxAdapter(child: _buildContent(template)),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<TemplateProvider>(
        builder: (context, provider, _) {
          if (provider.currentTemplate == null) return const SizedBox.shrink();
          return _buildBottomCta();
        },
      ),
    );
  }

  Widget _buildAppBar(TemplateResponse template, TemplateProvider provider) {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final isLiked = provider.isLiked(template.id);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: template.coverPhotoUrl.isNotEmpty
            ? Image.network(
                template.coverPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderCover(template),
              )
            : _buildPlaceholderCover(template),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.white,
          ),
          onPressed: () {
            provider.toggleLike(
              templateId: template.id,
              userId: userId,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // TODO: Share template
          },
        ),
      ],
    );
  }

  Widget _buildPlaceholderCover(TemplateResponse template) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          template.title,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildContent(TemplateResponse template) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & author info
          Text(
            template.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '🍴 ${template.forkCount} forks',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 16),
              Text(
                '❤️ ${template.likeCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Budget & Duration
          Row(
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                '${template.totalDays} days',
              ),
              const SizedBox(width: 12),
              if (template.estimatedBudgetMin != null)
                _buildInfoChip(
                  Icons.account_balance_wallet,
                  '${template.currency} ${template.estimatedBudgetMin!.toInt()}'
                  ' – ${template.estimatedBudgetMax?.toInt() ?? ''}',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          if (template.description.isNotEmpty) ...[
            Text(
              template.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
          ],

          // Tags
          if (template.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: template.tags.map((tag) => _buildTag(tag)).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Route section
          _buildSectionHeader('ROUTE'),
          const SizedBox(height: 12),

          // Legs
          ...template.legs.map((leg) => _buildLegCard(leg)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildLegCard(TemplateLegResponse leg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leg header
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Leg ${leg.order}: ${leg.city}, ${leg.country} (${leg.days} days)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Flight recommendation
          if (leg.flightRecommendation != null) ...[
            _buildTransportInfo(
              icon: '✈️',
              title:
                  '${leg.flightRecommendation!.originCity} → ${leg.flightRecommendation!.destinationCity}',
              subtitle:
                  'Recommended: ${leg.flightRecommendation!.preferredAirlines.join(", ")}',
              price: leg.flightRecommendation!.typicalPriceMin != null
                  ? '€${leg.flightRecommendation!.typicalPriceMin!.toInt()}'
                      '–${leg.flightRecommendation!.typicalPriceMax?.toInt() ?? ''}'
                  : null,
            ),
            if (leg.flightRecommendation!.tip.isNotEmpty)
              AuthorTipBox(tip: leg.flightRecommendation!.tip),
          ],

          // Transport recommendation
          if (leg.transportRecommendation != null) ...[
            _buildTransportInfo(
              icon: '🚌',
              title:
                  '${leg.transportRecommendation!.fromCity} → ${leg.transportRecommendation!.toCity}',
              subtitle:
                  'Recommended: ${leg.transportRecommendation!.preferredProviders.join(", ")}',
              price: leg.transportRecommendation!.typicalPrice != null
                  ? '~${leg.transportRecommendation!.currency} ${leg.transportRecommendation!.typicalPrice!.toInt()}'
                  : null,
            ),
            if (leg.transportRecommendation!.tip.isNotEmpty)
              AuthorTipBox(tip: leg.transportRecommendation!.tip),
          ],

          // Hotel recommendations
          if (leg.hotelRecommendations != null) ...[
            const SizedBox(height: 8),
            Text(
              '🏨 Hotels (${leg.hotelRecommendations!.primaryPicks.length} picks):',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            ...leg.hotelRecommendations!.primaryPicks.map(
              (pick) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (pick.priority == 1)
                          const Text('⭐ ',
                              style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            '${pick.name} ${'★' * pick.stars}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (pick.authorReview.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          '"${pick.authorReview}"',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    if (pick.pricePaid != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          'Author paid: ${pick.currency}${pick.pricePaid!.toInt()}/night',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // Playlist
          if (leg.playlistId != null && leg.playlistId!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '🎵 Playlist attached',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],

          // Restaurants
          if (leg.restaurantIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '🍽 ${leg.restaurantIds.length} restaurants recommended',
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],

          // Author notes
          if (leg.authorNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝 ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      leg.authorNotes,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportInfo({
    required String icon,
    required String title,
    required String subtitle,
    String? price,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (price != null)
                  Text(
                    'Typical: $price',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ForkWizardScreen(templateId: widget.templateId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              '🚀  USE THIS TEMPLATE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
