import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_auth_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final api = ApiAuthService();
  final auth = AuthService();
  final bio = BiometricService();
  final picker = ImagePicker();

  int userId = 1;
  String username = "-";
  String email = "-";
  String phone = "-";
  bool biometricEnabled = false;

  File? imageFile;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt("user_id") ?? 1;

    final res = await api.getProfile(userId);

    if (res["success"] == true) {
      final user = res["user"];

      setState(() {
        username = user["username"] ?? "-";
        email = user["email"] ?? "-";
        phone = user["phone"] == null || user["phone"].toString().isEmpty
            ? "-"
            : user["phone"].toString();
      });
    }

    final bioStatus = await auth.isBiometricEnabled();
    setState(() => biometricEnabled = bioStatus);
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> setupBiometric() async {
    final success = await bio.authenticate();

    if (success) {
      await auth.setBiometricEnabled(true);
      await api.setBiometric(userId: userId, enabled: true);
      setState(() => biometricEnabled = true);
      message("Sidik jari berhasil diaktifkan");
    } else {
      message("Verifikasi sidik jari gagal");
    }
  }

  Future<void> disableBiometric() async {
    await auth.setBiometricEnabled(false);
    await api.setBiometric(userId: userId, enabled: false);
    setState(() => biometricEnabled = false);
    message("Sidik jari dinonaktifkan");
  }

  void showBiometricSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xffe9f2ff),
                child: Icon(
                  Icons.fingerprint,
                  size: 54,
                  color: Color(0xff5146b8),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Pengaturan Sidik Jari",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                biometricEnabled
                    ? "Sidik jari aktif untuk login cepat."
                    : "Aktifkan sidik jari untuk keamanan dan login cepat.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      biometricEnabled ? disableBiometric : setupBiometric,
                  icon: Icon(
                    biometricEnabled ? Icons.close : Icons.fingerprint,
                  ),
                  label: Text(
                    biometricEnabled ? "Nonaktifkan" : "Aktifkan Sidik Jari",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        biometricEnabled ? Colors.red : const Color(0xff5146b8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> logout() async {
    await auth.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  void confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = const Color(0xff5146b8),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? getProfileImage() {
    if (imageFile != null) return FileImage(imageFile!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef4ff),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: const Color(0xff5146b8),
            title: const Text("Profil"),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff5146b8),
                      Color(0xff7b8cff),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 62,
                            backgroundColor: Colors.white24,
                            backgroundImage: getProfileImage(),
                            child: imageFile == null
                                ? const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 4,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Color(0xff5146b8),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "SmartPay AI User",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            infoCard(
                              icon: Icons.email,
                              title: "Email",
                              value: email,
                            ),
                            const SizedBox(width: 12),
                            infoCard(
                              icon: Icons.phone_android,
                              title: "Nomor HP",
                              value: phone,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Keamanan Akun",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  menuCard(
                    icon: Icons.fingerprint,
                    title: biometricEnabled
                        ? "Sidik Jari Aktif"
                        : "Aktifkan Sidik Jari",
                    subtitle: biometricEnabled
                        ? "Login cepat menggunakan fingerprint"
                        : "Tambahkan keamanan biometrik",
                    onTap: showBiometricSheet,
                  ),

                  menuCard(
                    icon: Icons.pin,
                    title: "Ganti PIN",
                    subtitle: "Ubah PIN transaksi 6 digit",
                    onTap: () {
                      message("Fitur ganti PIN dibuka dari halaman ini");
                    },
                  ),

                  menuCard(
                    icon: Icons.lock,
                    title: "Ganti Kode Akses",
                    subtitle: "Perbarui kode akses login akun",
                    onTap: () {
                      message("Fitur ganti kode akses dibuka dari halaman ini");
                    },
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    "Akun",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  menuCard(
                    icon: Icons.logout,
                    title: "Logout",
                    subtitle: "Keluar dan masuk menggunakan akun lain",
                    color: Colors.red,
                    onTap: confirmLogout,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}