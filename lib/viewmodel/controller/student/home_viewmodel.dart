import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/user/user_profile_model.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/mentor/mentor_model.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/repository/mentor_repo.dart';
import 'package:toriino_todd/repository/session_repo.dart';

class HomeViewmodel extends GetxController {
  final _userRepo = UserRepo();
  final _courseRepo = CourseRepo();
  final _mentorRepo = MentorRepo();
  final _sessionRepo = SessionRepo();

  final rxProfile = Rx<ApiResponse<UserProfileModel>>(ApiResponse.loading());
  final rxCourses = Rx<ApiResponse<CourseListResponse>>(ApiResponse.loading());
  final rxMentors = Rx<ApiResponse<MentorListResponse>>(ApiResponse.loading());
  final rxSessionCount = 0.obs;

  String? _lastCourseKey;
  bool get hasMoreCourses => _lastCourseKey != null;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  void fetchAll() {
    fetchProfile();
    fetchCourses();
    fetchMentors();
    fetchSessionCount();
  }

  void fetchProfile() {
    rxProfile.value = ApiResponse.loading();
    _userRepo.getProfile().then((value) {
      rxProfile.value = ApiResponse.success(UserProfileModel.fromJson(value));
    }).onError((error, _) {
      rxProfile.value = ApiResponse.error(error.toString());
    });
  }

  void fetchCourses({bool loadMore = false}) {
    if (!loadMore) {
      _lastCourseKey = null;
      rxCourses.value = ApiResponse.loading();
    }
    _courseRepo.getCourses(lastKey: loadMore ? _lastCourseKey : null).then((value) {
      final response = CourseListResponse.fromJson(value);
      if (loadMore) {
        final existing = rxCourses.value.data?.courses ?? [];
        rxCourses.value = ApiResponse.success(CourseListResponse(
          courses: [...existing, ...response.courses],
          count: response.count,
        ));
      } else {
        rxCourses.value = ApiResponse.success(response);
      }
      _lastCourseKey = value['lastKey'] as String?;
    }).onError((error, _) {
      rxCourses.value = ApiResponse.error(error.toString());
    });
  }

  void fetchMentors() {
    rxMentors.value = ApiResponse.loading();
    _mentorRepo.getMentors().then((value) {
      rxMentors.value = ApiResponse.success(MentorListResponse.fromJson(value));
    }).onError((error, _) {
      rxMentors.value = ApiResponse.error(error.toString());
    });
  }

  void fetchSessionCount() {
    _sessionRepo.getSessions(role: 'student').then((value) {
      final list = SessionListResponse.fromJson(value);
      rxSessionCount.value = list.sessions.length;
    }).catchError((_) {});
  }
}
