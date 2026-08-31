import 'package:flutter/material.dart';

import '../../data/models/intent_category_response.dart';

class IntentCategoryTile extends StatelessWidget {
  const IntentCategoryTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  final IntentCategoryResponse category;
  final VoidCallback onTap;

  static IconData _iconFor(String intentType) => switch (intentType) {
        'communication' => Icons.mail_outline,
        'todo' => Icons.check_circle_outline,
        'study' => Icons.school_outlined,
        'reminder' => Icons.alarm_outlined,
        'idea' => Icons.lightbulb_outline,
        'reference' => Icons.bookmark_outline,
        'question' => Icons.help_outline,
        'event' => Icons.event_outlined,
        _ => Icons.label_outline,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconFor(category.intentType)),
      title: Text(category.name),
      subtitle: category.description != null
          ? Text(
              category.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Chip(
        label: Text('${category.noteCount}'),
        padding: EdgeInsets.zero,
      ),
      onTap: onTap,
    );
  }
}
