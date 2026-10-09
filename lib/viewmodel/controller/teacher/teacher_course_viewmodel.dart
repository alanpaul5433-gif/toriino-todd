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
  String? selectedLanguage;
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

  VoidCallback? onCourseCreated;
  String? lastCourseId;

  void createCourse() {
    saving.value = true;
    Map<String, dynamic> data = {
      'title': titleController.text,
      'description': descriptionController.text,
      'category': selectedCategory.value,
      'duration': durationController.text,
      'price': double.tryParse(priceController.text) ?? 0,
      'level': selectedLevel.value,
      'language': selectedLanguage ?? '',
    };

    _courseRepo.createCourse(data).then((value) {
      saving.value = false;
      lastCourseId = (value as Map<String, dynamic>?)?['courseId'] as String?;
      clearCourseForm();
      fetchMyCourses();
      if (onCourseCreated != null) {
        onCourseCreated!();
      } else {
        Utils.toastMassage("Course created!");
        Get.back();
      }
    }).onError((error, _) {
      saving.value = false;
      Utils.toastMassage(error.toString());
    });
  }

  /// POSTs each lesson. Lesson media is sent as S3 keys (`videoKey` /
  /// `materialKey`), never URLs. Returns one "title: reason" entry per lesson
  /// the server rejected (empty list = all saved).
  Future<List<String>> submitLessons(
      String courseId, List<Map<String, dynamic>> lessonsData) async {
    final failures = <String>[];
    for (final lesson in lessonsData) {
      try {
        await _courseRepo.addLesson(courseId, {
          'title': lesson['title'] ?? '',
          'description': lesson['description'] ?? '',
          'duration': lesson['duration'] ?? '',
          'order': lesson['order']?.toString() ?? '0',
          'materialType': lesson['materialType'] ?? 'Video',
          if ((lesson['videoKey'] as String?)?.isNotEmpty == true)
            'videoKey': lesson['videoKey'],
          if ((lesson['materialKey'] as String?)?.isNotEmpty == true)
            'materialKey': lesson['materialKey'],
          if ((lesson['url'] as String?)?.isNotEmpty == true) 'url': lesson['url'],
        });
      } catch (e) {
        failures.add('${lesson['title'] ?? 'Lesson'}: ${Utils.errorMessage(e)}');
      }
    }
    return failures;
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
