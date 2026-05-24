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
      SnackBar(content: Text(text)),
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
      backgroundColor: const Color(0xffdfeaff),
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
                    radius: 48,
                    backgroundColor: Color(0xffe9f2ff),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 52,
                      color: Color(0xff5146b8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "SmartPay AI",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLogoutMode
                        ? "Login dengan nomor HP dan kode akses"
                        : "Login cukup dengan kode akses",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 28),

                  if (isLogoutMode) ...[
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: "Nomor HP",
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextField(
                    controller: accessController,
                    obscureText: hideCode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: "Kode Akses",
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hideCode ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => hideCode = !hideCode);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff5146b8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : biometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text("Login dengan Fingerprint"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff5146b8),
                        side: const BorderSide(color: Color(0xff5146b8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum punya akun?"),
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
                        child: const Text("Register"),
                      ),
                    ],
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