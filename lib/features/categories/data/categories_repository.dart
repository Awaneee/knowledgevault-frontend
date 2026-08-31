import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import 'models/category_create_request.dart';
import 'models/category_response.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.read(apiClientProvider).dio);
});

class CategoriesRepository {
  CategoriesRepository(this._dio);

  final Dio _dio;

  Future<List<CategoryResponse>> listCategories() async {
    try {
      final response = await _dio.get('/categories/');
      return (response.data as List<dynamic>)
          .map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<CategoryResponse> createCategory(String name) async {
    try {
      final response = await _dio.post(
        '/categories/',
        data: CategoryCreateRequest(name: name).toJson(),
      );
      return CategoryResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }
}
