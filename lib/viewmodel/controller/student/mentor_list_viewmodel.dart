import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/mentor/mentor_model.dart';
import 'package:toriino_todd/model/mentor/availability_model.dart';
import 'package:toriino_todd/model/review/review_model.dart';
import 'package:toriino_todd/repository/mock/mock_repo.dart';

class MentorListViewmodel extends GetxController {
  final rxMentors = Rx<ApiResponse<MentorListResponse>>(ApiResponse.loading());
  final rxMentorDetail = Rx<ApiResponse<MentorModel>>(ApiResponse.loading());
  final rxAvailability =
      Rx<ApiResponse<List<AvailabilityModel>>>(ApiResponse.loading());
  final rxReviews =
      Rx<ApiResponse<ReviewListResponse>>(ApiResponse.loading());

  RxString selectedExpertise = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMentors();
  }

  void fetchMentors({String? expertise}) {
    rxMentors.value = ApiResponse.loading();
    MockRepo.getMentors(expertise: expertise).then((value) {
      rxMentors.value =
          ApiResponse.success(MentorListResponse.fromJson(value));
    }).onError((error, _) {
      rxMentors.value = ApiResponse.error(error.toString());
    });
  }

  void fetchMentorDetail(String mentorId) {
    rxMentorDetail.value = ApiResponse.loading();
    MockRepo.getMentorById(mentorId).then((value) {
      rxMentorDetail.value =
          ApiResponse.success(MentorModel.fromJson(value));
    }).onError((error, _) {
      rxMentorDetail.value = ApiResponse.error(error.toString());
    });
  }

  void fetchAvailability(String mentorId) {
    rxAvailability.value = ApiResponse.loading();
    MockRepo.getAvailability(mentorId).then((value) {
      final slots = (value['slots'] as List)
          .map((e) => AvailabilityModel.fromJson(e as Map<String, dynamic>))
          .toList();
      rxAvailability.value = ApiResponse.success(slots);
    }).onError((error, _) {
      rxAvailability.value = ApiResponse.error(error.toString());
    });
  }

  void fetchReviews(String mentorId) {
    rxReviews.value = ApiResponse.loading();
    MockRepo.getReviews(mentorId).then((value) {
      rxReviews.value =
          ApiResponse.success(ReviewListResponse.fromJson(value));
    }).onError((error, _) {
      rxReviews.value = ApiResponse.error(error.toString());
    });
  }
}
