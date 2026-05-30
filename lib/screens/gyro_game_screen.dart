import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GyroGameScreen extends StatefulWidget {
  const GyroGameScreen({super.key});

  @override
  State<GyroGameScreen> createState() => _GyroGameScreenState();
}

class _GyroGameScreenState extends State<GyroGameScreen> {
  StreamSubscription? sensorSub;
  Timer? gameTimer;

  final random = Random();

  double carX = 0;
  double enemyX = 0;
  double enemyY = -320;

  int score = 0;
  bool gameOver = false;

  final double carWidth = 52;
  final double carHeight = 82;

  final double enemyWidth = 52;
  final double enemyHeight = 82;

  double enemySpeed = 7;
  double controlSpeed = 12;

  final bgDark = const Color(0xff0F1020);
  final cardDark = const Color(0xff1A1B2E);
  final primary = const Color(0xff7C5CFF);
  final secondary = const Color(0xff00D1FF);

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    sensorSub?.cancel();
    gameTimer?.cancel();

    setState(() {
      gameOver = false;
      score = 0;
      carX = 0;
      enemyY = -320;
      enemyX = random.nextDouble() * 240 - 120;
      enemySpeed = 7;
    });

    sensorSub = accelerometerEventStream().listen((event) {
      if (gameOver) return;

      setState(() {
        carX -= event.x * controlSpeed;
      });
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 25), (_) {
      if (gameOver) return;

      setState(() {
        enemyY += enemySpeed;

        if (enemyY > 620) {
          score++;
          enemySpeed += 0.18;
          enemyY = -220;
          enemyX = random.nextDouble() * 260 - 130;
        }

        checkCollision();
      });
    });
  }

  void checkCollision() {
    const double playerY = 220;

    final playerRect = Rect.fromCenter(
      center: Offset(carX, playerY),
      width: carWidth * 0.72,
      height: carHeight * 0.78,
    );

    final enemyRect = Rect.fromCenter(
      center: Offset(enemyX, enemyY - 220),
      width: enemyWidth * 0.72,
      height: enemyHeight * 0.78,
    );

    if (playerRect.overlaps(enemyRect)) {
      setState(() {
        gameOver = true;
      });

      sensorSub?.cancel();
      gameTimer?.cancel();

      showGameOverDialog();
    }
  }

  void showGameOverDialog() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            backgroundColor: cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "Game Over",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "Skor kamu: $score",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  startGame();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Main Lagi"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget carWidget({
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: carWidth,
      height: carHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 18,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 38,
      ),
    );
  }

  Widget roadLine(double top) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 8,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final widthLimit = MediaQuery.of(context).size.width / 2 - 58;
    carX = carX.clamp(-widthLimit, widthLimit);
    enemyX = enemyX.clamp(-widthLimit, widthLimit);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text("Gyro Car Game"),
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: startGame,
            icon: Icon(Icons.refresh, color: secondary),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 16,
            left: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primary,
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Score: $score",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    "Speed ${enemySpeed.toStringAsFixed(1)}",
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),

          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              margin: const EdgeInsets.fromLTRB(22, 105, 22, 28),
              decoration: BoxDecoration(
                color: const Color(0xff171827),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 25,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xff10111F),
                              Color(0xff22243B),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 22,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 4, color: Colors.white12),
                    ),

                    Positioned(
                      right: 22,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 4, color: Colors.white12),
                    ),

                    roadLine(20),
                    roadLine(130),
                    roadLine(240),
                    roadLine(350),
                    roadLine(460),

                    Center(
                      child: Transform.translate(
                        offset: Offset(enemyX, enemyY - 220),
                        child: carWidget(
                          color: Colors.redAccent,
                          icon: Icons.local_taxi,
                        ),
                      ),
                    ),

                    Center(
                      child: Transform.translate(
                        offset: Offset(carX, 220),
                        child: carWidget(
                          color: secondary,
                          icon: Icons.directions_car_filled,
                        ),
                      ),
                    ),

                    if (gameOver)
                      Container(
                        color: Colors.black.withOpacity(0.55),
                        child: const Center(
                          child: Text(
                            "GAME OVER",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 36,
            left: 28,
            right: 28,
            child: Text(
              "Miringkan HP kiri/kanan untuk menghindari mobil merah.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    sensorSub?.cancel();
    gameTimer?.cancel();
    super.dispose();
  }
}