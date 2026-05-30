import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/transaction_service.dart';

class QRISScreen extends StatefulWidget {
  const QRISScreen({super.key});

  @override
  State<QRISScreen> createState() => _QRISScreenState();
}

class _QRISScreenState extends State<QRISScreen> {
  final amountController = TextEditingController();
  final pinController = TextEditingController();
  final service = TransactionService();

  int userId = 1;
  String username = "User";
  String phone = "-";

  bool scanned = false;
  bool loading = false;

  String receiverName = "";
  String receiverPhone = "";

  final bgDark = const Color(0xff0F1020);
  final cardDark = const Color(0xff1A1B2E);
  final fieldDark = const Color(0xff25263A);
  final primary = const Color(0xff7C5CFF);
  final secondary = const Color(0xff00D1FF);

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userId = prefs.getInt("user_id") ?? 1;
      username = prefs.getString("username") ?? "User";
      phone = prefs.getString("phone") ?? "-";
    });
  }

  String get myQRData {
    return jsonEncode({
      "type": "SMARTPAY_QRIS",
      "name": username,
      "phone": phone,
    });
  }

  void onDetect(BarcodeCapture capture) {
    if (scanned) return;

    final value = capture.barcodes.first.rawValue;
    if (value == null) return;

    try {
      final data = jsonDecode(value);

      if (data["type"] != "SMARTPAY_QRIS") {
        message("QR tidak valid");
        return;
      }

      final targetPhone = data["phone"].toString();

      if (targetPhone == phone) {
        message("Tidak bisa bayar ke QR sendiri");
        return;
      }

      setState(() {
        scanned = true;
        receiverName = data["name"].toString();
        receiverPhone = targetPhone;
      });
    } catch (e) {
      message("QR tidak terbaca");
    }
  }

  Future<void> payQRIS() async {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final pin = pinController.text.trim();

    if (receiverPhone.isEmpty) {
      message("Scan QR terlebih dahulu");
      return;
    }

    if (amount <= 0) {
      message("Nominal tidak valid");
      return;
    }

    if (pin.length != 6) {
      message("PIN harus 6 digit");
      return;
    }

    setState(() => loading = true);

 final success = await service.qrisPayBool(
  userId: userId,
  receiverPhone: receiverPhone,
  amount: amount,
  pin: pin,
);

    setState(() => loading = false);

    if (success) {
      message("Pembayaran QRIS berhasil");
      Navigator.pop(context, true);
    } else {
      message("Pembayaran gagal. Cek saldo/PIN/nomor penerima.");
    }
  }

  void resetScan() {
    setState(() {
      scanned = false;
      receiverName = "";
      receiverPhone = "";
      amountController.clear();
      pinController.clear();
    });
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: cardDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: secondary),
        filled: true,
        fillColor: fieldDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text("QRIS SmartPay"),
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text(
                    "QR Akun Saya",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: QrImageView(
                      data: myQRData,
                      version: QrVersions.auto,
                      size: 210,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "$username • $phone",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              height: 260,
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: scanned
                    ? Center(
                        child: Icon(
                          Icons.check_circle,
                          color: secondary,
                          size: 80,
                        ),
                      )
                    : MobileScanner(
                        onDetect: onDetect,
                      ),
              ),
            ),

            const SizedBox(height: 18),

            if (scanned)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primary.withOpacity(0.2),
                          child: Icon(Icons.store, color: secondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "$receiverName\n$receiverPhone",
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: resetScan,
                          icon: const Icon(Icons.refresh, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    input(
                      controller: amountController,
                      label: "Nominal pembayaran",
                      icon: Icons.payments,
                    ),
                    const SizedBox(height: 12),
                    input(
                      controller: pinController,
                      label: "PIN 6 digit",
                      icon: Icons.lock,
                      obscure: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : payQRIS,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Bayar QRIS"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
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

  @override
  void dispose() {
    amountController.dispose();
    pinController.dispose();
    super.dispose();
  }
}