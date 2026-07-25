import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/template_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/templates/template_card.dart';
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
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EWAppBar(title: 'Trip Templates'),
          _buildSearchBar(),
          _buildTagFilters(),
          _buildSortRow(),
          Expanded(child: _buildTemplateList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search templates...',
          prefixIcon: Icon(Icons.search, color: context.ew.textSecondary),
          filled: true,
          fillColor: context.ew.cardColor,
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderMd,
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        ),
        onSubmitted: (value) {
          context.read<TemplateProvider>().setDestinationFilter(
                value.isEmpty ? null : value,
              );
        },
      ),
    );
  }

  Widget _buildTagFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final tag = _tags[index];
          final isSelected = _selectedTag == tag;
          return FilterChip(
            label: Text(tag),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedTag = selected ? tag : null;
              });
              context
                  .read<TemplateProvider>()
                  .setTagsFilter(_selectedTag);
            },
            selectedColor: AppColors.brandPrimary.withOpacity(0.15),
            checkmarkColor: AppColors.brandPrimary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.brandPrimary : context.ew.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: context.ew.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderXl,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.brandPrimary
                  : Colors.grey.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortRow() {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
          child: Row(
            children: [
              _buildSortChip('Newest', 'newest', provider),
              const SizedBox(width: AppSpacing.xs),
              _buildSortChip('Most Forked', 'most_forked', provider),
              const SizedBox(width: AppSpacing.xs),
              _buildSortChip('Popular', 'most_liked', provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortChip(String label, String value, TemplateProvider provider) {
    final isSelected = provider.sortBy == value;
    return GestureDetector(
      onTap: () => provider.setSortBy(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : context.ew.cardColor,
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : context.ew.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateList() {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.templates.isEmpty) {
          return const ShimmerList();
        }

        if (provider.templates.isEmpty) {
          return const EmptyState(
            icon: Icons.map_outlined,
            title: 'No templates found',
            subtitle: 'Be the first to share a trip template!',
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
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.brandPrimary),
                ),
              );
            }

            final template = provider.templates[index];
            return TemplateCard(
              template: template,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TemplateDetailScreen(templateId: template.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
