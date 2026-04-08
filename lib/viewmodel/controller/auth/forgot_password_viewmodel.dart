import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/repository/auth_repo.dart';
import 'package:getxmvvm/utils/utils.dart';

class ForgotPasswordViewmodel extends GetxController {
  final _authRepo = AuthRepo();

  final emailController = TextEditingController().obs;
  final codeController = TextEditingController().obs;
  final newPasswordController = TextEditingController().obs;

  RxBool loading = false.obs;
  RxBool codeSent = false.obs;

  void sendResetCode() {
    loading.value = true;

    _authRepo
        .forgotPasswordApi({'email': emailController.value.text})
        .then((value) {
          loading.value = false;
          codeSent.value = true;
          Utils.toastMassage("Reset code sent to your email");
        })
        .onError((error, stackTrace) {
          loading.value = false;
          if (kDebugMode) print(error.toString());
          Utils.toastMassage(error.toString());
        });
  }

  void resetPassword() {
    loading.value = true;

    Map<String, dynamic> data = {
      'email': emailController.value.text,
      'code': codeController.value.text,
      'newPassword': newPasswordController.value.text,
    };

    _authRepo
        .resetPasswordApi(data)
        .then((value) {
          loading.value = false;
          Utils.toastMassage("Password reset successfully");
          Get.back();
        })
        .onError((error, stackTrace) {
          loading.value = false;
          if (kDebugMode) print(error.toString());
          Utils.toastMassage(error.toString());
        });
  }

  @override
  void onClose() {
    emailController.value.dispose();
    codeController.value.dispose();
    newPasswordController.value.dispose();
    super.onClose();
  }
}
