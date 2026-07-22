import 'package:flutter/material.dart';
import 'dart:convert'; // untuk mengubah teks dari API jadi daftar (List)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nextask/notification_helper.dart';
import 'package:nextask/ui/Home.dart';
import 'package:nextask/ui/detailtugas.dart'; // Alat untuk "menelpon" server API
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:nextask/ui/profile.dart'; // Alat untuk menyimpan token secara aman
import 'package:intl/intl.dart'; // Untuk memformat tanggal ke bahasa Indonesia
import 'package:nextask/main.dart';

class Detailtugas extends StatefulWidget {
  // Ini ibaratnya 'receiver' Bundle-nya
  final Map tugas; // Data awal yang dikirim dari halaman home

  // Constructor: Cara kita menerima data dari halaman sebelumnya
  Detailtugas({super.key, required this.tugas});

  @override
  State<Detailtugas> createState() => _DetailState();
}

class _DetailState extends State<Detailtugas> {
  Map? _detailTugas; // Kita pakai Map karena datanya cuman satu bukan List
  bool _isLoading = true;

  String formatTanggalIndonesia(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "Tidak ada tenggat waktu";

    try {
      // ✅ 1. Langsung parse string aslinya (Flutter suka yang ada huruf T-nya)
      // ✅ 2. Tambahkan .toLocal() agar jamnya otomatis dikonversi ke zona waktu HP (WIB)
      DateTime dateTime = DateTime.parse(rawDate).toLocal();

      // 3. Format menggunakan intl dengan pola: d MMMM yyyy, HH.mm
      // Kita set lokalisasinya ke 'id' agar nama bulannya otomatis Bahasa Indonesia (Maret, Mei, dst.)
      return DateFormat('d MMMM yyyy, HH.mm', 'id').format(dateTime);
    } catch (e) {
      // Jika format dari server agak aneh, kembalikan eks aslinya saja biar tidak error
      return rawDate;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTask();
  }

  Future<void> _fetchTask() async {
    setState(() {
      _isLoading = true;
    });

    final storage = const FlutterSecureStorage();

    try {
      String? token = await storage.read(key: "access_token");

      final int idTugas = widget.tugas["id"];

      final response = await http.get(
        Uri.parse(
          'https://alwi-zahrawi-nextask-backend.hf.space/detail/tugas/$idTugas',
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decodeData = json.decode(response.body);
        setState(() {
          // AMbil dari data["data"]["user"] sesuaikan dengan struktur JSON FastAPI
          _detailTugas = decodeData["data"]["user"];
          _isLoading = false; // -> agar pas datanya muncul loadingnya hilang
        });

        // 1. Proses penjadwalan alarm dimulai disini
        try {
          String? rawDateLine = _detailTugas?["dateline"];

          if (rawDateLine != null && rawDateLine.isNotEmpty) {
            // 2. Bersihkan huruf 'T' (sama seperti titik tanggal  Indonesia)
            DateTime waktuDateLine = DateTime.parse(rawDateLine).toLocal();

            // 3. Validasi: pastikan alarm hanya dipasang jika waktunya belum lewat
            if (waktuDateLine.isAfter(DateTime.now())) {
              await NotificationHelper.scheduleNotification(
                id: idTugas,
                title: "Tenggat Tugas!",
                body: "Tugas ${_detailTugas?["judul"]} mendekati deadline",
                scheduledDate: waktuDateLine,
              );

              print(
                "Nextask: Alarm berhasil dijadwalkan pada waktu $waktuDateLine",
              );
            } else {
              print(
                "Nextask: Alarm tidak dijadwalkan karena tenggat waktu sudah terlewat",
              );
            }
          }
        } catch (alarmError) {
          print("NexTask: Gagal menjadwalkan alarm karena $alarmError");
        }
        // Selesai
      } else {
        throw Exception("Gagal mengambil detail dari server");
      }
    } catch (e) {
      print("Koneksi error");
    }
  }

  void _showDialogEdit() {
    // Inisialiasasi controller engan judul tugas yang sekarang
    final TextEditingController editingController = TextEditingController(
      text: _detailTugas?["judul"] ?? widget.tugas["nama"] ?? "",
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Tugas"),
          content: TextField(
            controller: editingController,
            decoration: const InputDecoration(
              hintText: "Masukkan judul baru",
              labelText: "Judul Tugas",
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),

            ElevatedButton(
              onPressed: () {
                if (editingController.text.isNotEmpty) {
                  // panggil fungsi edit (kita perlu update fungsi edit judulnya)
                  editJudul(editingController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateTask(bool status) async {
    final storage = const FlutterSecureStorage();

    try {
      String? token = await storage.read(key: "access_token");

      final int idTugas = widget.tugas["id"];

      final response = await http.put(
        Uri.parse(
          "https://alwi-zahrawi-nextask-backend.hf.space/update/tugas/$idTugas",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"is_Done": status}),
      );

      if (response.statusCode == 200) {
        // JIKA response berhasil
        showDialog(
          // tampilkan dialog dengan animasi lottie didalamnya
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    "assets/lottie/ic_check.json",
                    width: 120,
                    height: 120,
                    repeat: false,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    status
                        ? "Tugas diselesaikan"
                        : "Status tugas dikembalikan semula",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        Navigator.pop(context); // tutup dialog
        Navigator.pop(context, true); // kembali + refresh
      } else {
        throw Exception("Gagal update tugas");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> deleteTask() async {
    final storage = const FlutterSecureStorage();

    try {
      String? token = await storage.read(key: "access_token");

      final int idTugas = widget.tugas["id"];

      final response = await http.delete(
        Uri.parse(
          "https://alwi-zahrawi-nextask-backend.hf.space/delete/tugas/$idTugas",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Tugas berhasil dihapus")));

        Navigator.pop(context, true);
      } else {
        throw Exception("Gagal menghapus tugas");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> editJudul(String judulBaru) async {
    final storage = const FlutterSecureStorage();

    try {
      String? token = await storage.read(key: "access_token");

      final int idTugas = widget.tugas["id"];

      final response = await http.put(
        Uri.parse(
          "https://alwi-zahrawi-nextask-backend.hf.space/edit/tugas/$idTugas",
        ),
        headers: {
          "Content-Type": "application/json", // jangan lupa header ini
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"judul": judulBaru}), // Kirim judul baru ke server
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Judul tugas berhasil di edit")));

        Navigator.pop(context, true);
      } else {
        throw Exception("Gagal mengedit tugas");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget build(BuildContext context) {
    bool isDone = _detailTugas?["done"] ?? widget.tugas["done"] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Tugas"),
        actions: [
          TextButton(
            onPressed: () {
              _showDialogEdit();
            },
            child: Text("Edit", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Tampilkan loading
          : Padding(
              padding: const EdgeInsetsGeometry.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Judul: ${_detailTugas?["judul"] ?? widget.tugas["nama"] ?? "Tanpa nama"}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text("Pemilik: ${_detailTugas?["nama"] ?? "-"}"),
                  Text("Email: ${_detailTugas?["email"] ?? "-"}"),
                  const Divider(),

                  // 1. Tampilkan DateLine (Tenggat Waktu)
                  Row(
                    children: [
                      const Icon(
                        Icons.alarm,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Tenggat: ${formatTanggalIndonesia(_detailTugas?["dateline"] ?? widget.tugas["dateline"])}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Tampilkan detail / deskripsi tugas
                  const Text(
                    "Detail Tugas:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _detailTugas?["detail"] != null &&
                              _detailTugas!["detail"].toString().isNotEmpty
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _detailTugas?["detail"] ?? "Tidak ada deskripsi detail.",
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  const Divider(),

                  Text(
                    "Status: ${isDone ? "✅ Selesai" : "⏳ Belum selesai"}",
                    style: TextStyle(
                      color: (isDone ? Colors.green : Colors.orange),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width:
                              MediaQuery.of(context).size.width *
                              0.6, // Mengatur lebar tombol agar proposional
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // Warnanya dinamis kalo mau reverse orange kalo selesai green
                              backgroundColor: isDone
                                  ? Colors.orange
                                  : Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              updateTask(!isDone);
                            },
                            child: Text(
                              isDone ? "Belum selesai" : "Sudah selesai",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
