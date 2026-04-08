import 'dart:typed_data';

import 'package:http/http.dart' as http;

class UploadRepo {
  /// Uploads bytes directly to S3 using a presigned URL.
  /// [presignedUrl] - The presigned PUT URL from the backend.
  /// [bytes] - File bytes to upload (works on all platforms including web).
  /// [contentType] - MIME type (e.g., 'image/jpeg', 'video/mp4').
  Future<bool> uploadToS3({
    required String presignedUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final response = await http.put(
      Uri.parse(presignedUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    return response.statusCode == 200;
  }
}
