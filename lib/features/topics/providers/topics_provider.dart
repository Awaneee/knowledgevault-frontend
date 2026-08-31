import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/topic_response.dart';
import '../data/topics_repository.dart';

final topicsProvider =
    FutureProvider<List<TopicResponse>>((ref) {
  return ref.read(topicsRepositoryProvider).listTopics();
});
