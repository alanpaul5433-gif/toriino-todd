import 'package:get/get.dart';
import 'package:getxmvvm/data/response/api_response.dart';
import 'package:getxmvvm/model/course/course_model.dart';
import 'package:getxmvvm/model/course/lesson_model.dart';
import 'package:getxmvvm/repository/mock/mock_repo.dart';
import 'package:getxmvvm/utils/utils.dart';

class CourseViewmodel extends GetxController {
  final rxCourses = Rx<ApiResponse<CourseListResponse>>(ApiResponse.loading());
  final rxMyCourses =
      Rx<ApiResponse<CourseListResponse>>(ApiResponse.loading());
  final rxCourseDetail = Rx<ApiResponse<CourseModel>>(ApiResponse.loading());
  final rxLessons =
      Rx<ApiResponse<List<LessonModel>>>(ApiResponse.loading());

  RxBool enrolling = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCourses();
    fetchMyCourses();
  }

  void fetchCourses({String? category}) {
    rxCourses.value = ApiResponse.loading();
    MockRepo.getCourses(category: category).then((value) {
      rxCourses.value =
          ApiResponse.success(CourseListResponse.fromJson(value));
    }).onError((error, _) {
      rxCourses.value = ApiResponse.error(error.toString());
    });
  }

  void fetchMyCourses() {
    rxMyCourses.value = ApiResponse.loading();
    MockRepo.getMyEnrolledCourses().then((value) {
      rxMyCourses.value =
          ApiResponse.success(CourseListResponse.fromJson(value));
    }).onError((error, _) {
      rxMyCourses.value = ApiResponse.error(error.toString());
    });
  }

  void fetchCourseDetail(String courseId) {
    rxCourseDetail.value = ApiResponse.loading();
    MockRepo.getCourseById(courseId).then((value) {
      rxCourseDetail.value =
          ApiResponse.success(CourseModel.fromJson(value));
    }).onError((error, _) {
      rxCourseDetail.value = ApiResponse.error(error.toString());
    });
  }

  void fetchLessons(String courseId) {
    rxLessons.value = ApiResponse.loading();
    MockRepo.getLessons(courseId).then((value) {
      final lessons = (value['lessons'] as List)
          .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
          .toList();
      rxLessons.value = ApiResponse.success(lessons);
    }).onError((error, _) {
      rxLessons.value = ApiResponse.error(error.toString());
    });
  }

  void enrollCourse(String courseId) {
    enrolling.value = true;
    MockRepo.enrollCourse(courseId).then((value) {
      enrolling.value = false;
      Utils.toastMassage("Enrolled successfully!");
      fetchMyCourses();
    }).onError((error, _) {
      enrolling.value = false;
      Utils.toastMassage(error.toString());
    });
  }
}
