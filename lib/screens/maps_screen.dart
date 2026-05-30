import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController mapController = MapController();

  LatLng currentLocation = const LatLng(-7.797068, 110.370529);

  bool loading = false;
  String address = "Tap peta atau tekan Lokasi Saya";

  final Color bgDark = const Color(0xff0F1020);
  final Color cardDark = const Color(0xff1A1B2E);
  final Color primary = const Color(0xff7C5CFF);
  final Color secondary = const Color(0xff00D1FF);

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      setState(() {
        loading = true;
        address = "Mengambil lokasi...";
      });

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          loading = false;
          address = "GPS belum aktif";
        });
        showMessage("Aktifkan GPS terlebih dahulu");
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          loading = false;
          address = "Izin lokasi ditolak";
        });
        showMessage("Izin lokasi ditolak");
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          loading = false;
          address = "Izin lokasi ditolak permanen";
        });
        showMessage("Aktifkan izin lokasi dari pengaturan aplikasi");
        await Geolocator.openAppSettings();
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();

      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() => loading = false);

      mapController.move(currentLocation, 16);

      await getAddressFromLatLng();
    } catch (e) {
      setState(() {
        loading = false;
        address = "Gagal mengambil lokasi";
      });
      showMessage("Gagal mengambil lokasi. Coba tekan Lokasi Saya lagi.");
    }
  }

  Future<void> getAddressFromLatLng() async {
    try {
      setState(() => address = "Mencari alamat...");

      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse"
        "?format=jsonv2"
        "&lat=${currentLocation.latitude}"
        "&lon=${currentLocation.longitude}",
      );

      final res = await http.get(
        url,
        headers: {
          "User-Agent": "smartpay-ai-flutter",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          address = data["display_name"] ?? "Alamat tidak ditemukan";
        });
      } else {
        setState(() {
          address = "Alamat tidak ditemukan";
        });
      }
    } catch (e) {
      setState(() {
        address = "Gagal mendapatkan alamat";
      });
    }
  }

  Future<void> selectLocation(LatLng point) async {
    setState(() {
      currentLocation = point;
      address = "Mencari alamat...";
    });

    mapController.move(point, mapController.camera.zoom);

    await getAddressFromLatLng();
  }

  Future<void> openGoogleMaps() async {
    final lat = currentLocation.latitude;
    final lng = currentLocation.longitude;

    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      showMessage("Tidak bisa membuka Google Maps");
    }
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: cardDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Expanded(
      child: SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text("Maps"),
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: getCurrentLocation,
            icon: Icon(
              Icons.my_location,
              color: secondary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                selectLocation(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.smartpay_ai",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation,
                    width: 80,
                    height: 80,
                    child: Icon(
                      Icons.location_on,
                      size: 58,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardDark.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primary.withOpacity(0.20),
                    child: Icon(
                      Icons.touch_app,
                      color: secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Tap peta untuk memilih lokasi",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primary.withOpacity(0.20),
                        child: Icon(
                          Icons.place,
                          color: secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Lokasi Dipilih",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (loading)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: secondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    address,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${currentLocation.latitude.toStringAsFixed(6)}, "
                    "${currentLocation.longitude.toStringAsFixed(6)}",
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      actionButton(
                        icon: Icons.my_location,
                        label: "Lokasi Saya",
                        onTap: getCurrentLocation,
                      ),
                      const SizedBox(width: 10),
                      actionButton(
                        icon: Icons.map,
                        label: "Google Maps",
                        color: Colors.green,
                        onTap: openGoogleMaps,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}