import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl = "http://192.168.0.100:3000";

  Future<String> askAI({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/ai/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": message,
          "history": history,
        }),
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        return data["reply"] ?? "AI tidak memberi jawaban";
      }

      return data["message"] ?? "AI gagal merespon";
    } catch (e) {
      return "Tidak dapat terhubung ke AI";
    }
  }
}