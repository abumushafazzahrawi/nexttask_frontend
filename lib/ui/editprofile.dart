import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class EditProfile extends StatefulWidget {
  final String telepon;
  final String alamat;

  const EditProfile({super.key, required this.telepon, required this.alamat});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _telpController = TextEditingController();
  final _alamatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Jika data dari profile "Belum diatur", kosongkan hint text - nya biar bersih
    _telpController.text = widget.telepon == "Belum diatur"
        ? ""
        : widget.telepon;
    _alamatController.text = widget.alamat == "Belum diatur"
        ? ""
        : widget.alamat;
  }

  Future<void> _simpanPerubahan() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: "access_token");

    // Kirim data ke FastAPI lewat Query Parameter atau Body sesuai rancangan Backend
    final url = Uri.parse(
      "https://alwi-zahrawi-nextask-backend.hf.space/profile/update?no_telp=${_telpController.text}&alamat=${_alamatController.text}",
    );

    final response = await http.put(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      // Jika sukses, kembali ke halaman profil sambil membawa status true
      if (!mounted) return;
      // Berhasil simpan tutup bottomsheet sambil melempar ilai "true" untuk refresh
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX utama: Menggunakan Padding dinamis agar komponen naik saat keyboard hape muncul
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(
          context,
        ).viewInsets.bottom, // Mengikuti tinggi keyboard
        left: 20,
        right: 20,
        top: 15,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Tinggi menyesuaikan isi, tidak full semonitor
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Garis kecil estetik di bagian atas Bottom Sheet
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Edit Profil Anda",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _telpController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Nomor Telepon",
                hintText: "Masukkan nomor telepon anda",
                border: OutlineInputBorder(), // BIkin kotakan biar rapi
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _alamatController,
              maxLines: 2, // Biar leluasa ngetik dalama panjang
              decoration: const InputDecoration(
                labelText: "Alamat",
                hintText: "Masukkan alamat anda",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _simpanPerubahan,
                child: const Text("Simpan Perubahan"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
