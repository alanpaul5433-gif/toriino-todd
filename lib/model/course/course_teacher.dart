import 'package:toriino_todd/model/course/course_model.dart';

/// A teacher as seen from the course catalog: the owner (teacherId) of one or more published
/// courses. There is no teachers endpoint, and GET /mentors returns mentors — showing those
/// under "Recommended Teachers" mislabelled mentors as teachers (UAT Round 5).
class CourseTeacher {
  final String teacherId;
  final String name;
  final List<String> categories;
  final int courseCount;
  final double? averageRating;

  const CourseTeacher({
    required this.teacherId,
    required this.name,
    required this.categories,
    required this.courseCount,
    this.averageRating,
  });

  /// Unique teachers of [courses], in catalog order. Courses without a teacherId are skipped.
  static List<CourseTeacher> fromCourses(List<CourseModel> courses) {
    final order = <String>[];
    final names = <String, String>{};
    final cats = <String, Set<String>>{};
    final counts = <String, int>{};
    final ratings = <String, List<double>>{};
    for (final c in courses) {
      final id = (c.teacherId ?? '').trim();
      if (id.isEmpty) continue;
      if (!counts.containsKey(id)) order.add(id);
      counts[id] = (counts[id] ?? 0) + 1;
      final name = (c.teacherName ?? '').trim();
      if (name.isNotEmpty) names.putIfAbsent(id, () => name);
      final cat = (c.category ?? '').trim();
      if (cat.isNotEmpty) cats.putIfAbsent(id, () => <String>{}).add(cat);
      if (c.rating != null && c.rating! > 0) ratings.putIfAbsent(id, () => []).add(c.rating!);
    }
    return [
      for (final id in order)
        CourseTeacher(
          teacherId: id,
          name: names[id] ?? 'Teacher',
          categories: (cats[id] ?? const <String>{}).toList(),
          courseCount: counts[id]!,
          averageRating: (ratings[id] ?? const []).isEmpty
              ? null
              : ratings[id]!.reduce((a, b) => a + b) / ratings[id]!.length,
        ),
    ];
  }
}
