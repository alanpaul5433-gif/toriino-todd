import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/course/lesson_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/utils/utils.dart';

class TeacherCourseViewmodel extends GetxController {
  final _courseRepo = CourseRepo();

  final rxMyCourses = Rx<ApiResponse<CourseListResponse>>(ApiResponse.loading());
  final rxLessons = Rx<ApiResponse<List<LessonModel>>>(ApiResponse.loading());

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController();
  final priceController = TextEditingController();

  RxString selectedCategory = 'General'.obs;
  RxString selectedLevel = 'Beginner'.obs;
  RxBool saving = false.obs;

  final lessonTitleController = TextEditingController();
  final lessonDescriptionController = TextEditingController();
  final lessonDurationController = TextEditingController();
  RxBool savingLesson = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyCourses();
  }

  void fetchMyCourses() {
    rxMyCourses.value = ApiResponse.loading();
    _courseRepo.getMyCreatedCourses().then((value) {
      rxMyCourses.value = ApiResponse.success(CourseListResponse.fromJson(value));
    }).onError((error, _) {
      rxMyCourses.value = ApiResponse.error(error.toString());
    });
  }

  void createCourse() {
    saving.value = true;
    Map<String, dynamic> data = {
      'courseId': 'crs_${DateTime.now().millisecondsSinceEpoch}',
      'title': titleController.text,
      'description': descriptionController.text,
      'category': selectedCategory.value,
      'duration': durationController.text,
      'price': double.tryParse(priceController.text) ?? 0,
      'level': selectedLevel.value,
      'status': 'active',
    };

    _courseRepo.createCourse(data).then((value) {
      saving.value = false;
      Utils.toastMassage("Course created!");
      clearCourseForm();
      fetchMyCourses();
      Get.back();
    }).onError((error, _) {
      saving.value = false;
      Utils.toastMassage(error.toString());
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

  void addLesson(String courseId) {
    savingLesson.value = true;
    Map<String, dynamic> data = {
      'lessonId': 'les_${DateTime.now().millisecondsSinceEpoch}',
      'title': lessonTitleController.text,
      'description': lessonDescriptionController.text,
      'duration': lessonDurationController.text,
    };

    _courseRepo.addLesson(courseId, data).then((value) {
      savingLesson.value = false;
      Utils.toastMassage("Lesson added!");
      clearLessonForm();
      fetchLessons(courseId);
    }).onError((error, _) {
      savingLesson.value = false;
      Utils.toastMassage(error.toString());
    });
  }

  void clearCourseForm() {
    titleController.clear();
    descriptionController.clear();
    durationController.clear();
    priceController.clear();
    selectedCategory.value = 'General';
    selectedLevel.value = 'Beginner';
  }

  void clearLessonForm() {
    lessonTitleController.clear();
    lessonDescriptionController.clear();
    lessonDurationController.clear();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    priceController.dispose();
    lessonTitleController.dispose();
    lessonDescriptionController.dispose();
    lessonDurationController.dispose();
    super.onClose();
  }
}
