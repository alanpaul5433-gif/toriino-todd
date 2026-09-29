import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/user/user_profile_model.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/mentor/mentor_model.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/repository/mentor_repo.dart';

class HomeViewmodel extends GetxController {
  final _userRepo = UserRepo();
  final _courseRepo = CourseRepo();
  final _mentorRepo = MentorRepo();

  final rxProfile = Rx<ApiResponse<UserProfileModel>>(ApiResponse.loading());
  final rxCourses = Rx<ApiResponse<CourseListResponse>>(ApiResponse.loading());
  final rxMentors = Rx<ApiResponse<MentorListResponse>>(ApiResponse.loading());

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  void fetchAll() {
    fetchProfile();
    fetchCourses();
    fetchMentors();
  }

  void fetchProfile() {
    rxProfile.value = ApiResponse.loading();
    _userRepo.getProfile().then((value) {
      rxProfile.value = ApiResponse.success(UserProfileModel.fromJson(value));
    }).onError((error, _) {
      rxProfile.value = ApiResponse.error(error.toString());
    });
  }

  void fetchCourses() {
    rxCourses.value = ApiResponse.loading();
    _courseRepo.getCourses().then((value) {
      rxCourses.value = ApiResponse.success(CourseListResponse.fromJson(value));
    }).onError((error, _) {
      rxCourses.value = ApiResponse.error(error.toString());
    });
  }

  void fetchMentors() {
    rxMentors.value = ApiResponse.loading();
    _mentorRepo.getMentors().then((value) {
      rxMentors.value = ApiResponse.success(MentorListResponse.fromJson(value));
    }).onError((error, _) {
      rxMentors.value = ApiResponse.error(error.toString());
    });
  }
}
