import 'package:flutter/material.dart';
import 'package:nextask/ui/login.dart';
//1.  jika ingin pakai API gunakan import ini
import 'dart:convert';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const Register({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Variabel untuk menyimpan pesan error
  String? _usernameError;
  String? _passwordError;
  String? _emailError;
  bool _isObscure = true;

  // 2. Tambahkan variabel ini di dalam _RegisterState:
  bool _isLoading = false;

  //  Future<void> _handleRegister() async konsepnya sama seperti suspendfun _handleRegister di kotlin
  Future<void> _handleRegister() async {
    // Reset error dan validasi lokal
    setState(() {
      // pengecekan -> contoh "eh, inputannya kosong gak?" ?-> kalau iya (True), ambil error kalau : -> kalau tidak atau sebaliknya ambil null atau isinya kalau ada
      _usernameError = _usernameController.text.isEmpty
          ? "Username tidak boleh kosong"
          : null;
      _passwordError = _passwordController.text.isEmpty
          ? "Password tidak boleh kosong"
          : null;
      _emailError = _emailController.text.isEmpty
          ? "Email tidak boleh kosong"
          : null;
    });

    // Jika semua field sudah diisi
    if (_usernameError == null &&
        _passwordError == null &&
        _emailError == null) {
      setState(() => _isLoading = true); // Tampilkan Loading

      try {
        // Kirim data ke API (POST)
        final response = await http.post(
          Uri.parse("https://alwi-zahrawi-nextask-backend.hf.space/register"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "username": _usernameController.text,
            "email": _emailController.text,
            "password": _passwordController.text,
          }),
        );

        // Debug: tampilkan status code dan body untuk membantu diagnosa
        debugPrint('Register response status: ${response.statusCode}');
        debugPrint('Register response body: ${response.body}');

        // Coba parse JSON, tapi fallback ke pesan mentah bila gagal
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = null;
        }

        if (response.statusCode == 200) {
          final message = (data is Map && data.containsKey('message'))
              ? data['message']
              : 'Pendaftaran berhasil';

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));

          // Pindah ke Login setelah sejenak agar user sempat melihat snackbar
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Login(
                onThemeChanged: widget.onThemeChanged,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );
        } else {
          // Jika gagal, coba ambil pesan dari response JSON atau gunakan body mentah
          String detail = 'Gagal mendaftar';
          if (data is Map && data.containsKey('detail')) {
            detail = data['detail'];
          } else if (response.body.isNotEmpty) {
            detail = response.body;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(detail), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        // Tampilkan error jika koneksi gagal / server mati
        debugPrint('Register exception: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false); // Matikan Loading
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
              _registerBuilder(),
              const SizedBox(height: 40),

              //INPUT Username dengan controller & ErrorText
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Masukkan nama anda",
                  labelText: "Username",
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  errorText: _usernameError,
                ),
              ),
              const SizedBox(height: 20),

              // Input Password dengan controller, Toggle Mata & errorText
              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  hintText: "Masukkan password anda",
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                  errorText: _passwordError,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Masukkan Email anda",
                  labelText: "Email",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  errorText: _emailError,
                ),
              ),

              const SizedBox(height: 20),
              // Tombol register
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Register"),
                ),
              ),

              const SizedBox(height: 50),
              Padding(
                padding: EdgeInsetsGeometry.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Sudah punya akun?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Login(
                              onThemeChanged: widget.onThemeChanged,
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.purple),
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

  Widget _registerBuilder() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Text(
          "Welcome",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
        ),
        Text(
          "Register your account first",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
