import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fork_wizard_provider.dart';

class StepChooseDates extends StatelessWidget {
  final String templateId;
  final VoidCallback onDateConfirmed;

  const StepChooseDates({
    super.key,
    required this.templateId,
    required this.onDateConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ForkWizardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'When do you want to start?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (provider.forkGuide != null)
                Text(
                  'Based on: "${provider.forkGuide!.title}"',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 24),

              // Date picker button
              GestureDetector(
                onTap: () => _selectDate(context, provider),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: provider.startDate != null
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: provider.startDate != null
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        provider.startDate != null
                            ? DateFormat('MMMM d, yyyy')
                                .format(provider.startDate!)
                            : 'Select start date',
                        style: TextStyle(
                          fontSize: 16,
                          color: provider.startDate != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Trip duration preview
              if (provider.startDate != null && provider.forkGuide != null) ...[
                _buildDatePreview(context, provider),
              ],

              const SizedBox(height: 32),

              // Next button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.startDate != null
                      ? () => _confirmDate(context, provider)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Next →',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              if (provider.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatePreview(BuildContext context, ForkWizardProvider provider) {
    final start = provider.startDate!;
    final totalDays = provider.forkGuide!.totalDays;
    final end = start.add(Duration(days: totalDays));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your trip will be:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)} ($totalDays days)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ...provider.forkGuide!.legs.map((leg) {
            final legStart =
                start.add(Duration(days: _daysBeforeLeg(provider, leg.order)));
            final legEnd = legStart.add(Duration(days: leg.days));
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Leg ${leg.order}: ${leg.city} — '
                '${DateFormat('MMM d').format(legStart)}–${DateFormat('MMM d').format(legEnd)} '
                '(${leg.days} days)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  int _daysBeforeLeg(ForkWizardProvider provider, int legOrder) {
    int days = 0;
    for (final leg in provider.forkGuide!.legs) {
      if (leg.order >= legOrder) break;
      days += leg.days;
    }
    return days;
  }

  Future<void> _selectDate(
      BuildContext context, ForkWizardProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.startDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.setStartDate(picked);
      // If we don't have the fork guide yet, fetch it now for the preview
      if (provider.forkGuide == null) {
        final userId = context.read<AuthProvider>().user?.id ?? '';
        final dateStr = DateFormat('yyyy-MM-dd').format(picked);
        await provider.initializeFork(
          templateId: templateId,
          userId: userId,
          startDate: dateStr,
        );
      }
    }
  }

  Future<void> _confirmDate(
      BuildContext context, ForkWizardProvider provider) async {
    if (provider.forkGuide == null) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      final dateStr = DateFormat('yyyy-MM-dd').format(provider.startDate!);
      await provider.initializeFork(
        templateId: templateId,
        userId: userId,
        startDate: dateStr,
      );
    }
    if (provider.forkGuide != null) {
      provider.nextStep();
      onDateConfirmed();
    }
  }
}
