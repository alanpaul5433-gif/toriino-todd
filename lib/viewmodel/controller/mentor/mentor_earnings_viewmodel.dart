import 'package:get/get.dart';
import 'package:getxmvvm/data/response/api_response.dart';
import 'package:getxmvvm/model/earnings/earnings_model.dart';
import 'package:getxmvvm/repository/mock/mock_repo.dart';

class MentorEarningsViewmodel extends GetxController {
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
    MockRepo.getEarningsSummary().then((value) {
      rxSummary.value = ApiResponse.success(EarningsSummaryResponse.fromJson(value));
    }).onError((error, _) {
      rxSummary.value = ApiResponse.error(error.toString());
    });
  }

  void fetchHistory() {
    rxHistory.value = ApiResponse.loading();
    MockRepo.getEarningsHistory().then((value) {
      final history = (value['history'] as List)
          .map((e) => EarningsModel.fromJson(e as Map<String, dynamic>))
          .toList();
      rxHistory.value = ApiResponse.success(history);
    }).onError((error, _) {
      rxHistory.value = ApiResponse.error(error.toString());
    });
  }
}
