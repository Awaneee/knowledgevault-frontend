import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import 'models/attachment_response.dart';

final attachmentsRepositoryProvider = Provider<AttachmentsRepository>((ref) {
  return AttachmentsRepository(ref.read(apiClientProvider).dio);
});

class AttachmentsRepository {
  AttachmentsRepository(this._dio);

  final Dio _dio;

  Future<List<AttachmentResponse>> listForNote(int noteId) async {
    try {
      final response = await _dio.get('/notes/$noteId/attachments');
      return (response.data as List<dynamic>)
          .map((e) => AttachmentResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<AttachmentResponse> upload({
    required int noteId,
    required String filePath,
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });
      final response = await _dio.post(
        '/attachments/',
        queryParameters: {'note_id': noteId},
        data: formData,
        onSendProgress: onProgress,
      );
      return AttachmentResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }
}
