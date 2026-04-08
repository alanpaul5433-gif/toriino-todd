import 'package:get/get.dart';
import 'package:getxmvvm/data/response/api_response.dart';
import 'package:getxmvvm/model/user/user_profile_model.dart';
import 'package:getxmvvm/model/course/course_model.dart';
import 'package:getxmvvm/model/earnings/earnings_model.dart';
import 'package:getxmvvm/repository/mock/mock_repo.dart';

class TeacherHomeViewmodel extends GetxController {
  final rxProfile = Rx<ApiResponse<UserProfileModel>>(ApiResponse.loading());
  final rxCourses = Rx<ApiResponse<CourseListResponse>>(ApiResponse.loading());
  final rxEarnings = Rx<ApiResponse<EarningsSummaryResponse>>(ApiResponse.loading());

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  void fetchAll() {
    fetchProfile();
    fetchMyCourses();
    fetchEarnings();
  }

  void fetchProfile() {
    rxProfile.value = ApiResponse.loading();
    MockRepo.getProfile().then((value) {
      rxProfile.value = ApiResponse.success(UserProfileModel.fromJson(value));
    }).onError((error, _) {
      rxProfile.value = ApiResponse.error(error.toString());
    });
  }

  void fetchMyCourses() {
    rxCourses.value = ApiResponse.loading();
    MockRepo.getMyCreatedCourses().then((value) {
      rxCourses.value = ApiResponse.success(CourseListResponse.fromJson(value));
    }).onError((error, _) {
      rxCourses.value = ApiResponse.error(error.toString());
    });
  }

  void fetchEarnings() {
    rxEarnings.value = ApiResponse.loading();
    MockRepo.getEarningsSummary().then((value) {
      rxEarnings.value = ApiResponse.success(EarningsSummaryResponse.fromJson(value));
    }).onError((error, _) {
      rxEarnings.value = ApiResponse.error(error.toString());
    });
  }
}
