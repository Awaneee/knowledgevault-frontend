import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import 'models/topic_response.dart';

final topicsRepositoryProvider = Provider<TopicsRepository>((ref) {
  return TopicsRepository(ref.read(apiClientProvider).dio);
});

class TopicsRepository {
  TopicsRepository(this._dio);

  final Dio _dio;

  Future<List<TopicResponse>> listTopics() async {
    try {
      final response = await _dio.get('/topics/');
      return (response.data as List<dynamic>)
          .map((e) => TopicResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }
}
