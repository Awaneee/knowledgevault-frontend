import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

extension PlatformFileMultipart on PlatformFile {
  /// Browsers expose no file path, only the bytes read at pick time (pick
  /// with `withData: kIsWeb`), so web uploads are sent from memory.
  bool get isReadable => bytes != null || path != null;

  Future<MultipartFile> toMultipart() async => bytes != null
      ? MultipartFile.fromBytes(bytes!, filename: name)
      : MultipartFile.fromFile(path!, filename: name);
}
