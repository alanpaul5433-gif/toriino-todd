import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/course/lesson_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/services/analytics_service.dart';
import 'package:toriino_todd/services/course_enrollment_service.dart';
import 'package:toriino_todd/utils/utils.dart';

class CourseViewmodel extends GetxController {
  final _courseRepo = CourseRepo();

  final rxCourses = Rx<ApiResponse<CourseListResponse>>(ApiResponse.loading());
  final rxMyCourses = Rx<ApiResponse<CourseListResponse>>(ApiResponse.loading());
  final rxCourseDetail = Rx<ApiResponse<CourseModel>>(ApiResponse.loading());
  final rxLessons = Rx<ApiResponse<List<LessonModel>>>(ApiResponse.loading());

  RxBool enrolling = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCourses();
    fetchMyCourses();
  }

  // Catalog paging: GET /courses returns a page plus lastKey. The Courses tab used to load
  // only the first page, so later courses could never be reached (UAT Round 6).
  String? _lastCourseKey;
  String? _category;
  bool _loadingMore = false;
  bool get hasMoreCourses => _lastCourseKey != null;

  /// Free-text filter for the Courses tab (title, teacher, category, level).
  final searchQuery = ''.obs;

  void fetchCourses({String? category}) {
    _category = category;
    _lastCourseKey = null;
    rxCourses.value = ApiResponse.loading();
    _courseRepo.getCourses(category: category).then((value) {
      rxCourses.value = ApiResponse.success(CourseListResponse.fromJson(value));
      _lastCourseKey = value['lastKey'] as String?;
    }).onError((error, _) {
      rxCourses.value = ApiResponse.error(error.toString());
    });
  }

  /// Appends the next catalog page, if there is one.
  Future<void> loadMoreCourses() async {
    final key = _lastCourseKey;
    if (key == null || _loadingMore) return;
    _loadingMore = true;
    try {
      final value = await _courseRepo.getCourses(category: _category, lastKey: key);
      final page = CourseListResponse.fromJson(value);
      final existing = rxCourses.value.data?.courses ?? const <CourseModel>[];
      rxCourses.value = ApiResponse.success(CourseListResponse(
        courses: [...existing, ...page.courses],
        count: page.count,
      ));
      _lastCourseKey = value['lastKey'] as String?;
    } catch (_) {
      // Keep what is shown; the next scroll to the end retries.
    } finally {
      _loadingMore = false;
    }
  }

  /// [courses] filtered by [searchQuery] (case-insensitive substring).
  List<CourseModel> filterCourses(List<CourseModel> courses) {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return courses;
    return courses.where((c) => [c.title, c.teacherName, c.category, c.level]
        .any((f) => (f ?? '').toLowerCase().contains(q))).toList();
  }

  void fetchMyCourses() {
    rxMyCourses.value = ApiResponse.loading();
    _courseRepo.getMyEnrolledCourses().then((value) {
      rxMyCourses.value = ApiResponse.success(CourseListResponse.fromJson(value));
    }).onError((error, _) {
      rxMyCourses.value = ApiResponse.error(error.toString());
    });
  }

  void fetchCourseDetail(String courseId) {
    rxCourseDetail.value = ApiResponse.loading();
    _courseRepo.getCourseById(courseId).then((value) {
      rxCourseDetail.value = ApiResponse.success(CourseModel.fromJson(value));
    }).onError((error, _) {
      rxCourseDetail.value = ApiResponse.error(error.toString());
    });
  }

  void fetchLessons(String courseId) {
    rxLessons.value = ApiResponse.loading();
    _courseRepo.getLessons(courseId).then((value) {
      final lessons = (value['lessons'] as List? ?? [])
          .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
          .toList();
      rxLessons.value = ApiResponse.success(lessons);
    }).onError((error, _) {
      rxLessons.value = ApiResponse.error(error.toString());
    });
  }

  /// Real enrollment: free course -> POST enroll; paid course (or a 402 from
  /// enroll) -> Stripe PaymentSheet, then poll my-courses until the webhook
  /// has enrolled the student. Prefer `runCourseEnrollment` from the UI, which
  /// also shows progress and the outcome.
  Future<EnrollResult> enrollCourse(CourseModel course) async {
    enrolling.value = true;
    final result = await CourseEnrollmentService().enroll(course);
    enrolling.value = false;
    if (result.isEnrolled) {
      AnalyticsService.logEnroll(courseId: course.courseId ?? '');
    }
    if (result.outcome != EnrollOutcome.failed &&
        result.outcome != EnrollOutcome.cancelled) {
      fetchMyCourses();
    }
    Utils.toastMassage(result.message);
    return result;
  }
}
