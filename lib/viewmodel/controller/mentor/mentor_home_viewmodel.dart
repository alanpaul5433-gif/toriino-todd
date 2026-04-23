import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/user/user_profile_model.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/model/earnings/earnings_model.dart';
import 'package:toriino_todd/repository/mock/mock_repo.dart';

class MentorHomeViewmodel extends GetxController {
  final rxProfile = Rx<ApiResponse<UserProfileModel>>(ApiResponse.loading());
  final rxSessions = Rx<ApiResponse<SessionListResponse>>(ApiResponse.loading());
  final rxEarnings = Rx<ApiResponse<EarningsSummaryResponse>>(ApiResponse.loading());

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  void fetchAll() {
    fetchProfile();
    fetchSessions();
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

  void fetchSessions() {
    rxSessions.value = ApiResponse.loading();
    MockRepo.getSessions(role: 'mentor').then((value) {
      rxSessions.value = ApiResponse.success(SessionListResponse.fromJson(value));
    }).onError((error, _) {
      rxSessions.value = ApiResponse.error(error.toString());
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
