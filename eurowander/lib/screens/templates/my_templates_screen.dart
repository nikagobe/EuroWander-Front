import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // Custom app bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'My Templates',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.textSecondary,
                    indicatorColor: AppTheme.primaryColor,
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
                          return const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryColor),
                          );
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
            ),
          ),
        ),
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
              status == 'published' ? Icons.public : Icons.edit_note,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              status == 'published' ? 'No published templates' : 'No drafts yet',
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
        foregroundColor: color ?? AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
