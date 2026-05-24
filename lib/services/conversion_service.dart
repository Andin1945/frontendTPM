import 'dart:convert';
import 'package:http/http.dart' as http;

class ConversionService {
  Future<double> convert(String from, String to, double amount) async {
    final res = await http.get(
      Uri.parse("https://api.exchangerate-api.com/v4/latest/$from"),
    );

    final data = jsonDecode(res.body);
    final rate = data["rates"][to];

    return amount * rate;
  }
}