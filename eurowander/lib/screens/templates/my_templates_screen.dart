import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/template_provider.dart';
import '../../widgets/widgets.dart';
import 'create_template/create_template_screen.dart';

class MyTemplatesScreen extends StatefulWidget {
  const MyTemplatesScreen({super.key});

  @override
  State<MyTemplatesScreen> createState() => _MyTemplatesScreenState();
}

class _MyTemplatesScreenState extends State<MyTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<TemplateProvider>().loadMyTemplates(userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateTemplateScreen(),
            ),
          );
        },
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Template'),
      ),
      child: Column(
        children: [
          const EWAppBar(title: 'My Templates'),
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.brandPrimary,
            unselectedLabelColor: context.ew.textSecondary,
            indicatorColor: AppColors.brandPrimary,
            tabs: const [
              Tab(text: 'Published'),
              Tab(text: 'Drafts'),
            ],
          ),
          // Content
          Expanded(
            child: Consumer<TemplateProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingMine) {
                  return const ShimmerList();
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(provider.myPublished, 'published'),
                    _buildList(provider.myDrafts, 'draft'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TemplateListItem> templates, String status) {
    if (templates.isEmpty) {
      return EmptyState(
        icon: status == 'published' ? Icons.public : Icons.edit_note,
        title: status == 'published' ? 'No published templates' : 'No drafts yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateItem(template, status);
      },
    );
  }

  Widget _buildTemplateItem(TemplateListItem template, String status) {
    final theme = Theme.of(context);

    return EWCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  template.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (template.legCities.isNotEmpty)
            Text(
              '${template.legCities.join(" → ")} • ${template.totalDays} days',
              style: theme.textTheme.bodyMedium,
            ),
          if (status == 'published') ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Icon(Icons.fork_right_rounded, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 2),
                Text('${template.forkCount} forks', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                Text('\u2022', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                Icon(Icons.favorite, size: 14, color: Colors.red.shade400),
                const SizedBox(width: 2),
                Text('${template.likeCount}', style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _buildActions(template, status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isPublished = status == 'published';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPublished ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPublished ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildActions(TemplateListItem template, String status) {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final provider = context.read<TemplateProvider>();

    return Row(
      children: [
        _buildActionButton('Edit', Icons.edit_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTemplateScreen(editTemplateId: template.id)));
        }),
        const SizedBox(width: 8),
        _buildActionButton('Delete', Icons.delete_outline, () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete template?'),
              content: const Text('This cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (confirmed == true) {
            provider.deleteTemplate(templateId: template.id, userId: userId);
          }
        }, color: Colors.red),
        const SizedBox(width: 8),
        if (status == 'draft')
          _buildActionButton('Publish', Icons.publish, () {
            provider.publishTemplate(templateId: template.id, userId: userId);
          }, color: Colors.green),
        if (status == 'published')
          _buildActionButton('Unpublish', Icons.unpublished_outlined, () {
            provider.unpublishTemplate(templateId: template.id, userId: userId);
          }),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.brandPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
