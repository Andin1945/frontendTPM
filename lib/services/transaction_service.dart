import 'dart:convert';
import 'package:http/http.dart' as http;

class TransactionService {
  static const String baseUrl = "http://192.168.0.108:3000";

  Future<List<dynamic>> getTransactions(int userId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/transactions/$userId"));
      final data = jsonDecode(res.body);
      return data["success"] == true ? data["data"] : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addTransaction({
    required int userId,
    required String title,
    required double amount,
    required String type,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/transactions"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "title": title,
          "amount": amount,
          "type": type,
        }),
      );

      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final res = await http.delete(Uri.parse("$baseUrl/transactions/$id"));
      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> transfer({
    required int userId,
    required String phone,
    required double amount,
    required String note,
    required String pin,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/transfer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "phone": phone,
          "amount": amount,
          "note": note,
          "pin": pin,
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
        "message": "Gagal set PIN",
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
}
