import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/user/user_profile_model.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/model/earnings/earnings_model.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/repository/session_repo.dart';
import 'package:toriino_todd/repository/earnings_repo.dart';

class MentorHomeViewmodel extends GetxController {
  final _userRepo = UserRepo();
  final _sessionRepo = SessionRepo();
  final _earningsRepo = EarningsRepo();

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
    _userRepo.getProfile().then((value) {
      rxProfile.value = ApiResponse.success(UserProfileModel.fromJson(value));
    }).onError((error, _) {
      rxProfile.value = ApiResponse.error(error.toString());
    });
  }

  void fetchSessions() {
    rxSessions.value = ApiResponse.loading();
    _sessionRepo.getSessions(role: 'mentor').then((value) {
      rxSessions.value = ApiResponse.success(SessionListResponse.fromJson(value));
    }).onError((error, _) {
      rxSessions.value = ApiResponse.error(error.toString());
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
