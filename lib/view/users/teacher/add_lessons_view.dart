import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/data/app_exception.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/course/lesson_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/student_view/course_enroll_flow.dart';
import 'package:toriino_todd/view/users/student_view/lesson_video_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// One lesson row of a course. Lesson media is private: the video/material
/// URL is fetched from GET /courses/{courseId}/lessons/{lessonId}/media right
/// before playing/opening (pre-signed, valid 300 s) and never cached.
class CourseContentWidget extends StatefulWidget {
  final LessonModel? lesson;
  final CourseModel? course;
  const CourseContentWidget({super.key, this.lesson, this.course});

  @override
  State<CourseContentWidget> createState() => _CourseContentWidgetState();
}

class _CourseContentWidgetState extends State<CourseContentWidget> {
  bool _isExpanded = false;
  bool _openingMaterial = false;

  String get _courseId =>
      widget.lesson?.courseId ?? widget.course?.courseId ?? '';

  void _playVideo() {
    final lesson = widget.lesson;
    if (lesson == null || !lesson.hasVideo) {
      Utils.toastMassage('This lesson has no video.');
      return;
    }
    // Private video -> fetched from the media endpoint inside the player.
    // Legacy lesson without videoKey -> play its plain videoUrl.
    final usesKey = lesson.hasVideoKey && (lesson.lessonId ?? '').isNotEmpty;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonVideoView(
          title: lesson.title ?? 'Lesson',
          courseId: usesKey ? _courseId : null,
          lessonId: usesKey ? lesson.lessonId : null,
          videoUrl: usesKey ? null : lesson.videoUrl,
          course: widget.course,
        ),
      ),
    );
  }

  Future<void> _openMaterial() async {
    final lesson = widget.lesson;
    if (lesson == null || !lesson.hasMaterial || _openingMaterial) return;

    // Legacy lesson: a plain materialUrl stored before media became private.
    if (!lesson.hasMaterialKey) {
      await _openExternal(lesson.materialUrl!, expires: false);
      return;
    }

    setState(() => _openingMaterial = true);
    try {
      // Always fetch a fresh pre-signed link right before opening it.
      final res =
          await CourseRepo().getLessonMedia(_courseId, lesson.lessonId ?? '');
      final media = LessonMediaModel.fromJson(
          res is Map<String, dynamic> ? res : <String, dynamic>{});
      if (!mounted) return;
      final url = media.materialUrl;
      if (url == null) {
        Utils.toastMassage('This lesson has no material.');
      } else {
        await _openExternal(url, expires: true, expiresIn: media.expiresIn);
      }
    } on PaymentRequiredException {
      if (mounted) await showEnrollRequiredDialog(context, widget.course);
    } catch (e) {
      Utils.toastMassage(Utils.errorMessage(e));
    } finally {
      if (mounted) setState(() => _openingMaterial = false);
    }
  }

  /// Link-type lesson: opens its external https page.
  Future<void> _openLink() async {
    final link = widget.lesson?.url;
    if (link == null || link.isEmpty) return;
    await _openExternal(link, expires: false);
  }

  /// Opens [url] in an external app/browser. If that is not possible, shows
  /// an error and falls back to the copy-link dialog.
  Future<void> _openExternal(String url,
      {required bool expires, int expiresIn = 300}) async {
    final uri = Uri.tryParse(url);
    var opened = false;
    if (uri != null && uri.hasScheme) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (opened || !mounted) return;
    Utils.toastMassage('Could not open the link on this device.');
    _showMaterialLink(url, expires: expires, expiresIn: expiresIn);
  }

  /// Fallback when no app can open the link: the (possibly short-lived) link
  /// is shown for the user to copy and open.
  void _showMaterialLink(String url, {required bool expires, int expiresIn = 300}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.primaryColor,
        title: Text(widget.lesson?.title ?? 'Lesson material',
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expires)
              Text(
                'This download link is valid for ${(expiresIn / 60).ceil()} minute(s).',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            const SizedBox(height: 8),
            SelectableText(url,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              Utils.toastMassage('Link copied');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Copy link', style: TextStyle(color: AppColor.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final lesson = widget.lesson;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        key: UniqueKey(),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        leading: SvgPicture.asset("assets/icons/Frame menu.svg"),
        title: Text(
          lesson?.title ?? 'Lesson',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * 12,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.grey,
        ),
        children: [
          if ((lesson?.description ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  lesson!.description!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          // Video section: tapping opens the player, which fetches a fresh
          // pre-signed URL.
          if (lesson?.hasVideo ?? false)
            GestureDetector(
              onTap: _playVideo,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(12),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          // Material section
          if (lesson?.hasMaterial ?? false)
            GestureDetector(
              onTap: _openMaterial,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        color: Colors.red, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Lesson material',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    _openingMaterial
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.open_in_new, color: Colors.blue),
                  ],
                ),
              ),
            ),
          // Link-type lesson: an external https page.
          if (lesson?.hasLink ?? false)
            GestureDetector(
              onTap: _openLink,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link, color: Colors.blue, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Open lesson link',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.open_in_new, color: Colors.blue),
                  ],
                ),
              ),
            ),
          if (!(lesson?.hasVideo ?? false) &&
              !(lesson?.hasMaterial ?? false) &&
              !(lesson?.hasLink ?? false))
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No media for this lesson.',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
