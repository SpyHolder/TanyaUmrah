import 'package:flutter/material.dart';

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
            children: [
              Icon(Icons.lightbulb_outline, size: 13, color: Colors.amber.shade800),
              const SizedBox(width: 4),
              Text(
                'Pertanyaan Terkait:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
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
              elevation: 0.5,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              side: BorderSide(color: Colors.amber.shade200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              label: Text(
                q,
                style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
              ),
              onPressed: () => onSelect(q),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
