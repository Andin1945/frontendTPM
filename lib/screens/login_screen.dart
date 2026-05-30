import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/api_auth_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'register_screen.dart';
import 'set_pin_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final accessController = TextEditingController();

  final api = ApiAuthService();
  final auth = AuthService();
  final bio = BiometricService();

  bool loading = false;
  bool hideCode = true;
  bool isLogoutMode = true;

  final Color bgDark = const Color(0xff0F1020);
  final Color cardDark = const Color(0xff1A1B2E);
  final Color fieldDark = const Color(0xff25263A);
  final Color primary = const Color(0xff7C5CFF);
  final Color secondary = const Color(0xff00D1FF);

  @override
  void initState() {
    super.initState();
    checkLoginMode();
  }

  Future<void> checkLoginMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLogoutMode = prefs.getBool("is_logout") ?? true;
      phoneController.text = prefs.getString("phone") ?? "";
    });
  }

  Future<void> login() async {
    final phone = phoneController.text.trim();
    final accessCode = accessController.text.trim();

    if (isLogoutMode && phone.isEmpty) {
      showMessage("Nomor HP wajib diisi setelah logout");
      return;
    }

    if (accessCode.isEmpty) {
      showMessage("Kode akses wajib diisi");
      return;
    }

    setState(() => loading = true);

    try {
      final res = await api.login(
        accessCode: accessCode,
        phone: isLogoutMode ? phone : null,
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (res["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        final user = res["user"] ?? {};
        final token = res["token"] ?? "";

        final hasPin =
            user["pin_hash"] != null && user["pin_hash"].toString().isNotEmpty;

        final bioEnabled = user["biometric_enabled"] == 1 ||
            user["biometric_enabled"] == true ||
            user["biometric_enabled"].toString() == "1";

        await prefs.setBool("isLogin", true);
        await prefs.setBool("is_logout", false);
        await prefs.setString("token", token);
        await prefs.setInt("user_id", user["id"] ?? 1);
        await prefs.setString("username", user["username"] ?? "");
        await prefs.setString("email", user["email"] ?? "");
        await prefs.setString("phone", user["phone"] ?? phone);
        await prefs.setBool("has_pin", hasPin);
        await prefs.setBool("biometric_enabled", bioEnabled);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => hasPin ? MainPage() : SetPinScreen(),
          ),
          (route) => false,
        );
      } else {
        showMessage(res["message"] ?? "Login gagal");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage("Gagal konek ke server. Pastikan backend aktif.");
    }
  }

  Future<void> biometricLogin() async {
    final enabled = await auth.isBiometricEnabled();

    if (!enabled) {
      showMessage("Aktifkan sidik jari dulu di Profil");
      return;
    }

    final success = await bio.authenticate();

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final hasPin = prefs.getBool("has_pin") ?? false;

      if (token != null && token.isNotEmpty) {
        await prefs.setBool("isLogin", true);
        await prefs.setBool("is_logout", false);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => hasPin ? MainPage() : SetPinScreen(),
          ),
          (route) => false,
        );
      } else {
        showMessage("Login kode akses dulu sebelum biometric");
      }
    } else {
      showMessage("Biometric gagal");
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardDark,
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: fieldDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    accessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff0F1020),
              Color(0xff17182F),
              Color(0xff111827),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: cardDark.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.28),
                      blurRadius: 34,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [primary, secondary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.45),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "SmartPay AI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogoutMode
                          ? "Login dengan nomor HP dan kode akses"
                          : "Login cepat dengan kode akses",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 32),

                    if (isLogoutMode) ...[
                      inputField(
                        controller: phoneController,
                        label: "Nomor HP",
                        icon: Icons.phone_android,
                      ),
                      const SizedBox(height: 14),
                    ],

                    inputField(
                      controller: accessController,
                      label: "Kode Akses",
                      icon: Icons.key,
                      obscure: hideCode,
                      suffix: IconButton(
                        icon: Icon(
                          hideCode ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() => hideCode = !hideCode);
                        },
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: loading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : biometricLogin,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text("Login dengan Fingerprint"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: secondary,
                          side: BorderSide(color: secondary.withOpacity(0.8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Belum punya akun?",
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegisterScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}