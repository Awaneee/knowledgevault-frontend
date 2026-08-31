import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/intents_repository.dart';
import '../data/models/intent_category_response.dart';

final intentsProvider =
    FutureProvider<List<IntentCategoryResponse>>((ref) {
  return ref.read(intentsRepositoryProvider).listCategories();
});
