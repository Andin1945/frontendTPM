import 'dart:convert';
import 'package:http/http.dart' as http;

class ConversionService {
  Future<double?> convert(String from, String to, double amount) async {
    try {
      if (from == to) return amount;

      final url = "https://open.er-api.com/v6/latest/$from";
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rate = data["rates"][to];

        if (rate == null) return null;

        return amount * (rate as num).toDouble();
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}