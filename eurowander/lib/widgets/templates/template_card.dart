import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/template.dart';

class TemplateCard extends StatefulWidget {
  final TemplateListItem template;
  final VoidCallback? onTap;

  const TemplateCard({super.key, required this.template, this.onTap});

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  TemplateListItem get template => widget.template;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover photo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: template.coverPhotoUrl.isNotEmpty
                ? Image.network(
                    template.coverPhotoUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildPlaceholderCover(),
                  )
                : _buildPlaceholderCover(),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (template.legCities.isNotEmpty)
                  Text(
                    template.legCities.join(' → '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                // Stats row
                Row(
                  children: [
                    _buildStat('${template.totalDays} days'),
                    if (template.estimatedBudgetMin != null) ...[
                      const SizedBox(width: 8),
                      _buildStat(
                        '${template.currency}${template.estimatedBudgetMin!.toInt()}'
                        '–${template.estimatedBudgetMax?.toInt() ?? ''}',
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fork_right_rounded,
                          size: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${template.forkCount}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${template.likeCount}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Tags
                if (template.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: template.tags
                        .take(3)
                        .map((tag) => _buildTagChip(tag))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          template.legCities.isNotEmpty ? template.legCities.first : 'Trip',
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
