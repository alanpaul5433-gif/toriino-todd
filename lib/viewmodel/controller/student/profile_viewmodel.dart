import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/user/user_profile_model.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/utils/utils.dart';

class ProfileViewmodel extends GetxController {
  final _userRepo = UserRepo();

  final rxProfile = Rx<ApiResponse<UserProfileModel>>(ApiResponse.loading());

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final locationController = TextEditingController();

  RxBool saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  void fetchProfile() {
    rxProfile.value = ApiResponse.loading();
    _userRepo.getProfile().then((value) {
      final profile = UserProfileModel.fromJson(value);
      rxProfile.value = ApiResponse.success(profile);
      nameController.text = profile.name ?? '';
      phoneController.text = profile.phone ?? '';
      bioController.text = profile.bio ?? '';
      locationController.text = profile.location ?? '';
    }).onError((error, _) {
      rxProfile.value = ApiResponse.error(Utils.errorMessage(error));
    });
  }

  void updateProfile() {
    saving.value = true;
    Map<String, dynamic> data = {
      'name': nameController.text,
      'phone': phoneController.text,
      'bio': bioController.text,
      'location': locationController.text,
    };

    _userRepo.updateProfile(data).then((value) {
      saving.value = false;
      Utils.toastMassage("Profile updated");
      fetchProfile();
    }).onError((error, _) {
      saving.value = false;
      Utils.toastMassage(Utils.errorMessage(error));
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    bioController.dispose();
    locationController.dispose();
    super.onClose();
  }
}
