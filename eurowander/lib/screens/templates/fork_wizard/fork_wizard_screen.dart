import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/fork_wizard_provider.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)])),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Consumer<ForkWizardProvider>(
                builder: (context, provider, _) {
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        GestureDetector(onTap: () => Navigator.of(context).pop(), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary))),
                        const SizedBox(width: 16),
                        Expanded(child: Text('Use Template', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                        Text('Step ${provider.currentStep + 1} of ${provider.totalSteps}', style: Theme.of(context).textTheme.bodyMedium),
                      ]),
                    ),
                    LinearProgressIndicator(value: (provider.currentStep + 1) / provider.totalSteps, backgroundColor: Colors.grey.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
                    Expanded(child: PageView(controller: _pageController, physics: const NeverScrollableScrollPhysics(), children: _buildPages(provider))),
                  ]);
                },
              ),
            ),
          ),
        ),
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
