import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/course/lesson_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/teacher/add_lessons_view.dart';

/// A teacher's own course: its lessons, each playable/openable. Lesson media is private;
/// GET /courses/{id}/lessons/{lessonId}/media issues pre-signed links to the owner as well
/// as to enrolled students. (Teachers previously had no way to view their lessons — UAT M8.)
class TeacherCourseLessonsView extends StatefulWidget {
  final CourseModel course;
  const TeacherCourseLessonsView({super.key, required this.course});

  @override
  State<TeacherCourseLessonsView> createState() => _TeacherCourseLessonsViewState();
}

class _TeacherCourseLessonsViewState extends State<TeacherCourseLessonsView> {
  late Future<dynamic> _lessons;

  @override
  void initState() {
    super.initState();
    _lessons = CourseRepo().getLessons(widget.course.courseId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.course.title ?? '').trim();
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColor.primaryColor,
        foregroundColor: AppColor.white,
        title: Text(title.isEmpty ? 'Course' : title,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _lessons = CourseRepo().getLessons(widget.course.courseId ?? ''));
          await _lessons.catchError((_) => null);
        },
        child: FutureBuilder<dynamic>(
          future: _lessons,
          builder: (context, snapshot) {
            Widget message(String text) => ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                  ),
                ]);
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return message(Utils.errorMessage(snapshot.error));
            final raw = snapshot.data;
            final list = (raw is Map ? raw['lessons'] as List? : null) ?? const [];
            if (list.isEmpty) return message('This course has no lessons yet.');
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) => CourseContentWidget(
                lesson: LessonModel.fromJson(list[i] as Map<String, dynamic>),
                course: widget.course,
              ),
            );
          },
        ),
      ),
    );
  }
}
