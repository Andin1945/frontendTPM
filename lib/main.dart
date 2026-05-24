import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/conversion_screen.dart';
import 'screens/profile_screen.dart';

import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SmartPay AI",
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffdfeaff),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff5146b8),
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff5146b8),
        ),
      ),
      home: FutureBuilder<bool>(
        future: auth.isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data == true ? MainPage() : LoginScreen();
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;
  final auth = AuthService();

  final List<Widget> pages = [
    HomeScreen(),
    ConversionScreen(),
    MapsScreen(),
    ProfileScreen(),
    SaranScreen(),
  ];

  Future<void> logout() async {
    await auth.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: const Color(0xff5146b8),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: "Konversi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Maps",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: "Saran",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff5146b8),
        onPressed: logout,
        child: const Icon(Icons.logout, color: Colors.white),
      ),
    );
  }
}

class SaranScreen extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  SaranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffdfeaff),
      appBar: AppBar(title: const Text("Saran & Kesan")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 14),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.feedback,
                size: 52,
                color: Color(0xff5146b8),
              ),
              const SizedBox(height: 12),
              const Text(
                "Saran & Kesan Mata Kuliah TPM",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Tulis saran dan kesan...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff5146b8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    controller.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Terima kasih atas masukannya"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text("Kirim"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}