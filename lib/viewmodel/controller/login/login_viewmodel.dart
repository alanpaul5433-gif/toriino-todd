import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/model/login/User_model.dart';
import 'package:getxmvvm/repository/auth_repo.dart';
import 'package:getxmvvm/resources/routes/routes_name.dart';
import 'package:getxmvvm/utils/utils.dart';
import 'package:getxmvvm/viewmodel/controller/login/user_prefrence/users_prefrence.dart';

class LoginViewmodel extends GetxController {
  UsersPrefrence usersPrefrence = UsersPrefrence();
  final _authRepo = AuthRepo();
  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;

  final emailFocusNode = FocusNode().obs;
  final passwordFocusNode = FocusNode().obs;

  RxBool loading = false.obs;

  void loginApi() {
    loading.value = true;
    Map<String, dynamic> data = {
      'email': emailController.value.text,
      'password': passwordController.value.text,
    };

    _authRepo
        .loginApi(data)
        .then((value) {
          loading.value = false;
          usersPrefrence
              .saveUser(UserModel.fromJson(value))
              .then((value) {
                Get.offAllNamed(RoutesName.homeview);
              })
              .onError((error, stackTrace) {
                if (kDebugMode) {
                  print(error.toString());
                }
              });
          Utils.toastMassage("Login Successfully");
        })
        .onError((error, stackTrace) {
          loading.value = false;
          Utils.toastMassage(error.toString());
        });
  }

  @override
  void onClose() {
    emailController.value.dispose();
    passwordController.value.dispose();
    emailFocusNode.value.dispose();
    passwordFocusNode.value.dispose();
    super.onClose();
  }
}
