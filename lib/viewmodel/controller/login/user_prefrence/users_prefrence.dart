import 'package:getxmvvm/model/login/User_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsersPrefrence {
  Future<bool> saveUser(UserModel userModel) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('accessToken', userModel.accessToken ?? '');
    sp.setString('idToken', userModel.idToken ?? '');
    sp.setString('refreshToken', userModel.refreshToken ?? '');
    sp.setInt('expiresIn', userModel.expiresIn ?? 3600);
    sp.setString('tokenType', userModel.tokenType ?? 'Bearer');
    sp.setInt('tokenSavedAt', DateTime.now().millisecondsSinceEpoch);
    return true;
  }

  Future<String?> getUser() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString('accessToken');
  }

  Future<String?> getRefreshToken() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString('refreshToken');
  }

  Future<String?> getIdToken() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString('idToken');
  }

  Future<bool> isTokenExpired() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    final savedAt = sp.getInt('tokenSavedAt') ?? 0;
    final expiresIn = sp.getInt('expiresIn') ?? 3600;
    final expiryTime = savedAt + (expiresIn * 1000);
    return DateTime.now().millisecondsSinceEpoch > expiryTime;
  }

  Future<bool> saveUserRole(String role) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('userRole', role);
    return true;
  }

  Future<String?> getUserRole() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString('userRole');
  }

  Future<bool> removeUser() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.clear();
    return true;
  }
}
