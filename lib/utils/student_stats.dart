import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/session/session_model.dart';

/// Counts derived from real server lists (GET /courses/my-courses and
/// GET /sessions?role=student). Counting only — no money.
class StudentStats {
  StudentStats._();

  /// Enrollments that are not completed (`enrollment.status` != completed).
  static int coursesInProgress(List<CourseModel> myCourses) =>
      myCourses.where((c) => !c.isCompleted).length;

  /// Enrollments with `enrollment.status == 'completed'`.
  static int coursesCompleted(List<CourseModel> myCourses) =>
      myCourses.where((c) => c.isCompleted).length;

  /// Sessions booked, excluding cancelled ones.
  static int sessionsBooked(List<SessionModel> sessions) =>
      sessions.where((s) => s.status != 'cancelled').length;

  /// Not cancelled/completed sessions scheduled in the future, soonest first.
  static List<SessionModel> upcoming(List<SessionModel> sessions,
      {DateTime? now}) {
    final t = now ?? DateTime.now();
    final list = sessions.where((s) {
      if (s.status == 'cancelled' || s.status == 'completed') return false;
      final d = DateTime.tryParse(s.dateTime ?? '');
      return d != null && d.isAfter(t);
    }).toList();
    list.sort((a, b) => DateTime.parse(a.dateTime!)
        .compareTo(DateTime.parse(b.dateTime!)));
    return list;
  }
}
