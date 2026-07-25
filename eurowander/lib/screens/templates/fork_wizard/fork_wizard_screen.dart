import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../providers/fork_wizard_provider.dart';
import '../../../widgets/widgets.dart';
import 'step_choose_dates.dart';
import 'step_hotel_selection.dart';
import 'step_review_create.dart';

class ForkWizardScreen extends StatefulWidget {
  final String templateId;
  const ForkWizardScreen({super.key, required this.templateId});

  @override
  State<ForkWizardScreen> createState() => _ForkWizardScreenState();
}

class _ForkWizardScreenState extends State<ForkWizardScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ForkWizardProvider>().reset());
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  void _goToPage(int page) {
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Consumer<ForkWizardProvider>(
        builder: (context, provider, _) {
          return Column(children: [
            EWAppBar(
              title: 'Use Template',
              trailing: [
                Text('Step ${provider.currentStep + 1} of ${provider.totalSteps}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            LinearProgressIndicator(value: (provider.currentStep + 1) / provider.totalSteps, backgroundColor: Colors.grey.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary)),
            Expanded(child: PageView(controller: _pageController, physics: const NeverScrollableScrollPhysics(), children: _buildPages(provider))),
          ]);
        },
      ),
    );
  }

  List<Widget> _buildPages(ForkWizardProvider provider) {
    final pages = <Widget>[
      StepChooseDates(templateId: widget.templateId, onDateConfirmed: () => _goToPage(1)),
    ];

    if (provider.forkGuide != null) {
      for (final leg in provider.forkGuide!.legs) {
        pages.add(StepHotelSelection(
          leg: leg,
          onNext: () { provider.nextStep(); _goToPage(provider.currentStep); },
          onBack: () { provider.previousStep(); _goToPage(provider.currentStep); },
        ));
      }
    }

    pages.add(StepReviewCreate(
      templateId: widget.templateId,
      onBack: () { provider.previousStep(); _goToPage(provider.currentStep); },
    ));

    return pages;
  }
}


