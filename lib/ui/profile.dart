import 'package:flutter/material.dart';
import 'dart:convert'; // untuk mengubah teks dari API jadi daftar (List)
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nextask/ui/editprofile.dart';
import 'package:nextask/ui/login.dart'; // Alat untuk menyimpan token secara aman

class ProfilePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const ProfilePage({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final storage =
      const FlutterSecureStorage(); // Tempat penyimpanan token yang aman
  String _nama = "Memuat...";
  String _email = "Memuat...";
  bool _isLoading = true;
  String _telepon = "Memuat...";
  String _alamat = "Memuat...";

  @override
  void initState() {
    super.initState();
    FetchUserProfile();
  }

  Future<void> LogOut() async {
    await storage.delete(key: "access_token");
    await storage.delete(key: "refresh_token");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => Login(
          onThemeChanged: widget.onThemeChanged,
          isDarkMode: widget.isDarkMode,
        ),
      ),
      (Route) => false,
    );
  }

  Future<void> FetchUserProfile() async {
    final storage = FlutterSecureStorage();

    try {
      String? token = await storage.read(key: "access_token");

      final response = await http.get(
        Uri.parse("https://alwi-zahrawi-nextask-backend.hf.space/profile/user"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        setState(() {
          // Ambil data asli dari database Backend
          _nama = resData["data"]["nama"] ?? "Tanpa nama";
          _email = resData["data"]["email"] ?? "Tanpa nama";
          _telepon = resData["data"]["no_telp"] ?? "Belum diatur";
          _alamat = resData["data"]["alamat"] ?? "Belum diatur";

          _isLoading = false; // hilangkan loading jika datanya muncul
        });
      } else {
        setState(() {
          _nama = "Gagal memuat profile";
          _email = "Status code ${response.statusCode}";
          _telepon = "Error";
          _alamat = "Error";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _nama = "Error koneksi";
        _email = "Gagal terhubung ke server";
        _isLoading = false;
      });
    }
  }

  Future<void> dialogLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Apakah anda yakin ingin keluar dari aplikasi ini?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Tidak"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog dulu
              LogOut();
            },
            child: const Text("Ya"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          TextButton(
            onPressed: () async {
              final apakahBerhasil = await showModalBottomSheet<bool?>(
                context: context,
                isScrollControlled:
                    true, // Wajib true agar bottom sheet bisa bergerak naik di atas keyboard
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ), // Lengkungan sudut atas
                ),
                builder: (context) =>
                    EditProfile(telepon: _telepon, alamat: _alamat),
              );

              // Jika dari halaman EditProfile membawa balikan 'true', trigger refresh!
              if (apakahBerhasil == true) {
                FetchUserProfile();
              }
            },
            child: Text("Edit Profile", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _nama,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(_email, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.blue),
                    title: Text(_telepon),
                  ),

                  Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                  ),

                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(_alamat),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          dialogLogout();
                        },
                        child: const Text("Logout"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
