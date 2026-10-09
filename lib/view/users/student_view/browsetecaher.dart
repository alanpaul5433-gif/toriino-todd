import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/course/course_teacher.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/student_view/teacher_profile.dart';

/// Teachers = owners of published courses (from GET /courses). This screen used to list
/// GET /mentors, so mentors appeared as "teachers" (UAT Round 5).
class BrowseTecher extends StatefulWidget {
  const BrowseTecher({super.key});

  @override
  State<BrowseTecher> createState() => _BrowseTecherState();
}

class _BrowseTecherState extends State<BrowseTecher> {
  late Future<List<CourseTeacher>> _teachers;

  @override
  void initState() {
    super.initState();
    _teachers = _load();
  }

  Future<List<CourseTeacher>> _load() async {
    final raw = await CourseRepo().getCourses();
    final list = CourseListResponse.fromJson(raw is Map<String, dynamic> ? raw : <String, dynamic>{});
    return CourseTeacher.fromCourses(list.courses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                  ),
                  Text(
                    "Browse Teachers",
                    style: TextStyle(
                      color: AppColor.secconderyColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<CourseTeacher>>(
                  future: _teachers,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                            const SizedBox(height: 8),
                            Text(Utils.errorMessage(snapshot.error),
                                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                            TextButton(
                              onPressed: () => setState(() => _teachers = _load()),
                              child: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }
                    final teachers = snapshot.data ?? const <CourseTeacher>[];
                    if (teachers.isEmpty) {
                      return const Center(
                        child: Text('No teachers yet', style: TextStyle(color: Colors.white70)),
                      );
                    }
                    return ListView.builder(
                      itemCount: teachers.length,
                      itemBuilder: (context, index) => _TeacherCard(teacher: teachers[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final CourseTeacher teacher;
  const _TeacherCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final rating = teacher.averageRating;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: AppColor.white.withValues(alpha: 0.08),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.person, color: Colors.white54, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teacher.name,
                          style: GoogleFonts.dmSans(
                              color: AppColor.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${teacher.courseCount} course${teacher.courseCount == 1 ? '' : 's'}'
                        '${rating != null ? '  ·  ★ ${rating.toStringAsFixed(1)}' : ''}',
                        style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (teacher.categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in teacher.categories)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Text(c, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TeacherProfile(teacherId: teacher.teacherId)),
                ),
                child: const Text('View Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
