import 'package:get/get.dart';
import 'package:getxmvvm/data/response/api_response.dart';
import 'package:getxmvvm/model/user/user_profile_model.dart';
import 'package:getxmvvm/model/course/course_model.dart';
import 'package:getxmvvm/model/mentor/mentor_model.dart';
import 'package:getxmvvm/repository/mock/mock_repo.dart';

class HomeViewmodel extends GetxController {
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
    MockRepo.getProfile().then((value) {
      rxProfile.value =
          ApiResponse.success(UserProfileModel.fromJson(value));
    }).onError((error, _) {
      rxProfile.value = ApiResponse.error(error.toString());
    });
  }

  void fetchCourses() {
    rxCourses.value = ApiResponse.loading();
    MockRepo.getCourses().then((value) {
      rxCourses.value =
          ApiResponse.success(CourseListResponse.fromJson(value));
    }).onError((error, _) {
      rxCourses.value = ApiResponse.error(error.toString());
    });
  }

  void fetchMentors() {
    rxMentors.value = ApiResponse.loading();
    MockRepo.getMentors().then((value) {
      rxMentors.value =
          ApiResponse.success(MentorListResponse.fromJson(value));
    }).onError((error, _) {
      rxMentors.value = ApiResponse.error(error.toString());
    });
  }
}
