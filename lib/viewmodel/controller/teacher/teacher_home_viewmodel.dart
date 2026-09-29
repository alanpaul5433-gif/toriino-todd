import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/user/user_profile_model.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/earnings/earnings_model.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/repository/earnings_repo.dart';

class TeacherHomeViewmodel extends GetxController {
  final _userRepo = UserRepo();
  final _courseRepo = CourseRepo();
  final _earningsRepo = EarningsRepo();

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
    _userRepo.getProfile().then((value) {
      rxProfile.value = ApiResponse.success(UserProfileModel.fromJson(value));
    }).onError((error, _) {
      rxProfile.value = ApiResponse.error(error.toString());
    });
  }

  void fetchMyCourses() {
    rxCourses.value = ApiResponse.loading();
    _courseRepo.getMyCreatedCourses().then((value) {
      rxCourses.value = ApiResponse.success(CourseListResponse.fromJson(value));
    }).onError((error, _) {
      rxCourses.value = ApiResponse.error(error.toString());
    });
  }

  void fetchEarnings() {
    rxEarnings.value = ApiResponse.loading();
    _earningsRepo.getEarningsSummary().then((value) {
      rxEarnings.value = ApiResponse.success(EarningsSummaryResponse.fromJson(value));
    }).onError((error, _) {
      rxEarnings.value = ApiResponse.error(error.toString());
    });
  }
}
