import 'dart:convert'; // untuk mengubah teks dari API jadi daftar (List)
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nextask/main.dart';
import 'package:nextask/ui/Arsip.dart';
import 'package:nextask/ui/detailtugas.dart'; // Alat untuk "menelpon" server API
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nextask/ui/profile.dart'; // Alat untuk menyimpan token secara aman
import 'package:nextask/ui/settings.dart';
import 'package:nextask/ui/statistik.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:nextask/ui/theme_shared_prefs.dart';
import 'package:nextask/ui/search.dart';
import 'package:nextask/notification_helper.dart';

final storage =
    const FlutterSecureStorage(); // Tempat penyimpanan token yang aman

class Home extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const Home({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // 1. Variabel Navigasi & Judul
  int _currentIndex = 0;
  final List<String> _titles = ["Home", "Statistik", "Settings"];

  // 2. Pusat data tugas
  List<dynamic> _daftarTugas =
      []; // Keranjang kosong untuk menyimpan tugas dari API di halaman home

  List<dynamic> _arsipTugas =
      []; // keranjang koaong untuk menyimpan tugas "done" di arsip

  late bool _isDarkMode;
  bool _isLoading =
      true; // Catatan apakah kita masih "loading" atau sudah selesai

  String _userName = "Loading...";
  String _userEmail = "Loadinh...";

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _fetchTasks();
    checkReminder();
    _fetchProfile();
  }

  // Fungsi Mengambil data
  Future<void> _fetchTasks() async {
    // 1. Kasih tahu aplikasi kalau sedang loading
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Menelepon server API
      // Gunakan 10.0.2.2 jika menggunakan emulator Android untuk mengakses localhost laptop
      String? token = await storage.read(key: "access_token");
      final response = await http.get(
        Uri.parse('https://alwi-zahrawi-nextask-backend.hf.space/tugas'),
        headers: {"Authorization": "Bearer $token"},
      ); // await -> nunggu response

      if (!mounted) return;

      // Jika response yang didapatkan 200 (berhasil)
      if (response.statusCode == 200) {
        // Isi keranjang kosong tadi dengan data dari server
        final data = json.decode(response.body);
        setState(() {
          // ambil data dari struktur json
          _daftarTugas = data["data"]
              .where((item) => item["done"] == false)
              .toList();
          _arsipTugas = data["data"]
              .where((item) => item["done"] == true)
              .toList();
          _isLoading = false; // Loading selesai
        });
      } else {
        throw Exception('Gagal mengambil data'); // Lempar error
      }
    } catch (e) {
      // 4. Jika ada erorr (misal server mati), tampilkan pesan
      setState(() {
        _isLoading = false; // Loading hilang
      });
      ScaffoldMessenger.of(context).showSnackBar(
        // Tampilokan pesan SnackBar
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> addTask(
    String judulTugas,
    String detailTugas,
    String dateline,
  ) async {
    // ambil token (jangan lupa titik koma)
    String? token = await storage.read(key: "access_token");

    try {
      var response = await http.post(
        Uri.parse("https://alwi-zahrawi-nextask-backend.hf.space/add/tugas"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },

        // sesuaikan dengan field yang ada di API (pakai "judul")
        body: jsonEncode({
          "judul": judulTugas,
          "detail": detailTugas,
          "dateline": dateline,
        }),
      );

      if (response.statusCode == 200) {
        // Ambil waktu deadline
        if (dateline.isNotEmpty) {
          DateTime waktuDeadLine = DateTime.parse(dateline);

          // Pastikan waktunya belum lewat
          if (waktuDeadLine.isAfter(DateTime.now())) {
            // Pakai timestamp biar id alarm menarik
            int alarmId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

            await NotificationHelper.scheduleNotification(
              id: alarmId,
              title: "Tenggat tugas",
              body: judulTugas,
              scheduledDate: waktuDeadLine,
            );

            print("NexTask: Reminder berhasil di jadwalkan");
          }
        }

        _fetchTasks(); // Refresh daftar tugas setelah berhasil menambahkan
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Tugas berhasil ditambahkan!")));
      } else if (response.statusCode == 401) {
        // Token tidak valid atau sudah kadaluarsa
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sesi Anda telah habis. Silakan login kembali."),
          ),
        );
        // Pindah ke halaman login
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Gagal menambahkan tugas');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Daftar Tugas Gagal Ditambahkan: $e")),
      );
    }
  }

  Future<void> deleteTask(int idTugas) async {
    try {
      String? token = await storage.read(key: "access_token");

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
        _fetchTasks(); // refresh list
      } else {
        throw Exception("Gagal menghapus tugas");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> checkReminder() async {
    String? token = await storage.read(key: "access_token");

    final response = await http.get(
      Uri.parse("https://alwi-zahrawi-nextask-backend.hf.space/reminder/check"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["total"] > 0) {
        for (var item in data["data"]) {
          await NotificationHelper.showNotification(
            id: item["id"],
            title: "Reminder tugas",
            body: item["judul"],
          );
        }
      }
    }
  }

  Future<void> _fetchProfile() async {
    try {
      String? token = await storage.read(key: "access_token");
      final response = await http.get(
        Uri.parse(
          "https://alwi-zahrawi-nextask-backend.hf.space/profile/users",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userName = data["data"]["nama"] ?? "User";
          _userEmail = data["data"]["email"] ?? "user@gmail.com";
        });
      } else {
        // Fallback jika gagal
        _userName = "Ralph";
        _userEmail = "ralph@gmail.com";
      }
    } catch (e) {
      _userName = "Ralph";
      _userEmail = "ralph@gmail.com";
    }
  }

  // Fungsi untuk memilihg body mana yang mau ditampilkan
  Widget _buildBody() {
    if (_currentIndex == 0) {
      return _buildHomeBody();
    } else if (_currentIndex == 1) {
      return Statistik();
    } else {
      // panggil nama class settings.dart disini
      return Settings(
        onThemeChanged: (value) {
          setState(() {
            // Jalankan fungsi update tema saat switch di tekan
            _isDarkMode = value;
          });

          widget.onThemeChanged(value);
        },
        isDarkMode: _isDarkMode, // Kirim status saat ini ke switch
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              right: 20,
              left: 20,
              bottom: 20,
            ),
            color: Colors.blue, // warna background drawer
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Bungkus pakai stack untuk mempertahankan dot ijo status
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(
                        "https://i.pinimg.com/736x/da/3e/2b/da3e2b3b85d1b8fc13fd16e4d98a77a7.jpg",
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ), // Biar ada list rapi
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 16,
                ), //Jarak horizontal antara foto dan teks
                // Gunakan Column agar nama dan email bertumpuk vertikal
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Rata kiri teks
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white, // Warna teks sesuai target
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ), // Jarak tipis antara nama dan email
                      Text(
                        _userEmail,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        overflow: TextOverflow
                            .ellipsis, // Biar kalau email kepanjangan tidak eror layout
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: Icon(Icons.person),
            title: Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    onThemeChanged: widget.onThemeChanged,
                    isDarkMode: _isDarkMode,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.archive),
            title: Text("Arsip"),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (context) => Arsip()),
              );
              if (result == true) {
                _fetchTasks();
              }
            },
          ),
        ],
      ),
    );
  }

  // Kita pindahkan logika tampilan daftar tugas ke fungsi terpisah
  Widget _buildHomeBody() {
    // 1. Jika sedang login
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Jika data kosong (tampilan cantik)
    if (_daftarTugas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),

            const SizedBox(height: 20),
            const Text(
              "Hore! Tidak ada tugas",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              "Nikmati waktu santaimu!",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchTasks,
              child: const Text("Cek lagi"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      // Biar bisa ditarik ke bawah buat refresh
      onRefresh: _fetchTasks,
      child: ListView.builder(
        itemCount: _daftarTugas.length,
        itemBuilder: (context, index) {
          final tugas = _daftarTugas[index];
          return Dismissible(
            key: Key(tugas["id"].toString()),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),

              child: const Icon(Icons.delete, color: Colors.white),
            ),

            direction: DismissDirection.endToStart,

            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Hapus Tugas"),
                  content: Text("Yakin ingin hapus tugas ${tugas["judul"]}?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context, true);
                        await deleteTask(tugas["id"]);
                      },
                      child: Text("Ya"),
                    ),
                  ],
                ),
              );
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: (tugas["done"] ?? false)
                      ? Colors.green
                      : Colors.orange,
                  child: Icon(
                    (tugas["done"] ?? false) ? Icons.check : Icons.assignment,
                    color: Colors.white,
                  ),
                ),
                title: Text(tugas["judul"] ?? "Tidak ada nama"),
                subtitle: Text(
                  (tugas["done"] ?? false) ? "Sudah Selesai" : "Belum Selesai",
                ),
                trailing: Icon(
                  (tugas["done"] ?? false)
                      ? Icons.check_circle
                      : Icons
                            .circle_outlined, // ?? -> jika yang kiri tugas["done"] null maka tampilkan false aja
                  color: (tugas["done"] ?? false) ? Colors.green : Colors.grey,
                ),
                onTap: () async {
                  // Disini kita kirim datanya langsung ke constructor!
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Detailtugas(tugas: tugas),
                    ),
                  );
                  if (result == true) {
                    _fetchTasks();
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 4. Opsional: Warna AppBar bisa mengikuti tema jika mau
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () async {
              await NotificationHelper.showNotification(
                id: 999,
                title: 'Tes Notif',
                body: 'Notifikasi uji coba',
                payload: 'debug',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notif uji coba dikirim')),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTasks),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: Search(_daftarTugas),
              );

              if (result == true) {
                _fetchTasks();
              }
            },
          ),
        ],
      ),

      drawer: _buildDrawer(),

      // Disini kuncinya : Memanggil fungsi secara dinamis
      body: _buildBody(),

      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: _isDarkMode
            ? const Color(0XFF121212)
            : Colors
                  .white, // Warna luar lekukan (samakan dengan background body)
        index: _currentIndex, // gunakan index bukan currentIndex
        color: Colors.blue, // warna dasar bar navigasi itu sendiri
        buttonBackgroundColor:
            Colors.orange, // Warna bulatan ikon yang sedang aktif
        animationDuration: const Duration(
          milliseconds: 300,
        ), // Kecepatan efek lengkungan saat berpindah
        height: 60, // Mengatur tinggi bar navigasi
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.bar_chart, size: 30, color: Colors.white),
          Icon(Icons.settings, size: 30, color: Colors.white),
        ],
      ),

      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: _isDarkMode ? Colors.orange : Colors.blue,
              foregroundColor: Colors.white,
              onPressed: () {
                final TextEditingController tugasController =
                    TextEditingController();
                final TextEditingController detailController =
                    TextEditingController();
                String dialogDateLine = ""; //Menampung hasil tanggal + jam

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Tambah tugas baru"),
                    // Menggunakan SingleChildScrollView agar tidak overload saat keyboard muncul
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: tugasController,
                            decoration: const InputDecoration(
                              hintText: "Masukkan judul tugas",
                              labelText: "Tugas",
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: detailController,
                            decoration: InputDecoration(
                              hintText: "Masukkan detail tugas",
                              labelText: "Detail",
                            ),
                          ),
                          const SizedBox(height: 20),

                          // StatefulBuilder digunakan agar text tanggal berubah saat user memilih kalender
                          StatefulBuilder(
                            builder: (context, setDialogState) {
                              return Column(
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.date_range),
                                    label: const Text(
                                      "Pilih Tenggat Waktu & Jam",
                                    ),
                                    onPressed: () async {
                                      // 1. Munculkan kalender
                                      final DateTime? tanggalDipilih =
                                          await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2030),
                                          );

                                      if (tanggalDipilih == null) return;

                                      // 2. Otomatis munculkan jam
                                      final TimeOfDay? jamDipilih =
                                          await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                          );

                                      if (jamDipilih == null) return;

                                      // Gabungkan tanggal & jam
                                      final DateTime waktuLengkap = DateTime(
                                        tanggalDipilih.year,
                                        tanggalDipilih.month,
                                        tanggalDipilih.day,
                                        jamDipilih.hour,
                                        jamDipilih.minute,
                                      );

                                      // Update teks di dalam dialog
                                      setDialogState(() {
                                        dialogDateLine = waktuLengkap
                                            .toString()
                                            .split('.')
                                            .first;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    dialogDateLine.isEmpty
                                        ? "Belum ada tenggat waktu"
                                        : "Tenggat: $dialogDateLine",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: dialogDateLine.isEmpty
                                          ? Colors.grey
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          if (tugasController.text.isNotEmpty) {
                            // Kirim 3 data seklaigus ke fungsi AddTask baru kita
                            addTask(
                              tugasController.text,
                              detailController.text,
                              dialogDateLine,
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Tambah"),
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
