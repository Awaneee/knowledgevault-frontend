import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledgevault/features/ask/data/ask_repository.dart';

void main() {
  final repo = AskRepository(Dio());

  String tokenOf(String frame) =>
      (repo.parseFrame(frame) as AskToken).text;

  group('AskRepository.parseFrame', () {
    test('decodes a JSON-encoded token, keeping whitespace', () {
      expect(tokenOf('data: " on your notes"'), ' on your notes');
      expect(tokenOf(r'data: ":\n\n1. "'), ':\n\n1. ');
    });

    test('[DONE] ends the stream', () {
      expect(repo.parseFrame('data: [DONE]'), isNull);
    });

    test('blank frame is an empty token', () {
      expect((repo.parseFrame('   ') as AskToken).text, isEmpty);
    });

    test('event: error throws with the message', () {
      expect(
        () => repo.parseFrame('event: error\ndata: "interrupted"'),
        throwsA(isA<AskStreamException>()
            .having((e) => e.message, 'message', 'interrupted')),
      );
    });

    test('event: citations decodes the citation list', () {
      final event = repo.parseFrame(
        'event: citations\n'
        'data: [{"ref":1,"note_id":7,"note_title":"Redis","chunk_id":null,'
        '"snippet":"fast"},{"ref":2,"note_id":8,"note_title":"PG",'
        '"chunk_id":80,"snippet":"durable"}]',
      ) as AskCitations;

      expect(event.citations.map((c) => c.ref), [1, 2]);
      expect(event.citations.first.noteTitle, 'Redis');
      expect(event.citations.first.chunkId, isNull);
      expect(event.citations.last.chunkId, 80);
    });

    test('malformed citations never break the answer', () {
      final bad = repo.parseFrame('event: citations\ndata: not json')
          as AskCitations;
      expect(bad.citations, isEmpty);

      final wrongShape = repo.parseFrame(
        'event: citations\ndata: [{"ref":"x"}]',
      ) as AskCitations;
      expect(wrongShape.citations, isEmpty);
    });
  });
}
