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

  LatLng currentLocation = LatLng(-6.200000, 106.816666);
  bool loading = true;
  String address = "Mencari alamat...";

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() => loading = false);
        showMessage("GPS belum aktif");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => loading = false);
        showMessage("Izin lokasi ditolak");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLocation = LatLng(pos.latitude, pos.longitude);

      await getAddressFromLatLng();

      setState(() => loading = false);

      mapController.move(currentLocation, 16);
    } catch (e) {
      setState(() => loading = false);
      showMessage("Gagal mengambil lokasi");
    }
  }

  Future<void> getAddressFromLatLng() async {
    try {
      final url =
          "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${currentLocation.latitude}&lon=${currentLocation.longitude}";

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "smartpay_ai",
        },
      );

      final data = jsonDecode(res.body);

      setState(() {
        address = data["display_name"] ?? "Alamat tidak ditemukan";
      });
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
      SnackBar(content: Text(text)),
    );
  }

  Widget actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xff5146b8),
  }) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef4ff),
      appBar: AppBar(
        title: const Text("Pilih Lokasi"),
        backgroundColor: const Color(0xff5146b8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: currentLocation,
                    initialZoom: 16,
                    onTap: (tapPosition, point) async {
                      await selectLocation(point);
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
                          width: 90,
                          height: 90,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  size: 42,
                                  color: Color(0xff5146b8),
                                ),
                              ),
                            ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.touch_app, color: Color(0xff5146b8)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Tap area map untuk memilih lokasi",
                            style: TextStyle(fontWeight: FontWeight.w600),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            CircleAvatar(
                              backgroundColor: Color(0xffe9f2ff),
                              child: Icon(
                                Icons.place,
                                color: Color(0xff5146b8),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Lokasi Dipilih",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)}",
                          style: const TextStyle(
                            color: Colors.grey,
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