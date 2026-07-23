import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StepBasicInfo extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController coverUrlController;
  final TextEditingController budgetMinController;
  final TextEditingController budgetMaxController;
  final List<String> tags;
  final String currency;
  final ValueChanged<List<String>> onTagsChanged;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onNext;

  const StepBasicInfo({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.coverUrlController,
    required this.budgetMinController,
    required this.budgetMaxController,
    required this.tags,
    required this.currency,
    required this.onTagsChanged,
    required this.onCurrencyChanged,
    required this.onNext,
  });

  @override
  State<StepBasicInfo> createState() => _StepBasicInfoState();
}

class _StepBasicInfoState extends State<StepBasicInfo> {
  static const _availableTags = [
    'budget',
    'luxury',
    'backpacking',
    'romantic',
    'family',
    '7-day',
    '14-day',
    'weekend',
    'adventure',
    'cultural',
    'beach',
    'city-break',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text('Title *', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: widget.titleController,
            decoration: _inputDecoration('e.g. 7 Days in Spain'),
          ),
          const SizedBox(height: 20),

          // Description
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: widget.descriptionController,
            maxLines: 3,
            decoration: _inputDecoration('Describe your trip template...'),
          ),
          const SizedBox(height: 20),

          // Cover photo URL
          Text('Cover Photo URL',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: widget.coverUrlController,
            decoration: _inputDecoration('https://...'),
          ),
          const SizedBox(height: 20),

          // Tags
          Text('Tags (tap to add)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = widget.tags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  final newTags = List<String>.from(widget.tags);
                  if (selected) {
                    newTags.add(tag);
                  } else {
                    newTags.remove(tag);
                  }
                  widget.onTagsChanged(newTags);
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontSize: 12,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Budget
          Text('Estimated Budget',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              // Currency
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.currency,
                    items: ['EUR', 'USD', 'GBP', 'GEL']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) widget.onCurrencyChanged(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.budgetMinController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Min'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('–'),
              ),
              Expanded(
                child: TextField(
                  controller: widget.budgetMaxController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Max'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Next button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.titleController.text.isNotEmpty
                  ? widget.onNext
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              ),
              child: const Text('Next →',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
