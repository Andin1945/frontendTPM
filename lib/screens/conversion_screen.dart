import 'package:flutter/material.dart';
import '../services/conversion_service.dart';

class ConversionScreen extends StatefulWidget {
  @override
  State<ConversionScreen> createState() => _ConversionScreenState();
}

class _ConversionScreenState extends State<ConversionScreen> {
  final service = ConversionService();
  final amountController = TextEditingController();

  String from = "IDR";
  String to = "USD";

  double? result;
  bool loading = false;

  Future<void> convertCurrency() async {
    String raw = amountController.text.trim();

    // FIX: biar 17.000 jadi 17000
    raw = raw.replaceAll(".", "").replaceAll(",", ".");

    final amount = double.tryParse(raw) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Masukkan jumlah yang valid")),
      );
      return;
    }

    setState(() => loading = true);

    final res = await service.convert(from, to, amount);

    setState(() {
      result = res;
      loading = false;
    });
  }

  String formatResult(double value) {
    // IDR tidak perlu desimal
    if (to == "IDR") {
      return value.toStringAsFixed(0);
    }
    // USD/EUR pakai 4 digit biar gak jadi 0.00
    return value.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffdfeaff),
      appBar: AppBar(title: Text("Konversi")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  Icon(Icons.currency_exchange,
                      size: 60, color: Color(0xff5146b8)),

                  SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Jumlah uang",
                      prefixIcon: Icon(Icons.payments),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                          child: _dropdown(from,
                              (v) => setState(() => from = v!))),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward,
                          color: Color(0xff5146b8)),
                      SizedBox(width: 12),
                      Expanded(
                          child:
                              _dropdown(to, (v) => setState(() => to = v!))),
                    ],
                  ),

                  SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : convertCurrency,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff5146b8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: loading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Konversi via API"),
                    ),
                  ),

                  SizedBox(height: 20),

                  if (result != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Color(0xff8fb0ff),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        "$from ${amountController.text} = $to ${formatResult(result!)}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      items: ["IDR", "USD", "EUR"]
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}