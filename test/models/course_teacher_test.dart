import 'package:flutter_test/flutter_test.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/course/course_teacher.dart';

void main() {
  CourseModel course(Map<String, dynamic> j) => CourseModel.fromJson(j);

  test('groups courses by teacherId in catalog order and skips courses without one', () {
    final teachers = CourseTeacher.fromCourses([
      course({'courseId': 'c1', 'teacherId': 't1', 'teacherName': 'Ann', 'category': 'Math', 'rating': 4}),
      course({'courseId': 'c2', 'teacherId': 't2', 'teacherName': 'Bob', 'category': 'Art'}),
      course({'courseId': 'c3', 'teacherId': 't1', 'teacherName': 'Ann', 'category': 'Physics', 'rating': 5}),
      course({'courseId': 'c4', 'title': 'no owner'}),
    ]);
    expect(teachers.map((t) => t.teacherId), ['t1', 't2']);
    expect(teachers.first.name, 'Ann');
    expect(teachers.first.courseCount, 2);
    expect(teachers.first.categories, ['Math', 'Physics']);
    expect(teachers.first.averageRating, 4.5);
    expect(teachers.last.averageRating, isNull);
  });

  test('empty catalog gives no teachers', () {
    expect(CourseTeacher.fromCourses(const []), isEmpty);
  });
}
