import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HotelPickCard extends StatelessWidget {
  final String name;
  final int stars;
  final String photoUrl;
  final String authorReview;
  final double? authorPricePaid;
  final String currency;
  final bool isAvailable;
  final double? currentPrice;
  final bool isSelected;
  final VoidCallback? onTap;

  const HotelPickCard({
    super.key,
    required this.name,
    required this.stars,
    required this.photoUrl,
    required this.authorReview,
    this.authorPricePaid,
    required this.currency,
    required this.isAvailable,
    this.currentPrice,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : isAvailable
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: photoUrl.isNotEmpty
                      ? Image.network(photoUrl, width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder())
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isAvailable ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          ...List.generate(stars, (_) => Icon(Icons.star_rounded, size: 14, color: isAvailable ? const Color(0xFFFF9800) : Colors.grey)),
                        ],
                      ),
                      if (authorReview.isNotEmpty)
                        Text(
                          '"$authorReview"',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      if (authorPricePaid != null)
                        Text(
                          'Author paid: $currency${authorPricePaid!.toInt()}/night',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            // Availability indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isAvailable ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isAvailable
                      ? (currentPrice != null ? 'Available • $currency${currentPrice!.toInt()}/night' : 'Available')
                      : 'Not available for your dates',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAvailable ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: const Icon(Icons.hotel, color: AppTheme.primaryColor, size: 24),
  );
}
