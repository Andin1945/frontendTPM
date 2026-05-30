import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiAuthService {
  static const String baseUrl = "http://192.168.0.100:3000";

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String phone,
    required String accessCode,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "phone": phone,
          "access_code": accessCode,
        }),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Tidak bisa konek ke server",
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String accessCode,
    String? phone,
  }) async {
    try {
      final body = {
        "access_code": accessCode,
      };

      if (phone != null && phone.isNotEmpty) {
        body["phone"] = phone;
      }

      final res = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Tidak bisa konek ke server",
      };
    }
  }

  Future<Map<String, dynamic>> getProfile(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/profile/$userId"),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Gagal mengambil profil",
      };
    }
  }

  Future<Map<String, dynamic>> setPhone({
    required int userId,
    required String phone,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/set-phone"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "phone": phone,
        }),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Gagal menyimpan nomor HP",
      };
    }
  }

  Future<Map<String, dynamic>> changeAccessCode({
    required int userId,
    required String oldCode,
    required String newCode,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/change-access-code"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "old_code": oldCode,
          "new_code": newCode,
        }),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Gagal ganti kode akses",
      };
    }
  }

  Future<Map<String, dynamic>> changePin({
    required int userId,
    required String oldPin,
    required String newPin,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/change-pin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "old_pin": oldPin,
          "new_pin": newPin,
        }),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Gagal ganti PIN",
      };
    }
  }

  Future<Map<String, dynamic>> setPin({
    required int userId,
    required String pin,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/set-pin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "pin": pin,
        }),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Gagal membuat PIN",
      };
    }
  }

  Future<Map<String, dynamic>> setBiometric({
    required int userId,
    required bool enabled,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/set-biometric"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "enabled": enabled,
        }),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Gagal update biometric",
      };
    }
  }
}