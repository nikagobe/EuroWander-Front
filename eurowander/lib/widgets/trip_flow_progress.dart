import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A horizontal step progress indicator for the Plan Trip flow.
/// Shows the user's position in the multi-step wizard.
class TripFlowProgress extends StatelessWidget {
  const TripFlowProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    this.labels = const ['Outbound', 'Return', 'Transport', 'Confirm'],
  });

  final int currentStep; // 0-indexed
  final int totalSteps;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.brandPrimary
                      : ew.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          // Step dot + label
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;
          final label = stepIndex < labels.length ? labels[stepIndex] : '';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 28 : 20,
                height: isCurrent ? 28 : 20,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.brandPrimary
                      : isCurrent
                          ? AppColors.brandPrimary
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? AppColors.brandPrimary
                        : ew.border,
                    width: isCurrent ? 2.5 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.3), blurRadius: 8)]
                      : [],
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                      : isCurrent
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCompleted || isCurrent
                      ? AppColors.brandPrimary
                      : ew.textTertiary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
