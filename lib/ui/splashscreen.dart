import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nextask/ui/Home.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'login.dart';

class Splashscreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;
  final bool isMenuDrawer;

  const Splashscreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
    required this.isMenuDrawer,
  });

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  final storage =
      const FlutterSecureStorage(); // 1. Definisikan storage di sini
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _startappDelay(); // Jalankan fungsi delay
    _isDarkMode = widget.isDarkMode;
  }

  Future<void> checkLoginStatus() async {
    String? token = await storage.read(key: "access_token");

    if (!mounted) return; // keamanan tambahan agar tidak error saat navigasi

    if (token != null) {
      // Ada token, langsung ke Home
      try {
        // 1. Tes tembak ke salah satu endpoint backend yang butuh token (contoh: /users)
        final response = await http.get(
          Uri.parse("https://alwi-zahrawi-nextask-backend.hf.space/users"),
          headers: {
            "Authorization": "Bearer $token",
          }, // Kirim tokennya di header
        );

        if (!mounted) return;

        // 2. Jika server merespons 200 OK, artinya token masih aktif dan valid!
        if (response.statusCode == 200) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Home(
                onThemeChanged: widget.onThemeChanged,
                isDarkMode: _isDarkMode,
              ),
            ),
          );
          // 3. Jika server merespons 401 (Unauthorized), artinya token sudah expired!
        } else if (response.statusCode == 401) {
          await storage.delete(
            key: "access_token",
          ); // Hapus token expired dari memori hape

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Login(
                onThemeChanged: widget.onThemeChanged,
                isDarkMode: _isDarkMode,
              ),
            ),
          );
          // Opsi tambahan jika ada kendala server lain , amankan ke halaman login
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Login(
                onThemeChanged: widget.onThemeChanged,
                isDarkMode: _isDarkMode,
              ),
            ),
          );
        }
        // Jika terjadi error koneksi (misal internet mati)
      } catch (e) {
        if (!mounted) ;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Login(
              onThemeChanged: widget.onThemeChanged,
              isDarkMode: _isDarkMode,
            ),
          ),
        );
      }
    } else {
      // Jika dari awal token memang kosong (null), langsung ke Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Login(
            onThemeChanged: widget.onThemeChanged,
            isDarkMode: _isDarkMode,
          ),
        ),
      );
    }
  }

  Future<void> _startappDelay() async {
    await Future.delayed(
      const Duration(seconds: 3),
    ); // Tunggu 3 detik biar logo kelihatan
    checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 1. Siapkan kotak
        width: double.infinity, // panjangnya matchParent
        height: double.infinity, // lebarnya match parent
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkMode
                ? [Colors.grey[500]!, Colors.black]
                : [Colors.blue, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/Logo_NextTask.png",
                width: 300,
                height: 300,
                errorBuilder: (context, error, stackTrace) {
                  // jika gambar gagal dimuat (misal file tidak ada), tampilkan icon pengganti
                  return const Icon(
                    Icons.flutter_dash,
                    size: 100,
                    color: Colors.blue,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
