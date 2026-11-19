import 'package:flutter/material.dart';
import '../core/constants.dart';

class SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSelect;

  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 13.5,
                color: AppConstants.warningAmber,
              ),
              SizedBox(width: 4),
              Text(
                'Pertanyaan Terkait:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.map((q) => ActionChip(
              backgroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
              side: const BorderSide(color: AppConstants.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              label: Text(
                q,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => onSelect(q),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
