class AttachmentResponse {
  const AttachmentResponse({
    required this.id,
    required this.filename,
    required this.filePath,
    required this.fileType,
    required this.noteId,
    required this.createdAt,
  });

  final int id;
  final String filename;
  final String filePath;
  final String fileType;
  final int noteId;
  final DateTime createdAt;

  factory AttachmentResponse.fromJson(Map<String, dynamic> json) =>
      AttachmentResponse(
        id: json['id'] as int,
        filename: json['filename'] as String,
        filePath: json['file_path'] as String,
        fileType: json['file_type'] as String,
        noteId: json['note_id'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
