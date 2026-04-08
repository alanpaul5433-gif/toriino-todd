import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/repository/auth_repo.dart';
import 'package:getxmvvm/utils/utils.dart';

class SignupViewmodel extends GetxController {
  final _authRepo = AuthRepo();

  final nameController = TextEditingController().obs;
  final emailController = TextEditingController().obs;
  final phoneController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;

  final nameFocusNode = FocusNode().obs;
  final emailFocusNode = FocusNode().obs;
  final phoneFocusNode = FocusNode().obs;
  final passwordFocusNode = FocusNode().obs;

  RxBool loading = false.obs;

  void registerApi() {
    loading.value = true;

    Map<String, dynamic> data = {
      'name': nameController.value.text,
      'email': emailController.value.text,
      'phone': phoneController.value.text,
      'password': passwordController.value.text,
    };

    _authRepo
        .registerApi(data)
        .then((value) {
          loading.value = false;
          Utils.toastMassage("Registration successful. Please verify your email.");
          // Navigate to OTP verification screen
          Get.toNamed('/otp_verify', arguments: {
            'email': emailController.value.text,
          });
        })
        .onError((error, stackTrace) {
          loading.value = false;
          if (kDebugMode) print(error.toString());
          Utils.toastMassage(error.toString());
        });
  }

  @override
  void onClose() {
    nameController.value.dispose();
    emailController.value.dispose();
    phoneController.value.dispose();
    passwordController.value.dispose();
    nameFocusNode.value.dispose();
    emailFocusNode.value.dispose();
    phoneFocusNode.value.dispose();
    passwordFocusNode.value.dispose();
    super.onClose();
  }
}
