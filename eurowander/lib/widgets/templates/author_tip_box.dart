import 'package:flutter/material.dart';

class AuthorTipBox extends StatelessWidget {
  final String tip;

  const AuthorTipBox({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    if (tip.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1565C0),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
