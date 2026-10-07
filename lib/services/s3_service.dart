import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';

/// The single upload path of the app: every file goes to S3 through a
/// server-issued pre-signed PUT URL.
///
/// 1. GET {base}/upload-url?folder=&contentType=&ext=
///    -> {uploadUrl, key, expiresIn, publicUrl?}
///    `publicUrl` (a CloudFront https URL) is present ONLY for the public
///    folders: profiles, courses/thumbnails, intro-videos. Private folders
///    (lessons, course-materials) return only the S3 `key`, which is what the
///    app must store; the media is later served via pre-signed GET URLs.
/// 2. HTTP PUT the bytes to uploadUrl with the same Content-Type.
///
/// The Lambda (upload-url) scopes the key to the Cognito sub and enforces
/// folder, content-type and size limits. No AWS credentials live in the app.
class S3Service {
  /// Folders accepted by the upload-url Lambda.
  static const Set<String> allowedFolders = {
    'profiles',
    'courses/thumbnails',
    'lessons',
    'course-materials',
    'intro-videos',
  };

  /// Content types accepted by the upload-url Lambda.
  static const Set<String> allowedContentTypes = {
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'video/mp4',
    'video/quicktime',
    'video/webm',
    'application/pdf',
    'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  };

  /// Uploads [bytes] to [folder] as [fileName].
  ///
  /// Returns `{'success': true, 'key': key, 'url': publicUrl ?? ''}` on
  /// success or `{'success': false, 'message': reason}` on any failure.
  /// `url` is empty for private folders — no S3 URL is ever invented.
  static Future<Map<String, dynamic>> uploadFile({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    String? contentType,
  }) async {
    try {
      if (!allowedFolders.contains(folder)) {
        return {'success': false, 'message': 'Unsupported upload folder: $folder'};
      }
      final type = contentType ?? contentTypeFor(fileName);
      if (type == null || !allowedContentTypes.contains(type)) {
        return {
          'success': false,
          'message': 'This file type is not supported for upload.',
        };
      }
      if (bytes.isEmpty) {
        return {'success': false, 'message': 'The selected file is empty.'};
      }
      final ext = _extension(fileName) ?? _defaultExt(type);

      // 1. Request a pre-signed PUT URL from the Lambda
      final authHeaders = await AuthInterceptor.getAuthHeaders();
      final uri = Uri.parse(AppUrl.uploadUrl).replace(queryParameters: {
        'folder': folder,
        'contentType': type,
        'ext': ext,
      });

      final metaResponse = await http
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 15));
      if (metaResponse.statusCode < 200 || metaResponse.statusCode >= 300) {
        return {
          'success': false,
          'message': _serverMessage(metaResponse.body) ??
              'Could not get an upload URL (${metaResponse.statusCode})',
        };
      }

      final meta = jsonDecode(metaResponse.body) as Map<String, dynamic>;
      final uploadUrl = meta['uploadUrl'] as String?;
      final publicUrl = meta['publicUrl'] as String?;
      final key = meta['key'] as String?;
      if (uploadUrl == null || uploadUrl.isEmpty) {
        return {'success': false, 'message': 'Upload URL missing from server response'};
      }
      if (key == null || key.isEmpty) {
        return {'success': false, 'message': 'Upload key missing from server response'};
      }

      // 2. PUT the bytes directly to S3 with the same Content-Type
      final putResponse = await http
          .put(
            Uri.parse(uploadUrl),
            headers: {'Content-Type': type},
            body: bytes,
          )
          .timeout(const Duration(minutes: 10));

      if (putResponse.statusCode >= 200 && putResponse.statusCode < 300) {
        return {'success': true, 'key': key, 'url': publicUrl ?? ''};
      }
      return {
        'success': false,
        'message': 'Upload to storage failed (${putResponse.statusCode})',
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Upload timed out. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Helpers ──────────────────────────────────────────
  /// MIME type for [fileName] based on its extension, or null if the
  /// extension is not one the backend accepts.
  static String? contentTypeFor(String fileName) {
    switch (_extension(fileName)) {
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
      case 'm4v':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default:
        return null;
    }
  }

  static String? _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return null;
    return fileName.substring(dot + 1).toLowerCase();
  }

  static String _defaultExt(String contentType) {
    switch (contentType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'video/mp4':
        return 'mp4';
      case 'video/quicktime':
        return 'mov';
      case 'video/webm':
        return 'webm';
      case 'application/pdf':
        return 'pdf';
      case 'text/plain':
        return 'txt';
      case 'application/msword':
        return 'doc';
      case 'application/vnd.ms-powerpoint':
        return 'ppt';
      case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        return 'pptx';
      default:
        return 'docx';
    }
  }

  static String? _serverMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final msg = decoded['error'] ?? decoded['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return null;
  }
}
