import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// 1. Deklarasikan variabel status di bagian atas State halaman Settings kamu

class Settings extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const Settings({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _isNotificationOn = true;

  void _showDisableNotificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User wajib memilih salah satu tombol
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text("Peringatan"),
            ],
          ),
          content: Text(
            "Yakin nih matiin notifikasi? nanti gak ada reminder tugas loh",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // tutup dialog
              },
              child: const Text("Batal"),
            ),
            // Tombol Yakin (Benar-benar mematikan)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  _isNotificationOn = false; // Matikan switch
                });
                // Tambahkan logika tambahan di sini jika ingin menyimpan status ke SharedPreferences
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Notifikasi dinonaktifkan.")),
                );
              },
              child: const Text("Yakin", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: Text(widget.isDarkMode ? "Turn On" : "Turn Off"),
            secondary: const Icon(Icons.dark_mode),
            value: widget.isDarkMode,
            onChanged: (value) {
              widget.onThemeChanged(value); // Kirim perubahan ke main.dart
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Notification"),
            subtitle: Text(_isNotificationOn ? "Turn On" : "Turn Off"),
            secondary: Icon(Icons.notifications_sharp),
            value: _isNotificationOn, // Gunakan variable dinamis
            onChanged: (bool value) async {
              if (value == false) {
                // Jika user mencoba mematikan switch, panggil dialog konfirmasi
                _showDisableNotificationDialog();
              } else {
                // Jika user mencoba menyalakan kembali, minta izin dari sistem Android
                var status = await Permission.notification.request();
                if (status.isGranted) {
                  setState(() {
                    _isNotificationOn = true;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Izin notifikasi ditolak oleh sistem"),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
