import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/template_provider.dart';
import 'create_template/create_template_screen.dart';
import 'template_detail_screen.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Templates',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Drafts'),
            Tab(text: 'Published'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: Consumer<TemplateProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingMine) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(provider.myDrafts, 'draft'),
              _buildList(provider.myPublished, 'published'),
              _buildList(provider.myArchived, 'archived'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateTemplateScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Template'),
      ),
    );
  }

  Widget _buildList(List<TemplateListItem> templates, String status) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'draft'
                  ? Icons.edit_note
                  : status == 'published'
                      ? Icons.public
                      : Icons.archive,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              status == 'draft'
                  ? 'No drafts yet'
                  : status == 'published'
                      ? 'No published templates'
                      : 'No archived templates',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateItem(template, status);
      },
    );
  }

  Widget _buildTemplateItem(TemplateListItem template, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  template.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 6),
          if (template.legCities.isNotEmpty)
            Text(
              '${template.legCities.join(" → ")} • ${template.totalDays} days',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (status == 'published') ...[
            const SizedBox(height: 4),
            Text(
              '🍴 ${template.forkCount} forks • ❤️ ${template.likeCount}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          _buildActions(template, status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'draft':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'published':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActions(TemplateListItem template, String status) {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final provider = context.read<TemplateProvider>();

    if (status == 'draft') {
      return Row(
        children: [
          _buildActionButton('Edit', Icons.edit_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CreateTemplateScreen(editTemplateId: template.id),
              ),
            );
          }),
          const SizedBox(width: 8),
          _buildActionButton('Delete', Icons.delete_outline, () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete template?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              provider.deleteTemplate(
                templateId: template.id,
                userId: userId,
              );
            }
          }, color: Colors.red),
          const SizedBox(width: 8),
          _buildActionButton('Publish', Icons.publish, () {
            provider.publishTemplate(
              templateId: template.id,
              userId: userId,
            );
          }, color: Colors.green),
        ],
      );
    }

    if (status == 'published') {
      return Row(
        children: [
          _buildActionButton('View', Icons.visibility_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TemplateDetailScreen(templateId: template.id),
              ),
            );
          }),
          const SizedBox(width: 8),
          _buildActionButton('Archive', Icons.archive_outlined, () {
            provider.archiveTemplate(
              templateId: template.id,
              userId: userId,
            );
          }),
        ],
      );
    }

    // Archived
    return _buildActionButton('View', Icons.visibility_outlined, () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TemplateDetailScreen(templateId: template.id),
        ),
      );
    });
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
        foregroundColor: color ?? AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
