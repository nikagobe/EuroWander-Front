import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fork_wizard_provider.dart';
import 'step_choose_dates.dart';
import 'step_leg_content.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForkWizardProvider>().reset();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Consumer<ForkWizardProvider>(
          builder: (_, provider, __) {
            return Text(
              'Build Your Trip',
              style: Theme.of(context).textTheme.titleLarge,
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<ForkWizardProvider>(
            builder: (_, provider, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Step ${provider.currentStep + 1} of ${provider.totalSteps}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ForkWizardProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: (provider.currentStep + 1) / provider.totalSteps,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _buildPages(provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPages(ForkWizardProvider provider) {
    final pages = <Widget>[
      StepChooseDates(
        templateId: widget.templateId,
        onDateConfirmed: () {
          _goToPage(1);
        },
      ),
    ];

    // One page per leg
    if (provider.forkGuide != null) {
      for (final leg in provider.forkGuide!.legs) {
        pages.add(StepLegContent(
          leg: leg,
          onNext: () {
            provider.nextStep();
            _goToPage(provider.currentStep);
          },
          onBack: () {
            provider.previousStep();
            _goToPage(provider.currentStep);
          },
        ));
      }
    }

    // Review page
    pages.add(StepReviewCreate(
      templateId: widget.templateId,
      onBack: () {
        provider.previousStep();
        _goToPage(provider.currentStep);
      },
    ));

    return pages;
  }
}
