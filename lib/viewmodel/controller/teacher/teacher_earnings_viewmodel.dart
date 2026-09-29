import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/earnings/earnings_model.dart';
import 'package:toriino_todd/repository/earnings_repo.dart';

class TeacherEarningsViewmodel extends GetxController {
  final _earningsRepo = EarningsRepo();

  final rxSummary = Rx<ApiResponse<EarningsSummaryResponse>>(ApiResponse.loading());
  final rxHistory = Rx<ApiResponse<List<EarningsModel>>>(ApiResponse.loading());

  @override
  void onInit() {
    super.onInit();
    fetchEarnings();
  }

  void fetchEarnings() {
    fetchSummary();
    fetchHistory();
  }

  void fetchSummary() {
    rxSummary.value = ApiResponse.loading();
    _earningsRepo.getEarningsSummary().then((value) {
      rxSummary.value = ApiResponse.success(EarningsSummaryResponse.fromJson(value));
    }).onError((error, _) {
      rxSummary.value = ApiResponse.error(error.toString());
    });
  }

  void fetchHistory() {
    rxHistory.value = ApiResponse.loading();
    _earningsRepo.getEarningsHistory().then((value) {
      final history = (value['history'] as List? ?? [])
          .map((e) => EarningsModel.fromJson(e as Map<String, dynamic>))
          .toList();
      rxHistory.value = ApiResponse.success(history);
    }).onError((error, _) {
      rxHistory.value = ApiResponse.error(error.toString());
    });
  }
}
