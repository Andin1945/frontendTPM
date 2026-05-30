import 'dart:async';
import 'package:flutter/material.dart';
import '../services/conversion_service.dart';

class ConversionScreen extends StatefulWidget {
  const ConversionScreen({super.key});

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

  Timer? timer;
  DateTime now = DateTime.now();

  final Color bgDark = const Color(0xff0F1020);
  final Color cardDark = const Color(0xff1A1B2E);
  final Color fieldDark = const Color(0xff25263A);
  final Color primary = const Color(0xff7C5CFF);
  final Color secondary = const Color(0xff00D1FF);

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() {
          now = DateTime.now().toUtc();
        });
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    amountController.dispose();
    super.dispose();
  }

  Future<void> convertCurrency() async {
    String raw = amountController.text.trim();

    raw = raw.replaceAll(".", "").replaceAll(",", ".");

    final amount = double.tryParse(raw) ?? 0;

    if (amount <= 0) {
      message("Masukkan jumlah yang valid");
      return;
    }

    setState(() => loading = true);

    final res = await service.convert(
      from,
      to,
      amount,
    );

    if (!mounted) return;

    setState(() {
      result = res;
      loading = false;
    });

    if (res == null) {
      message("Gagal mengambil data kurs");
    }
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

  String formatResult(double value) {
    if (to == "IDR") {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(4);
  }

  String timeFormat(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, "0");
    final m = dt.minute.toString().padLeft(2, "0");
    final s = dt.second.toString().padLeft(2, "0");

    return "$h:$m:$s";
  }

  Widget dropdown(
    String value,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: fieldDark,
      style: const TextStyle(color: Colors.white),

      decoration: InputDecoration(
        filled: true,
        fillColor: fieldDark,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),

      items: [
        "IDR",
        "USD",
        "EUR",
        "GBP",
        "JPY",
        "AUD",
        "SGD",
        "MYR",
      ]
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),

      onChanged: onChanged,
    );
  }

  Widget timeCard(
    String title,
    String time,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: fieldDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),

        child: Column(
          children: [
            Icon(icon, color: secondary),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wib = now.add(const Duration(hours: 7));
    final wita = now.add(const Duration(hours: 8));
    final wit = now.add(const Duration(hours: 9));
    final london = now;

    return Scaffold(
      backgroundColor: bgDark,

      appBar: AppBar(
        title: const Text("Konversi"),
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary,
                    const Color(0xff14162E),
                    secondary.withOpacity(0.65),
                  ],

                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.circular(34),

                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.28),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),

              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.14),
                    ),

                    child: const Icon(
                      Icons.currency_exchange,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Smart Conversion",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Konversi mata uang dan waktu dunia",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 26),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,

                    style: const TextStyle(
                      color: Colors.white,
                    ),

                    decoration: InputDecoration(
                      labelText: "Jumlah uang",

                      labelStyle: const TextStyle(
                        color: Colors.white54,
                      ),

                      prefixIcon: Icon(
                        Icons.payments,
                        color: secondary,
                      ),

                      filled: true,
                      fillColor: fieldDark,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: dropdown(
                          from,
                          (v) => setState(() => from = v!),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),

                        child: Icon(
                          Icons.swap_horiz,
                          color: secondary,
                          size: 32,
                        ),
                      ),

                      Expanded(
                        child: dropdown(
                          to,
                          (v) => setState(() => to = v!),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 56,

                    child: ElevatedButton.icon(
                      onPressed:
                          loading ? null : convertCurrency,

                      icon: const Icon(
                        Icons.currency_exchange,
                      ),

                      label: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Konversi",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondary,
                        foregroundColor: Colors.black,
                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  if (result != null) ...[
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),

                        borderRadius:
                            BorderRadius.circular(24),

                        border: Border.all(
                          color: Colors.white10,
                        ),
                      ),

                      child: Column(
                        children: [
                          const Text(
                            "HASIL KONVERSI",
                            style: TextStyle(
                              color: Colors.white54,
                              letterSpacing: 1,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "$from ${amountController.text}",
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Icon(
                            Icons.arrow_downward,
                            color: secondary,
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "$to ${formatResult(result!)}",
                            style: TextStyle(
                              color: secondary,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: secondary,
                      ),

                      const SizedBox(width: 10),

                      const Text(
                        "Waktu Dunia",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      timeCard(
                        "WIB",
                        timeFormat(wib),
                        Icons.access_time,
                      ),

                      timeCard(
                        "WITA",
                        timeFormat(wita),
                        Icons.schedule,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      timeCard(
                        "WIT",
                        timeFormat(wit),
                        Icons.watch_later,
                      ),

                      timeCard(
                        "London",
                        timeFormat(london),
                        Icons.public,
                      ),
                    ],
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