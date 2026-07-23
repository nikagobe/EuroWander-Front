import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TierBadge extends StatelessWidget {
  final String label;
  final bool isTopPick;

  const TierBadge({
    super.key,
    required this.label,
    this.isTopPick = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTopPick
            ? const Color(0xFFFFF3E0)
            : AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isTopPick
            ? Border.all(color: const Color(0xFFFF9800), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTopPick) ...[
            const Text('⭐ ', style: TextStyle(fontSize: 12)),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isTopPick
                  ? const Color(0xFFE65100)
                  : AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
