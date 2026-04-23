import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/repository/mock/mock_repo.dart';
import 'package:toriino_todd/utils/utils.dart';

class MentorSessionViewmodel extends GetxController {
  final rxSessions = Rx<ApiResponse<SessionListResponse>>(ApiResponse.loading());

  @override
  void onInit() {
    super.onInit();
    fetchSessions();
  }

  void fetchSessions() {
    rxSessions.value = ApiResponse.loading();
    MockRepo.getSessions(role: 'mentor').then((value) {
      rxSessions.value = ApiResponse.success(SessionListResponse.fromJson(value));
    }).onError((error, _) {
      rxSessions.value = ApiResponse.error(error.toString());
    });
  }

  void startSession(String sessionId) {
    Utils.toastMassage("Session started");
    fetchSessions();
  }

  void completeSession(String sessionId) {
    Utils.toastMassage("Session completed");
    fetchSessions();
  }

  void cancelSession(String sessionId) {
    Utils.toastMassage("Session cancelled");
    fetchSessions();
  }
}
