import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/course/lesson_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
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

  void fetchCourses({String? category}) {
    rxCourses.value = ApiResponse.loading();
    _courseRepo.getCourses(category: category).then((value) {
      rxCourses.value = ApiResponse.success(CourseListResponse.fromJson(value));
    }).onError((error, _) {
      rxCourses.value = ApiResponse.error(error.toString());
    });
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

  void enrollCourse(String courseId) {
    enrolling.value = true;
    _courseRepo.enrollCourse(courseId).then((value) {
      enrolling.value = false;
      Utils.toastMassage("Enrolled successfully!");
      fetchMyCourses();
    }).onError((error, _) {
      enrolling.value = false;
      Utils.toastMassage(error.toString());
    });
  }
}
