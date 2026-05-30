import 'dart:convert';
import 'dart:typed_data';

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

  Uint8List? profileBytes;

  final bgDark = const Color(0xff0F1020);
  final cardDark = const Color(0xff1A1B2E);
  final fieldDark = const Color(0xff25263A);
  final primary = const Color(0xff7C5CFF);
  final secondary = const Color(0xff00D1FF);

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt("user_id") ?? 1;

    final savedPhoto = prefs.getString("profile_photo_$userId");
    if (savedPhoto != null && savedPhoto.isNotEmpty) {
      profileBytes = base64Decode(savedPhoto);
    }

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
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final base64Image = base64Encode(bytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_photo_$userId", base64Image);

    setState(() => profileBytes = bytes);
    message("Foto profil berhasil disimpan");
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardDark,
      ),
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
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fingerprint, size: 60, color: secondary),
              const SizedBox(height: 14),
              const Text(
                "Pengaturan Sidik Jari",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                biometricEnabled
                    ? "Sidik jari aktif untuk login cepat."
                    : "Aktifkan sidik jari untuk keamanan akun.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 22),
              _button(
                biometricEnabled ? "Nonaktifkan Sidik Jari" : "Aktifkan Sidik Jari",
                biometricEnabled ? disableBiometric : setupBiometric,
                color: biometricEnabled ? Colors.redAccent : primary,
              ),
            ],
          ),
        );
      },
    );
  }

  void showChangePinSheet() {
    final oldPin = TextEditingController();
    final newPin = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _formSheet(
          title: "Ganti PIN",
          icon: Icons.pin,
          children: [
            _input(oldPin, "PIN Lama"),
            const SizedBox(height: 12),
            _input(newPin, "PIN Baru"),
            const SizedBox(height: 18),
            _button("Simpan PIN", () async {
              if (oldPin.text.length != 6 || newPin.text.length != 6) {
                message("PIN harus 6 digit");
                return;
              }

              final res = await api.changePin(
                userId: userId,
                oldPin: oldPin.text.trim(),
                newPin: newPin.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);
              message(res["message"] ?? "Selesai");
            }),
          ],
        );
      },
    );
  }

  void showChangeAccessCodeSheet() {
    final oldCode = TextEditingController();
    final newCode = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _formSheet(
          title: "Ganti Kode Akses",
          icon: Icons.lock,
          children: [
            _input(oldCode, "Kode Akses Lama"),
            const SizedBox(height: 12),
            _input(newCode, "Kode Akses Baru"),
            const SizedBox(height: 18),
            _button("Simpan Kode Akses", () async {
              if (oldCode.text.isEmpty || newCode.text.length < 6) {
                message("Kode akses baru minimal 6 digit");
                return;
              }

              final res = await api.changeAccessCode(
                userId: userId,
                oldCode: oldCode.text.trim(),
                newCode: newCode.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);
              message(res["message"] ?? "Selesai");
            }),
          ],
        );
      },
    );
  }

  Widget _formSheet({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: secondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label) {
    return TextField(
      controller: c,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        counterText: "",
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: fieldDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback onTap, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(text),
      ),
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
        backgroundColor: cardDark,
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Yakin ingin keluar dari akun ini?",
          style: TextStyle(color: Colors.white70),
        ),
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
    Color? color,
  }) {
    final c = color ?? secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: c.withOpacity(0.16),
              child: Icon(icon, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.white38),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 390,
            pinned: true,
            backgroundColor: bgDark,
            title: const Text("Profil", style: TextStyle(color: Colors.white)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      const Color(0xff14162E),
                      secondary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 35, 18, 18),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 62,
                              backgroundColor: Colors.white.withOpacity(0.16),
                              backgroundImage: profileBytes != null
                                  ? MemoryImage(profileBytes!)
                                  : null,
                              child: profileBytes == null
                                  ? const Icon(Icons.person,
                                      size: 70, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 4,
                              child: GestureDetector(
                                onTap: pickImage,
                                child: CircleAvatar(
                                  radius: 21,
                                  backgroundColor: secondary,
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.black, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(username,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 5),
                        const Text("SmartPay AI User",
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            infoCard(
                                icon: Icons.email, title: "Email", value: email),
                            const SizedBox(width: 12),
                            infoCard(
                                icon: Icons.phone_android,
                                title: "Nomor HP",
                                value: phone),
                          ],
                        ),
                      ],
                    ),
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
                  sectionTitle("Keamanan Akun"),
                  const SizedBox(height: 14),
                  menuCard(
                    icon: Icons.fingerprint,
                    title:
                        biometricEnabled ? "Sidik Jari Aktif" : "Aktifkan Sidik Jari",
                    subtitle: biometricEnabled
                        ? "Login cepat menggunakan fingerprint"
                        : "Tambahkan keamanan biometrik",
                    onTap: showBiometricSheet,
                  ),
                  menuCard(
                    icon: Icons.pin,
                    title: "Ganti PIN",
                    subtitle: "Ubah PIN transaksi 6 digit",
                    onTap: showChangePinSheet,
                  ),
                  menuCard(
                    icon: Icons.lock,
                    title: "Ganti Kode Akses",
                    subtitle: "Perbarui kode akses login akun",
                    onTap: showChangeAccessCodeSheet,
                  ),
                  const SizedBox(height: 10),
                  sectionTitle("Akun"),
                  const SizedBox(height: 14),
                  menuCard(
                    icon: Icons.logout,
                    title: "Logout",
                    subtitle: "Keluar dan masuk menggunakan akun lain",
                    color: Colors.redAccent,
                    onTap: confirmLogout,
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}