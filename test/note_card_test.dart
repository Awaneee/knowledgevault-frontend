import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledgevault/features/notes/data/models/note_response.dart';
import 'package:knowledgevault/features/notes/ui/widgets/note_card.dart';

void main() {
  final note = NoteResponse(
    id: 1,
    title: 'Test note title',
    content: 'Some content that should appear as a snippet.',
    userId: 42,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  testWidgets('NoteCard renders title and snippet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteCard(note: note, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Test note title'), findsOneWidget);
    expect(find.textContaining('Some content'), findsOneWidget);
  });

  testWidgets('NoteCard calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteCard(note: note, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(NoteCard));
    expect(tapped, isTrue);
  });

  testWidgets('NoteCard flags a note that has not synced yet', (tester) async {
    final pending = NoteResponse(
      id: -3,
      title: 'Written offline',
      userId: 42,
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NoteCard(note: pending, onTap: () {})),
      ),
    );
    expect(find.text('Waiting to sync'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NoteCard(note: note, onTap: () {})),
      ),
    );
    expect(find.text('Waiting to sync'), findsNothing);
  });

  testWidgets('NoteCard shows category chip when categoryName provided',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteCard(
              note: note, onTap: () {}, categoryName: 'Work'),
        ),
      ),
    );

    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('NoteCardSkeleton renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NoteCardSkeleton()),
      ),
    );
    expect(find.byType(NoteCardSkeleton), findsOneWidget);
  });
}
