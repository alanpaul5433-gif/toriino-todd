// controllers/custom_drawer_controller.dart
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:get/get.dart';

class CustomDrawerController extends GetxController {
  final AdvancedDrawerController advancedDrawerController = AdvancedDrawerController();
  var currentIndex = 0.obs;

  void showDrawer() {
    advancedDrawerController.showDrawer();
  }

  void hideDrawer() {
    advancedDrawerController.hideDrawer();
  }

  void toggleDrawer() {
    advancedDrawerController.toggleDrawer();
  }

  void changeIndex(int index) {
    currentIndex.value = index;
  }
}