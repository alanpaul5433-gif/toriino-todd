import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';

/// Uploads files to S3 via a server-issued pre-signed PUT URL.
///
/// The Lambda (upload-url) scopes the key to the Cognito sub and enforces
/// content-type and size limits.  No AWS credentials are ever stored in the
/// Flutter app.
class S3Service {
  // ── Upload File via pre-signed URL ───────────────────
  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String folder, // 'profiles' | 'courses/thumbnails' | 'lessons'
    required String fileName,
  }) async {
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
      final contentType = _getContentType(fileName);

      // 1. Request a pre-signed PUT URL from the Lambda
      final authHeaders = await AuthInterceptor.getAuthHeaders();
      final uri = Uri.parse(AppUrl.uploadUrl).replace(queryParameters: {
        'folder': folder,
        'contentType': contentType,
        'ext': ext,
      });

      final metaResponse = await http.get(uri, headers: authHeaders);
      if (metaResponse.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to get upload URL: ${metaResponse.statusCode}',
        };
      }

      final meta = jsonDecode(metaResponse.body) as Map<String, dynamic>;
      final uploadUrl = meta['uploadUrl'] as String?;
      final publicUrl = meta['publicUrl'] as String?;
      final key = meta['key'] as String?;

      if (uploadUrl == null) {
        return {'success': false, 'message': 'No uploadUrl in response'};
      }

      // 2. PUT the file bytes directly to S3 using the pre-signed URL
      final bytes = await file.readAsBytes();
      final putResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 204) {
        return {'success': true, 'url': publicUrl ?? '', 'key': key ?? ''};
      } else {
        return {
          'success': false,
          'message': 'S3 PUT failed: ${putResponse.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Convenience wrappers ─────────────────────────────
  static Future<Map<String, dynamic>> uploadProfilePicture({
    required File imageFile,
    required String userId,
  }) {
    final ext = imageFile.path.split('.').last;
    return uploadFile(
      file: imageFile,
      folder: 'profiles',
      fileName: '$userId.$ext',
    );
  }

  static Future<Map<String, dynamic>> uploadCourseThumbnail({
    required File imageFile,
    required String courseId,
  }) {
    final ext = imageFile.path.split('.').last;
    return uploadFile(
      file: imageFile,
      folder: 'courses/thumbnails',
      fileName: '$courseId.$ext',
    );
  }

  // ── Helpers ──────────────────────────────────────────
  static String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
