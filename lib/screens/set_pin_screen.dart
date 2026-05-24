import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/transaction_service.dart';
import '../main.dart';

class SetPinScreen extends StatefulWidget {
  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final pinController = TextEditingController();
  final confirmController = TextEditingController();
  final service = TransactionService();

  bool loading = false;
  bool hidePin = true;

  Future<void> savePin() async {
    final pin = pinController.text.trim();
    final confirm = confirmController.text.trim();

    if (pin.length != 6 || confirm.length != 6) {
      showMessage("PIN harus 6 digit");
      return;
    }

    if (pin != confirm) {
      showMessage("Konfirmasi PIN tidak sama");
      return;
    }

    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id") ?? 1;

    final res = await service.setPin(userId: userId, pin: pin);

    setState(() => loading = false);

    if (res["success"] == true) {
      await prefs.setBool("has_pin", true);

      showMessage("PIN berhasil dibuat");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainPage()),
        (route) => false,
      );
    } else {
      showMessage(res["message"] ?? "Gagal membuat PIN");
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffdfeaff),
      appBar: AppBar(title: const Text("Buat PIN")),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 18),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xffe9f2ff),
                    child: Icon(
                      Icons.lock,
                      color: Color(0xff5146b8),
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Buat PIN SmartPay",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "PIN digunakan untuk konfirmasi transfer",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 28),

                  TextField(
                    controller: pinController,
                    obscureText: hidePin,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "PIN 6 digit",
                      prefixIcon: const Icon(Icons.pin),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePin ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => hidePin = !hidePin);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: confirmController,
                    obscureText: hidePin,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Konfirmasi PIN",
                      prefixIcon: const Icon(Icons.verified_user),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : savePin,
                      icon: const Icon(Icons.check),
                      label: loading
                          ? const Text("Menyimpan...")
                          : const Text("Simpan PIN"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff5146b8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}