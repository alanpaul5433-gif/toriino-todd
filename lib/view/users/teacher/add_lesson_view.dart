import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/s3_service.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/teacher/teacher_home_view.dart';
import 'package:toriino_todd/viewmodel/controller/teacher/teacher_course_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Material type labels ────────────────────────────────────────────────────
const _kMaterialTypes = ['Video', 'PDF', 'Quiz', 'Link'];

// ── Per-lesson data ─────────────────────────────────────────────────────────
class _LessonEntry {
  String title;
  String description;
  String duration;
  int order;
  String materialType; // Video | PDF | Quiz | Link
  Uint8List? fileBytes;
  String? fileName;
  int? fileSize;
  String? linkUrl;
  // S3 key returned by S3Service.uploadFile. Lesson media is private, so the
  // key (not a URL) is stored as videoKey / materialKey.
  String? uploadedKey;

  _LessonEntry({
    required this.title,
    this.description = '',
    this.duration = '',
    this.order = 0,
    this.materialType = 'Video',
    this.fileBytes,
    this.fileName,
    this.fileSize,
    this.linkUrl,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'duration': duration,
        'order': order,
        'materialType': materialType,
        if (uploadedKey != null && materialType == 'Video')
          'videoKey': uploadedKey,
        if (uploadedKey != null && materialType == 'PDF')
          'materialKey': uploadedKey,
        if (materialType == 'Link' && (linkUrl ?? '').isNotEmpty) 'url': linkUrl,
      };
}

class AddLessonView extends StatefulWidget {
  const AddLessonView({super.key});

  @override
  State<AddLessonView> createState() => _AddLessonViewState();
}

class _AddLessonViewState extends State<AddLessonView> {
  late final TeacherCourseViewmodel _courseVm;
  final List<_LessonEntry> _lessons = [];

  bool _uploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _courseVm = Get.isRegistered<TeacherCourseViewmodel>()
        ? Get.find<TeacherCourseViewmodel>()
        : Get.put(TeacherCourseViewmodel());
  }

  // ── Add Lesson dialog ────────────────────────────────────────────────────

