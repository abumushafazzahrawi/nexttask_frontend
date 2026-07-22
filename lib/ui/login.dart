import 'package:flutter/material.dart';
import 'package:nextask/ui/Home.dart';
import 'package:nextask/ui/register.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Alat untuk menyimpan token secara aman

class Login extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;


  const Login({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // 1. Definisikan controller (Seperti variable untuk menampung inptan)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final storage =
      const FlutterSecureStorage(); // Tempat penyimpanan token yang aman
  // Variable untuk menyimpan pesan error
  String? _emailError;
  String? _passError;
  bool _isObscure = true;
  bool _isLoading = false;
  bool _isSuccess = false;

  // Bagian Logika Validasi
  Future<void> _handleLogin() async {
    setState(() {
      // Reset Error dan validasi lokal
      _emailError = _emailController.text.isEmpty
          ? "Email tidak boleh kosong"
          : null;
      _passError = _passwordController.text.isEmpty
          ? "Password tidak boleh kosong"
          : null;
    });

    // Jika email & password terisi, baru tampilkan dialog konfirmasi
    if (_emailError == null && _passError == null) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse(
            "https://alwi-zahrawi-nextask-backend.hf.space/login",
          ), // Ganti jadi /login
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": _emailController.text,
            "password": _passwordController.text,
          }),
        );

        final data = jsonDecode(response.body);

        print("Status Code dari server: ${response.statusCode}");
        print("Isi jawaban server: $data");

        if (response.statusCode == 200 && data != null) {
          final Map<String, dynamic>? responseData = data["data"];

          if (responseData != null && responseData.containsKey("tokens")) {
            final String token =
                responseData["tokens"]["access_token"]; // Ambil token pastikan key nya sesuai dengan API

            // Simpan ke storage aman (Flutter Secure Storage)
            await storage.write(key: "access_token", value: token);

            // Login berhasil: update state lalu navigasi
            setState(() {
              _isLoading = false;
              _isSuccess = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Login Berhasil! Selamat Datang")),
            );

            await Future.delayed(const Duration(milliseconds: 800));

            if (!mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            // Pindah ke halaman utama (Home)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Home(
                  onThemeChanged:
                      widget.onThemeChanged, // ambil dari widget login
                  isDarkMode: widget.isDarkMode,

                ),
              ),
            );
          } else {
            // Response 200 tapi tidak ada token -> anggap gagal
            String pesanError = data["detail"] ?? "Login Gagal";
            setState(() {
              _emailError = null;
              _passError = null;
              _isLoading = false;
            });
            if (pesanError.contains("Email")) {
              setState(() => _emailError = pesanError);
            } else if (pesanError.contains("Password")) {
              setState(() => _passError = pesanError);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(pesanError),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Gagal (Ambil pesan dari kunci "detail" yang ada di API)
          String pesanError = data["detail"] ?? "Login Gagal";

          setState(() {
            if (pesanError.contains("Email")) {
              _emailError = pesanError; // Teks error muncul
            } else if (pesanError.contains("Password")) {
              _passError = pesanError; // Teks error muncul
            }
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                pesanError,
              ), // Akan muncul password salah atau email tidak ditemukan
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error $e"), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted && !_isSuccess) {
          // mounted -> widget masih hidup (true)
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _builder(),
              const SizedBox(height: 40),

              // Input email dengan CONTROLLER & ErrorText
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Masukkan email anda",
                  labelText: "Email",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email), // Icon disebelah kiri
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 20),

              // Input Password dengan CONTROLLER, Toggle Mata, & ErrorText
              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  hintText: "Masukkan password anda",
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock), // Icon disebelah kiri
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure; // Toggle status
                      });
                    },
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                  errorText: _passError,
                ),
              ),

              const SizedBox(height: 20),

              // Tombol Login
              Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: (_isLoading || _isSuccess)
                      ? 60
                      : MediaQuery.of(context).size.width,
                  height: 60,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: (_isSuccess)
                          ? Colors.white
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          (_isLoading || _isSuccess) ? 30 : 10,
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (!_isLoading && !_isSuccess) {
                        _handleLogin();
                      }
                    },
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : _isSuccess
                        ? const Icon(Icons.check, color: Colors.green, size: 30)
                        : const Text("Login", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),

              const SizedBox(height: 50), // menambahkan marginTop 50
              Padding(
                padding: const EdgeInsetsGeometry.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum punya akun?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Register(
                              onThemeChanged: widget.onThemeChanged,
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _builder() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Text(
          "Welcome Back!",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          "Login to your account",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
