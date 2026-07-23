import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/template.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/template_provider.dart';
import 'step_basic_info.dart';
import 'step_define_route.dart';
import 'step_leg_recommendations.dart';
import 'step_review.dart';

class CreateTemplateScreen extends StatefulWidget {
  final String? editTemplateId;

  const CreateTemplateScreen({super.key, this.editTemplateId});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Basic Info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  List<String> _tags = [];
  String _currency = 'EUR';

  // Step 2: Route
  List<CreateTemplateLeg> _legs = [];

  bool get _isEditing => widget.editTemplateId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingTemplate();
    }
  }

  Future<void> _loadExistingTemplate() async {
    final provider = context.read<TemplateProvider>();
    await provider.loadTemplateDetail(widget.editTemplateId!);
    final template = provider.currentTemplate;
    if (template != null && mounted) {
      setState(() {
        _titleController.text = template.title;
        _descriptionController.text = template.description;
        _coverUrlController.text = template.coverPhotoUrl;
        _budgetMinController.text =
            template.estimatedBudgetMin?.toInt().toString() ?? '';
        _budgetMaxController.text =
            template.estimatedBudgetMax?.toInt().toString() ?? '';
        _tags = List.from(template.tags);
        _currency = template.currency;
        _legs = template.legs
            .map((l) => CreateTemplateLeg(
                  order: l.order,
                  city: l.city,
                  country: l.country,
                  days: l.days,
                  flightRecommendation: l.flightRecommendation,
                  transportRecommendation: l.transportRecommendation,
                  hotelRecommendations: l.hotelRecommendations,
                  playlistId: l.playlistId,
                  restaurantIds: l.restaurantIds,
                  authorNotes: l.authorNotes,
                ))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAsDraft() async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final provider = context.read<TemplateProvider>();

    if (_isEditing) {
      await provider.updateTemplate(
        templateId: widget.editTemplateId!,
        userId: userId,
        request: UpdateTemplateRequest(
          title: _titleController.text,
          description: _descriptionController.text,
          coverPhotoUrl: _coverUrlController.text,
          tags: _tags,
          legs: _legs,
          estimatedBudgetMin: double.tryParse(_budgetMinController.text),
          estimatedBudgetMax: double.tryParse(_budgetMaxController.text),
          currency: _currency,
        ),
      );
    } else {
      await provider.createTemplate(CreateTemplateRequest(
        authorId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        coverPhotoUrl: _coverUrlController.text,
        tags: _tags,
        legs: _legs,
        estimatedBudgetMin: double.tryParse(_budgetMinController.text),
        estimatedBudgetMax: double.tryParse(_budgetMaxController.text),
        currency: _currency,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template saved as draft')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _publish() async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final provider = context.read<TemplateProvider>();

    // Save first
    TemplateResponse? result;
    if (_isEditing) {
      result = await provider.updateTemplate(
        templateId: widget.editTemplateId!,
        userId: userId,
        request: UpdateTemplateRequest(
          title: _titleController.text,
          description: _descriptionController.text,
          coverPhotoUrl: _coverUrlController.text,
          tags: _tags,
          legs: _legs,
          estimatedBudgetMin: double.tryParse(_budgetMinController.text),
          estimatedBudgetMax: double.tryParse(_budgetMaxController.text),
          currency: _currency,
        ),
      );
    } else {
      result = await provider.createTemplate(CreateTemplateRequest(
        authorId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        coverPhotoUrl: _coverUrlController.text,
        tags: _tags,
        legs: _legs,
        estimatedBudgetMin: double.tryParse(_budgetMinController.text),
        estimatedBudgetMax: double.tryParse(_budgetMaxController.text),
        currency: _currency,
      ));
    }

    if (result != null) {
      await provider.publishTemplate(
        templateId: result.id,
        userId: userId,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template published!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Template' : 'Create Template',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Step ${_currentStep + 1} of 4',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StepBasicInfo(
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  coverUrlController: _coverUrlController,
                  budgetMinController: _budgetMinController,
                  budgetMaxController: _budgetMaxController,
                  tags: _tags,
                  currency: _currency,
                  onTagsChanged: (tags) => setState(() => _tags = tags),
                  onCurrencyChanged: (c) => setState(() => _currency = c),
                  onNext: _nextStep,
                ),
                StepDefineRoute(
                  legs: _legs,
                  onLegsChanged: (legs) => setState(() => _legs = legs),
                  onNext: _nextStep,
                  onBack: _previousStep,
                ),
                StepLegRecommendations(
                  legs: _legs,
                  onLegsChanged: (legs) => setState(() => _legs = legs),
                  onNext: _nextStep,
                  onBack: _previousStep,
                ),
                StepReview(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  coverPhotoUrl: _coverUrlController.text,
                  tags: _tags,
                  legs: _legs,
                  currency: _currency,
                  budgetMin: double.tryParse(_budgetMinController.text),
                  budgetMax: double.tryParse(_budgetMaxController.text),
                  onSaveDraft: _saveAsDraft,
                  onPublish: _publish,
                  onBack: _previousStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