  Future<void> _addLesson() async {
    // The dialog owns its text controllers and disposes them in its own dispose(), i.e. only
    // after the closing animation. Disposing them here as soon as showDialog returned hit the
    // '_dependents.isEmpty' assertion on every Add/Cancel/Back (UAT Round 4b H4).
    final entry = await showDialog<_LessonEntry>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddLessonDialog(order: _lessons.length),
    );
    if (entry != null && mounted) setState(() => _lessons.add(entry));
  }

  Future<void> _publishCourse() async {
    if (_lessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 lesson before publishing.')),
      );
      return;
    }
    // Step 1: upload files for Video/PDF lessons
    final lessonsNeedingUpload = _lessons
        .where((l) =>
            (l.materialType == 'Video' || l.materialType == 'PDF') &&
            l.fileBytes != null &&
            l.uploadedKey == null)
        .toList();

    if (lessonsNeedingUpload.isNotEmpty) {
      setState(() {
        _uploading = true;
        _uploadProgress = 0.0;
        _uploadStatus = 'Uploading lesson materials…';
      });

      for (int i = 0; i < lessonsNeedingUpload.length; i++) {
        final lesson = lessonsNeedingUpload[i];
        try {
          setState(() {
            _uploadStatus =
                'Uploading "${lesson.fileName}" (${i + 1}/${lessonsNeedingUpload.length})…';
          });

          final contentType = lesson.materialType == 'PDF'
              ? 'application/pdf'
              : _videoContentType(lesson.fileName ?? '');
          if (contentType == null) {
            throw Exception(
                'Unsupported video format. Please use MP4, MOV or WebM.');
          }

          final result = await S3Service.uploadFile(
            bytes: lesson.fileBytes!,
            folder: lesson.materialType == 'PDF' ? 'course-materials' : 'lessons',
            fileName: lesson.fileName!,
            contentType: contentType,
          );
          if (result['success'] != true) {
            throw Exception(result['message'] ?? 'Upload failed');
          }
          final key = (result['key'] as String?) ?? '';
          if (key.isEmpty) throw Exception('Upload did not return a file key');

          setState(() {
            lesson.uploadedKey = key;
            _uploadProgress = (i + 1) / lessonsNeedingUpload.length;
          });
        } catch (e) {
          setState(() {
            _uploading = false;
            _uploadStatus = '';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed for "${lesson.fileName}": ${Utils.errorMessage(e)}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _uploading = false;
        _uploadStatus = '';
        _uploadProgress = 0.0;
      });
    }

    // Step 2: create course and submit lessons
    _courseVm.onCourseCreated = () async {
      final courseId = _courseVm.lastCourseId;
      if (courseId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Course was created but the server did not return its id, so lessons were not saved.'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }
      final failures = await _courseVm.submitLessons(
        courseId,
        _lessons.map((l) => l.toMap()).toList(),
      );
      if (!mounted) return;
      if (failures.isEmpty) {
        _courseCompleteAlert(context);
      } else {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColor.primaryColor,
            title: const Text('Some lessons were not saved',
                style: TextStyle(color: Colors.white)),
            content: Text(
              'The course was created, but ${failures.length} lesson(s) failed:\n\n${failures.join('\n')}',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppColor.red)),
              ),
            ],
          ),
        );
      }
    };
    _courseVm.createCourse();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColor.primaryColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              const SizedBox(height: 8),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset(
                            "assets/icons/Arrow - Right 3.svg"),
                      ),
                      SizedBox(width: Responsive.w(1)),
                      Text(
                        'Add Lessons',
                        style: GoogleFonts.rethinkSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ],
                  ),
                  circularIcon("assets/icons/robotic.svg"),
                ],
              ),
              const SizedBox(height: 16),

              // Lesson list
              if (_lessons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No lessons added yet.\nTap "Add Lesson" below.',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ..._lessons.asMap().entries.map((e) => _lessonCard(e.key, e.value)),

              const SizedBox(height: 12),

              // Add Lesson button
              GestureDetector(
                onTap: _uploading ? null : _addLesson,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: ShapeDecoration(
                    color: AppColor.primaryColor,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: Colors.white),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset("assets/icons/plus-sign.svg"),
                      const SizedBox(width: 8),
                      Text(
                        'Add Lesson',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontSize: Responsive.textScaleFactor * 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: Responsive.h(4)),

              // Upload progress
              if (_uploading) ...[
                Text(
                  _uploadStatus,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.red),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                const SizedBox(height: 12),
              ],

              // Publish Course button
              Obx(() {
                final saving = _courseVm.saving.value || _uploading;
                return GestureDetector(
                  onTap: saving ? null : _publishCourse,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: ShapeDecoration(
                      color: saving
                          ? AppColor.red.withValues(alpha: 0.5)
                          : AppColor.red,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            width: 1,
                            color: saving
                                ? Colors.red.withValues(alpha: 0.5)
                                : Colors.red),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (saving)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                        else
                          Text(
                            'Publish Course',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: AppColor.white,
                              fontSize: Responsive.textScaleFactor * 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: Responsive.h(4)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _lessonCard(int index, _LessonEntry lesson) {
    final hasFile = lesson.fileName != null;
    final hasLink = (lesson.linkUrl ?? '').isNotEmpty;
    final uploaded = (lesson.uploadedKey ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson ${index + 1}: ${lesson.title}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                if (lesson.description.isNotEmpty)
                  Text(lesson.description,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                if (lesson.duration.isNotEmpty)
                  Text('${lesson.duration} min',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _typeBadge(lesson.materialType),
                    const SizedBox(width: 6),
                    if (hasFile)
                      Flexible(
                        child: Text(
                          lesson.fileName!,
                          style: TextStyle(
                              color: uploaded ? Colors.greenAccent : Colors.white54,
                              fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else if (hasLink)
                      Flexible(
                        child: Text(
                          lesson.linkUrl!,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColor.red, size: 20),
            onPressed: () => setState(() => _lessons.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    final colors = {
      'Video': Colors.blueAccent,
      'PDF': Colors.redAccent,
      'Quiz': Colors.orangeAccent,
      'Link': Colors.greenAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[type] ?? Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: (colors[type] ?? Colors.grey).withValues(alpha: 0.4)),
      ),
      child: Text(
        type,
        style: TextStyle(
            color: colors[type] ?? Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Video MIME type accepted by the upload backend, or null if unsupported.
  String? _videoContentType(String fileName) {
    final type = S3Service.contentTypeFor(fileName);
    return (type != null && type.startsWith('video/')) ? type : null;
  }
}

void _courseCompleteAlert(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: AppColor.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset("assets/icons/checkmark-circle-02.svg"),
              SizedBox(height: Responsive.h(1)),
              Text(
                "Your Course is Live!",
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: Responsive.textScaleFactor * 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Responsive.h(1)),
              Text(
                textAlign: TextAlign.center,
                "Your course is now available for students to discover and purchase. You can boost it for more visibility anytime.",
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: Responsive.textScaleFactor * 16,
                ),
              ),
              SizedBox(height: Responsive.h(5)),
              GestureDetector(
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: AppColor.red,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Got It",
                            style: GoogleFonts.dmSans(
                              fontSize: Responsive.textScaleFactor * 14,
                              color: AppColor.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SvgPicture.asset("assets/icons/arrow.svg"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── Add Lesson dialog ───────────────────────────────────────────────────────

class _AddLessonDialog extends StatefulWidget {
  final int order;
  const _AddLessonDialog({required this.order});

  @override
  State<_AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<_AddLessonDialog> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final linkCtrl = TextEditingController();
  String selectedType = 'Video';
  String? pickedFileName;
  int? pickedFileSize;
  Uint8List? pickedBytes;

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    durationCtrl.dispose();
    linkCtrl.dispose();
    super.dispose();
  }

  /// The lesson to add, or null (dialog stays open) while the title is empty.
  _LessonEntry? _entry() {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return null;
    final link = linkCtrl.text.trim();
    return _LessonEntry(
      title: title,
      description: descCtrl.text.trim(),
      duration: durationCtrl.text.trim(),
      order: widget.order,
      materialType: selectedType,
      fileBytes: pickedBytes,
      fileName: pickedFileName,
      fileSize: pickedFileSize,
      linkUrl: link.isEmpty ? null : link,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.primaryColor,
      title: Text('Add Lesson',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _lessonDialogField(titleCtrl, 'Lesson Title'),
            const SizedBox(height: 10),
            // Description
            _lessonDialogField(descCtrl, 'Description (optional)'),
            const SizedBox(height: 10),
            // Duration
            _lessonDialogField(durationCtrl, 'Duration in minutes (optional)',
                type: TextInputType.number),
            const SizedBox(height: 14),

            // Material type selector
            Text('Material Type',
                style: GoogleFonts.dmSans(
                    color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _kMaterialTypes.map((t) {
                final active = selectedType == t;
                return GestureDetector(
                  onTap: () =>
                      setState(() => selectedType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColor.red
                          : AppColor.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppColor.red : Colors.white24,
                      ),
                    ),
                    child: Text(t,
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Conditional content by material type
            if (selectedType == 'Video' || selectedType == 'PDF') ...[
              GestureDetector(
                onTap: () async {
                  final type = selectedType == 'Video'
                      ? FileType.video
                      : FileType.custom;
                  final result =
                      await FilePicker.platform.pickFiles(
                    type: type,
                    allowedExtensions:
                        selectedType == 'PDF' ? ['pdf'] : null,
                    withData: true,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    setState(() {
                      pickedFileName = file.name;
                      pickedFileSize = file.size;
                      pickedBytes = file.bytes;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColor.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedType == 'Video'
                            ? Icons.video_file_outlined
                            : Icons.picture_as_pdf_outlined,
                        color: AppColor.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickedFileName ??
                              'Tap to select $selectedType file',
                          style: GoogleFonts.dmSans(
                              color: pickedFileName != null
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (pickedFileSize != null)
                        Text(
                          _formatBytes(pickedFileSize!),
                          style: GoogleFonts.dmSans(
                              color: Colors.white54, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ),
            ] else if (selectedType == 'Link') ...[
              _lessonDialogField(linkCtrl, 'https://...'),
            ] else if (selectedType == 'Quiz') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  'Quiz questions will be added after publishing.',
                  style: GoogleFonts.dmSans(
                      color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () {
            if (titleCtrl.text.trim().isEmpty) {
              Utils.toastMassage('Please enter a lesson title');
              return;
            }
            Navigator.pop(context, _entry());
          },
          child: Text('Add', style: TextStyle(color: AppColor.red)),
        ),
      ],
    );
  }
}

Widget _lessonDialogField(
  TextEditingController ctrl,
  String hint, {
  TextInputType type = TextInputType.text,
}) {
  return TextField(
    controller: ctrl,
    style: const TextStyle(color: Colors.white),
    keyboardType: type,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColor.red)),
    ),
  );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
