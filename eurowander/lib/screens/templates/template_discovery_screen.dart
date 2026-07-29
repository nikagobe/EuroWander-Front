import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/template_provider.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/widgets.dart';
import 'create_template/create_template_screen.dart';
import 'my_templates_screen.dart';
import 'template_detail_screen.dart';

class TemplateDiscoveryScreen extends StatefulWidget {
  const TemplateDiscoveryScreen({super.key});

  @override
  State<TemplateDiscoveryScreen> createState() =>
      _TemplateDiscoveryScreenState();
}

class _TemplateDiscoveryScreenState extends State<TemplateDiscoveryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTag;

  static const _tags = [
    'budget',
    'luxury',
    'backpacking',
    'romantic',
    'family',
    '7-day',
    '14-day',
    'weekend',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().loadTemplates(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TemplateProvider>().loadTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back + title + My Templates + Create
          EWAppBar(
            title: 'Trip Templates',
            trailing: [
              _buildHeaderAction(
                icon: Icons.folder_special_rounded,
                label: 'Mine',
                color: AppColors.brandAmber,
                onTap: () => Navigator.push(context, EWPageRoute(page: const MyTemplatesScreen())),
              ),
              _buildHeaderAction(
                icon: Icons.add_rounded,
                label: 'Create',
                color: AppColors.brandPrimary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTemplateScreen())),
              ),
            ],
          ),

          // Hero search area
          _buildHeroSearch(ew),

          const SizedBox(height: AppSpacing.sm),

          // Tag filters
          _buildTagFilters(ew),

          const SizedBox(height: AppSpacing.xs),

          // Sort + result count
          _buildSortRow(ew),

          // Template list
          Expanded(child: _buildTemplateList(ew)),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSearch(EuroWanderTheme ew) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandAmber.withOpacity(0.08),
            AppColors.brandPrimary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandAmber.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compass_calibration_rounded, size: 20, color: AppColors.brandAmber),
              const SizedBox(width: 8),
              Text(
                'Find your perfect itinerary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ew.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by destination, title...',
              hintStyle: TextStyle(fontSize: 13, color: ew.textTertiary),
              prefixIcon: Icon(Icons.search_rounded, color: ew.textSecondary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 18, color: ew.textTertiary),
                      onPressed: () {
                        _searchController.clear();
                        context.read<TemplateProvider>().setDestinationFilter(null);
                      },
                    )
                  : null,
              filled: true,
              fillColor: ew.cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => setState(() {}),
            onSubmitted: (value) {
              context.read<TemplateProvider>().setDestinationFilter(value.isEmpty ? null : value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilters(EuroWanderTheme ew) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = _tags[index];
          final isSelected = _selectedTag == tag;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTag = isSelected ? null : tag);
              context.read<TemplateProvider>().setTagsFilter(_selectedTag);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandAmber : ew.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.brandAmber : ew.border,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.brandAmber.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : ew.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortRow(EuroWanderTheme ew) {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
          child: Row(
            children: [
              Text(
                '${provider.templates.length} templates',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ew.textTertiary),
              ),
              const Spacer(),
              _buildSortChip('Newest', 'newest', provider, ew),
              const SizedBox(width: 6),
              _buildSortChip('Forked', 'most_forked', provider, ew),
              const SizedBox(width: 6),
              _buildSortChip('Popular', 'most_liked', provider, ew),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortChip(String label, String value, TemplateProvider provider, EuroWanderTheme ew) {
    final isSelected = provider.sortBy == value;
    return GestureDetector(
      onTap: () => provider.setSortBy(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.brandPrimary : ew.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : ew.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateList(EuroWanderTheme ew) {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.templates.isEmpty) {
          return const ShimmerList();
        }

        if (provider.templates.isEmpty) {
          return const EmptyState(
            icon: Icons.map_outlined,
            title: 'No templates found',
            subtitle: 'Try different keywords or filters',
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          itemCount: provider.templates.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.templates.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
              );
            }

            final template = provider.templates[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 350 + (index.clamp(0, 10) * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
              ),
              child: _buildEnhancedTemplateCard(template, ew),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedTemplateCard(TemplateListItem t, EuroWanderTheme ew) {
    return GestureDetector(
      onTap: () => Navigator.push(context, EWPageRoute(page: TemplateDetailScreen(templateId: t.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ew.borderSubtle),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with overlays
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  t.coverPhotoUrl.isNotEmpty
                      ? Image.network(t.coverPhotoUrl, height: 150, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholderCover(t))
                      : _placeholderCover(t),
                  // Scrim
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Route on image
                  if (t.legCities.isNotEmpty)
                    Positioned(
                      bottom: 10, left: 12, right: 12,
                      child: Row(
                        children: [
                          const Icon(Icons.route_rounded, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t.legCities.join(' → '),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Days badge
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.brandAmber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${t.totalDays} days', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + arrow
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.brandAmber.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brandAmber),
                      ),
                    ],
                  ),
                  if (t.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(t.description, style: TextStyle(fontSize: 12, color: ew.textSecondary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 10),

                  // Stats row
                  Row(
                    children: [
                      _buildStatBadge(Icons.fork_right_rounded, '${t.forkCount}', ew.textSecondary),
                      const SizedBox(width: 8),
                      _buildStatBadge(Icons.favorite_rounded, '${t.likeCount}', Colors.red.shade300),
                      if (t.estimatedBudgetMin != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '€${t.estimatedBudgetMin!.toInt()}–${t.estimatedBudgetMax?.toInt() ?? ''}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                        ),
                      ],
                      const Spacer(),
                    ],
                  ),

                  // Tags
                  if (t.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: t.tags.take(4).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('#$tag', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: ew.textSecondary)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _placeholderCover(TemplateListItem t) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandSecondary]),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 36, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 6),
            Text(
              t.legCities.isNotEmpty ? t.legCities.first : 'Trip',
              style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
