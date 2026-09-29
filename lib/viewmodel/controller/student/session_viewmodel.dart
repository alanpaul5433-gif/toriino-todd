import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/repository/session_repo.dart';
import 'package:toriino_todd/utils/utils.dart';

class SessionViewmodel extends GetxController {
  final _sessionRepo = SessionRepo();

  final rxSessions = Rx<ApiResponse<SessionListResponse>>(ApiResponse.loading());
  RxBool booking = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSessions();
  }

  void fetchSessions() {
    rxSessions.value = ApiResponse.loading();
    _sessionRepo.getSessions(role: 'student').then((value) {
      rxSessions.value = ApiResponse.success(SessionListResponse.fromJson(value));
    }).onError((error, _) {
      rxSessions.value = ApiResponse.error(error.toString());
    });
  }

  void bookSession(Map<String, dynamic> data) {
    booking.value = true;
    _sessionRepo.bookSession(data).then((value) {
      booking.value = false;
      Utils.toastMassage("Session booked successfully!");
      fetchSessions();
    }).onError((error, _) {
      booking.value = false;
      Utils.toastMassage(error.toString());
    });
  }

  void updateSessionStatus(String sessionId, String status) {
    _sessionRepo.updateSessionStatus(sessionId, status).then((_) {
      fetchSessions();
    }).onError((error, _) {
      Utils.toastMassage(error.toString());
    });
  }
}
