import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final isLogin = prefs.getBool("isLogin") ?? false;
    final token = prefs.getString("token");

    return isLogin && token != null && token.isNotEmpty;
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("biometric_enabled") ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("biometric_enabled", value);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("isLogin", false);
    await prefs.setBool("is_logout", true);

    // Jangan hapus token, phone, dan biometric_enabled
    // supaya fingerprint masih bisa dipakai setelah logout.
  }
}
