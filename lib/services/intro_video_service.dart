import 'dart:typed_data';

import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/services/s3_service.dart';
import 'package:toriino_todd/utils/utils.dart';

typedef IntroVideoUploader = Future<Map<String, dynamic>> Function({
  required Uint8List bytes,
  required String folder,
  required String fileName,
  String? contentType,
});

typedef ProfileUpdater = Future<dynamic> Function(Map<String, dynamic> data);

/// Uploads a mentor/teacher intro video and saves it on the profile:
/// 1. S3Service.uploadFile(folder: 'intro-videos') -> public CloudFront URL
/// 2. PUT /users/profile {'introVideoUrl': url} (mirrored to the mentor record)
/// Success is reported only when BOTH steps succeed.
class IntroVideoService {
  static const String folder = 'intro-videos';
  static const Set<String> allowedTypes = {
    'video/mp4',
    'video/quicktime',
    'video/webm',
  };

  final IntroVideoUploader _upload;
  final ProfileUpdater _updateProfile;

  IntroVideoService({IntroVideoUploader? upload, ProfileUpdater? updateProfile})
      : _upload = upload ?? S3Service.uploadFile,
        _updateProfile = updateProfile ?? UserRepo().updateProfile;

  /// Returns `{'success': true, 'url': introVideoUrl}` or
  /// `{'success': false, 'message': reason}`.
  Future<Map<String, dynamic>> uploadAndSave({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final type = S3Service.contentTypeFor(fileName);
    if (type == null || !allowedTypes.contains(type)) {
      return {
        'success': false,
        'message': 'Unsupported video format. Please use MP4, MOV or WebM.',
      };
    }

    final upload = await _upload(
      bytes: bytes,
      folder: folder,
      fileName: fileName,
      contentType: type,
    );
    if (upload['success'] != true) {
      return {
        'success': false,
        'message': upload['message'] ?? 'Upload failed',
      };
    }
    final url = (upload['url'] as String?) ?? '';
    if (!url.startsWith('https://')) {
      return {
        'success': false,
        'message': 'The server did not return a public URL for the video.',
      };
    }

    try {
      await _updateProfile({'introVideoUrl': url});
    } catch (e) {
      return {'success': false, 'message': Utils.errorMessage(e)};
    }
    return {'success': true, 'url': url};
  }
}
