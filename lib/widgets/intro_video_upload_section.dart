import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/intro_video_service.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/widgets/intro_video_tile.dart';

/// Pick -> upload (S3 'intro-videos') -> save `introVideoUrl` on the profile.
/// Shared by the mentor/teacher intro-video screens. Success is shown only
/// after both the upload and the profile update succeed.
class IntroVideoUploadSection extends StatefulWidget {
  final ValueChanged<String>? onSaved;
  final ValueChanged<bool>? onBusyChanged;

  /// Currently saved intro video, if known (shown with a play action).
  final String? currentUrl;

  const IntroVideoUploadSection({
    super.key,
    this.onSaved,
    this.onBusyChanged,
    this.currentUrl,
  });

  @override
  State<IntroVideoUploadSection> createState() =>
      _IntroVideoUploadSectionState();
}

class _IntroVideoUploadSectionState extends State<IntroVideoUploadSection> {
  final _service = IntroVideoService();
  bool _busy = false;
  String? _fileName;
  String? _savedUrl;
  String? _error;

  void _setBusy(bool v) {
    setState(() => _busy = v);
    widget.onBusyChanged?.call(v);
  }

  Future<void> _pickAndUpload() async {
    if (_busy) return;
    // Same picker approach as AddLessonView: file_picker, video type, bytes
    // loaded in memory for the pre-signed PUT.
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Could not read the selected file.');
      return;
    }

    setState(() {
      _fileName = file.name;
      _error = null;
    });
    _setBusy(true);
    final result =
        await _service.uploadAndSave(bytes: bytes, fileName: file.name);
    if (!mounted) return;
    _setBusy(false);

    if (result['success'] == true) {
      final url = result['url'] as String;
      setState(() => _savedUrl = url);
      Utils.toastMassage('Intro video saved');
      widget.onSaved?.call(url);
    } else {
      final msg = (result['message'] as String?) ?? 'Upload failed';
      setState(() => _error = msg);
      Utils.toastMassage(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final shownUrl = _savedUrl ?? widget.currentUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _busy ? null : _pickAndUpload,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadiusDirectional.circular(28),
              color: AppColor.white.withValues(alpha: 0.08),
            ),
            child: Padding(
              padding: Responsive.padding(top: 7, bottom: 7),
              child: Column(
                children: [
                  if (_busy)
                    const CircularProgressIndicator(color: AppColor.red)
                  else if (_savedUrl != null)
                    const Icon(Icons.check_circle,
                        color: Colors.greenAccent, size: 48)
                  else
                    SvgPicture.asset("assets/icons/upload-circle.svg"),
                  const SizedBox(height: 8),
                  Text(
                    _busy
                        ? 'Uploading ${_fileName ?? 'video'}…'
                        : _savedUrl != null
                            ? 'Intro video saved${_fileName != null ? ' ($_fileName)' : ''}'
                            : (_fileName ?? 'Formats: MP4, MOV, WebM'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: AppColor.white,
                      fontSize: Responsive.textScaleFactor * 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: Colors.redAccent,
                          fontSize: Responsive.textScaleFactor * 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: Responsive.h(1)),
        GestureDetector(
          onTap: _busy ? null : _pickAndUpload,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadiusDirectional.circular(28),
              color: AppColor.primaryColor,
              border: Border.all(color: AppColor.red),
            ),
            child: Padding(
              padding: Responsive.padding(top: 2, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset("assets/icons/IC_cross.svg"),
                  SizedBox(width: Responsive.w(2)),
                  Text(
                    shownUrl != null ? 'Replace video' : 'Upload a video',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (shownUrl != null && !_busy) ...[
          SizedBox(height: Responsive.h(1)),
          TextButton.icon(
            onPressed: () => openIntroVideo(context, shownUrl),
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
            label: Text('Play intro video',
                style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ],
    );
  }
}
