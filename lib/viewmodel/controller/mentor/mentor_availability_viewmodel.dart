import 'package:get/get.dart';
import 'package:getxmvvm/data/response/api_response.dart';
import 'package:getxmvvm/model/mentor/availability_model.dart';
import 'package:getxmvvm/repository/mock/mock_repo.dart';
import 'package:getxmvvm/utils/utils.dart';

class MentorAvailabilityViewmodel extends GetxController {
  final rxSlots = Rx<ApiResponse<List<AvailabilityModel>>>(ApiResponse.loading());

  RxBool saving = false.obs;
  RxList<Map<String, dynamic>> editableSlots = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAvailability();
  }

  void fetchAvailability() {
    rxSlots.value = ApiResponse.loading();
    MockRepo.getAvailability('mnt_001').then((value) {
      final slots = (value['slots'] as List)
          .map((e) => AvailabilityModel.fromJson(e as Map<String, dynamic>))
          .toList();
      rxSlots.value = ApiResponse.success(slots);
      editableSlots.value = slots
          .map((s) => {
                'dayOfWeek': s.dayOfWeek,
                'startTime': s.startTime,
                'endTime': s.endTime,
                'isRecurring': s.isRecurring ?? true,
              })
          .toList();
    }).onError((error, _) {
      rxSlots.value = ApiResponse.error(error.toString());
    });
  }

  void addSlot(String dayOfWeek, String startTime, String endTime) {
    editableSlots.add({
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isRecurring': true,
    });
  }

  void removeSlot(int index) {
    editableSlots.removeAt(index);
  }

  void saveAvailability() {
    saving.value = true;
    MockRepo.updateAvailability({'slots': editableSlots.toList()}).then((_) {
      saving.value = false;
      Utils.toastMassage("Availability updated");
      fetchAvailability();
    }).onError((error, _) {
      saving.value = false;
      Utils.toastMassage(error.toString());
    });
  }
}
