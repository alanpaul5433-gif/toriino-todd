import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/repository/session_repo.dart';
import 'package:toriino_todd/utils/utils.dart';

class MentorSessionViewmodel extends GetxController {
  final _sessionRepo = SessionRepo();

  final rxSessions = Rx<ApiResponse<SessionListResponse>>(ApiResponse.loading());

  @override
  void onInit() {
    super.onInit();
    fetchSessions();
  }

  void fetchSessions() {
    rxSessions.value = ApiResponse.loading();
    _sessionRepo.getSessions(role: 'mentor').then((value) {
      rxSessions.value = ApiResponse.success(SessionListResponse.fromJson(value));
    }).onError((error, _) {
      rxSessions.value = ApiResponse.error(error.toString());
    });
  }

  void startSession(String sessionId) {
    _sessionRepo.updateSessionStatus(sessionId, 'active').then((_) {
      fetchSessions();
      Utils.toastMassage("Session started");
    }).onError((error, _) {
      Utils.toastMassage(error.toString());
    });
  }

  void completeSession(String sessionId) {
    _sessionRepo.updateSessionStatus(sessionId, 'completed').then((_) {
      fetchSessions();
      Utils.toastMassage("Session completed");
    }).onError((error, _) {
      Utils.toastMassage(error.toString());
    });
  }

  void cancelSession(String sessionId) {
    _sessionRepo.updateSessionStatus(sessionId, 'cancelled').then((_) {
      fetchSessions();
      Utils.toastMassage("Session cancelled");
    }).onError((error, _) {
      Utils.toastMassage(error.toString());
    });
  }

  final isCreating = false.obs;

  void createSession(Map<String, dynamic> data, {VoidCallback? onSuccess}) {
    isCreating.value = true;
    _sessionRepo.bookSession(data).then((_) {
      isCreating.value = false;
      fetchSessions();
      Utils.toastMassage("Session created");
      onSuccess?.call();
    }).onError((error, _) {
      isCreating.value = false;
      Utils.toastMassage(error.toString());
    });
  }
}
