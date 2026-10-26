import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Display name, icon and card colour for an AI intent type.
String intentLabel(String type) => switch (type) {
  'todo' => 'Tasks',
  'study' => 'Study',
  'question' => 'Questions',
  'communication' => 'Messages',
  'reference' => 'Reference',
  'idea' => 'Ideas',
  'reminder' => 'Reminders',
  'event' => 'Events',
  _ => 'General',
};

IconData intentIcon(String type) => switch (type) {
  'todo' => Icons.check_circle_outline,
  'study' => Icons.school_outlined,
  'question' => Icons.help_outline,
  'communication' => Icons.chat_bubble_outline,
  'reference' => Icons.bookmark_outline,
  'idea' => Icons.lightbulb_outline,
  'reminder' => Icons.alarm_outlined,
  'event' => Icons.event_outlined,
  _ => Icons.notes_outlined,
};

Pastel intentPastel(String type) => switch (type) {
  'todo' => Pastel.sage,
  'study' => Pastel.lilac,
  'question' => Pastel.periwinkle,
  'communication' => Pastel.sky,
  'reference' => Pastel.butter,
  'idea' => Pastel.rose,
  'reminder' => Pastel.peach,
  'event' => Pastel.rose,
  _ => Pastel.sage,
};
