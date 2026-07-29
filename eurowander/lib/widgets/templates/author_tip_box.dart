import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AuthorTipBox extends StatelessWidget {
  final String tip;

  const AuthorTipBox({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    if (tip.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF8E1),
            const Color(0xFFFFF3E0).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.08),
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
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFE65100)),
              ),
              const SizedBox(width: 8),
              const Text(
                'Author\'s Note',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE65100),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tip,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4E342E),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
