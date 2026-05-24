import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/transaction_service.dart';
import '../services/notification_service.dart';

class TransferScreen extends StatefulWidget {
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final phoneController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final pinController = TextEditingController();

  final service = TransactionService();

  bool loading = false;

  String formatRupiah(String value) {
    if (value.isEmpty) return "0";
    return value.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => "${m[1]}.",
    );
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> confirmPin() async {
    final phone = phoneController.text.trim();
    final amount = amountController.text.trim();

    if (phone.isEmpty || amount.isEmpty) {
      showMessage("Nomor tujuan dan nominal wajib diisi");
      return;
    }

    pinController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text("Masukkan PIN"),
          content: TextField(
            controller: pinController,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: "PIN SmartPay",
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff5146b8),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (pinController.text.length != 6) {
                  showMessage("PIN harus 6 digit");
                  return;
                }

                Navigator.pop(context);
                transfer();
              },
              child: const Text("Konfirmasi"),
            ),
          ],
        );
      },
    );
  }

  Future<void> transfer() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id") ?? 1;

    final phone = phoneController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final note = noteController.text.trim();

    if (phone.isEmpty || amount <= 0) {
      showMessage("Data transfer tidak valid");
      return;
    }

    setState(() => loading = true);

    final res = await service.transfer(
      userId: userId,
      phone: phone,
      amount: amount,
      note: note,
      pin: pinController.text,
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (res["success"] == true) {
      await NotificationService.showTransferSuccess(
        phone,
        formatRupiah(amount.toStringAsFixed(0)),
      );

      showSuccessDialog(phone, amount);
    } else {
      showMessage(res["message"] ?? "Transfer gagal");
    }
  }

  void showSuccessDialog(String phone, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 58,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Transfer Berhasil",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Rp${formatRupiah(amount.toStringAsFixed(0))}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff5146b8),
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Berhasil dikirim ke"),
                Text(
                  phone,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffe9f2ff),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Color(0xff5146b8),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text("Notifikasi transaksi masuk ke perangkat."),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff5146b8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    },
                    child: const Text("Selesai"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    amountController.dispose();
    noteController.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountText = formatRupiah(amountController.text);

    return Scaffold(
      backgroundColor: const Color(0xffdfeaff),
      appBar: AppBar(title: const Text("Transfer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff8fb0ff),
                    Color(0xff5146b8),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.send_to_mobile, color: Colors.white, size: 42),
                  SizedBox(height: 12),
                  Text(
                    "Transfer SmartPay",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Kirim saldo dengan PIN keamanan",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 14),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: "Nomor HP / ID E-Wallet",
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: "Nominal Transfer",
                      prefixIcon: const Icon(Icons.payments),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xffe9f2ff),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Transfer"),
                        const SizedBox(height: 6),
                        Text(
                          "Rp$amountText",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff5146b8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Catatan",
                      prefixIcon: const Icon(Icons.note_alt),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : confirmPin,
                      icon: const Icon(Icons.lock),
                      label: loading
                          ? const Text("Memproses...")
                          : const Text("Lanjutkan Transfer"),
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

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Color(0xff5146b8)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "PIN diverifikasi dari MySQL API dan transaksi tersimpan ke server.",
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
}