import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/config/aws_config.dart';

class S3Service {
  static const String _bucket = AWSConfig.s3Bucket;
  static const String _region = AWSConfig.s3Region;
  static String get _baseUrl =>
      'https://$_bucket.s3.$_region.amazonaws.com';

  // ── Upload File ──────────────────────────────────────
  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String folder, // e.g. 'profiles', 'courses', 'thumbnails'
    required String fileName,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final key = '$folder/$fileName';
      final url = '$_baseUrl/$key';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': _getContentType(fileName),
          'x-amz-acl': 'public-read',
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'url': url,
          'key': key,
        };
      } else {
        return {
          'success': false,
          'message': 'Upload failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Upload Profile Picture ───────────────────────────
  static Future<Map<String, dynamic>> uploadProfilePicture({
    required File imageFile,
    required String userId,
  }) async {
    final ext = imageFile.path.split('.').last;
    return uploadFile(
      file: imageFile,
      folder: 'profiles',
      fileName: '$userId.$ext',
    );
  }

  // ── Upload Course Thumbnail ──────────────────────────
  static Future<Map<String, dynamic>> uploadCourseThumbnail({
    required File imageFile,
    required String courseId,
  }) async {
    final ext = imageFile.path.split('.').last;
    return uploadFile(
      file: imageFile,
      folder: 'courses/thumbnails',
      fileName: '$courseId.$ext',
    );
  }

  // ── Get Public URL ───────────────────────────────────
  static String getPublicUrl(String key) {
    return '$_baseUrl/$key';
  }

  // ── Delete File ──────────────────────────────────────
  static Future<bool> deleteFile(String key) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$key'),
      );
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ── Helper ───────────────────────────────────────────
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

  // ── Generate Unique File Name ────────────────────────
  static String generateFileName(String userId, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = md5.convert(utf8.encode('$userId$timestamp')).toString();
    return '$hash.$extension';
  }
}
