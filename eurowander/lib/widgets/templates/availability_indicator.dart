import 'package:flutter/material.dart';

class AvailabilityIndicator extends StatelessWidget {
  final bool isAvailable;
  final String? priceText;

  const AvailabilityIndicator({
    super.key,
    required this.isAvailable,
    this.priceText,
  });

  @override
  Widget build(BuildContext context) {
    if (isAvailable) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 4),
          Text(
            priceText != null ? 'Available • $priceText' : 'Available',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800), size: 16),
        SizedBox(width: 4),
        Text(
          'Not available for your dates',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFFF9800),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
