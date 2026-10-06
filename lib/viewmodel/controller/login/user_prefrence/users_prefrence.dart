import 'package:shared_preferences/shared_preferences.dart';

class UsersPrefrence {
  Future<bool> saveUserRole(String role) async {
    final sp = await SharedPreferences.getInstance();
    sp.setString('userRole', role);
    return true;
  }

  Future<String?> getUserRole() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('userRole');
  }

  Future<bool> removeUser() async {
    final sp = await SharedPreferences.getInstance();
    sp.clear();
    return true;
  }
}
