import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/local_cache.dart';
import '../data/categories_repository.dart';
import '../data/models/category_response.dart';

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryResponse>>(
        CategoriesNotifier.new);

class CategoriesNotifier extends AsyncNotifier<List<CategoryResponse>> {
  @override
  Future<List<CategoryResponse>> build() async {
    final db = ref.read(appDatabaseProvider);

    final cachedRows = await db.getCachedCategoryRows();
    if (cachedRows.isNotEmpty) {
      state = AsyncData(_rowsToCategories(cachedRows));
    }

    final categories =
        await ref.read(categoriesRepositoryProvider).listCategories();
    await db.cacheCategoryRows(
        categories.map((c) => {'id': c.id, 'name': c.name}).toList());
    return categories;
  }

  Future<CategoryResponse> createCategory(String name) async {
    final category =
        await ref.read(categoriesRepositoryProvider).createCategory(name);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, category]);
    return category;
  }

  static List<CategoryResponse> _rowsToCategories(
          List<Map<String, dynamic>> rows) =>
      rows
          .map((r) => CategoryResponse(
                id: r['id'] as int,
                name: r['name'] as String,
              ))
          .toList();
}
