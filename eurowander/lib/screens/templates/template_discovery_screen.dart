import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/template_provider.dart';
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTagFilters(),
            _buildSortRow(),
            Expanded(child: _buildTemplateList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        'Trip Templates',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search templates...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
            selectedColor: AppTheme.primaryColor.withOpacity(0.15),
            checkmarkColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryColor
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              _buildSortChip('Newest', 'newest', provider),
              const SizedBox(width: 8),
              _buildSortChip('Most Forked', 'most_forked', provider),
              const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateList() {
    return Consumer<TemplateProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.templates.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (provider.templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🗺️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No templates found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share a trip template!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: provider.templates.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.templates.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor),
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
