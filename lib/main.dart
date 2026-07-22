import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nextask/notification_helper.dart';
import 'package:nextask/ui/splashscreen.dart';
import 'package:nextask/ui/theme_shared_prefs.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart'; // Tambahkan import ini di main.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:nextask/services/reminder_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // ➕ Tambahkan ini jika belum ada
import 'package:http/http.dart' as http; // ➕ Tambahkan ini untuk hit API
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const storage = FlutterSecureStorage();

// Handler Top-Level untuk mendengarkan notifikasi saat aplikasi MATI / di Background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
    "NexTask background: Mendapat pesan Firebase! ${message.notification?.title}",
  );

  // Tampilkan lewat local notification helper
  if (message.notification != null) {
    await NotificationHelper.showNotification(
      id: message.hashCode,
      title: message.notification!.title ?? "NexTask",
      body: message.notification!.body ?? "",
      payload: message.data["task_id"],
    );
  }
}

// Fungsi CallBack Alarm Lama Kamu (Tetap biarkan)
@pragma('vm:entry-point')
void alarmCallBack() async {
  // Pastikan binding terinisialisasi saat dijalankan di isolate background
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  print("NexTask background: Alarm terpacu!");

  // Inisialisasi plugin notifikasi juga di isolate background
  await NotificationHelper.init();

  // Tampilkan notifikasi
  await NotificationHelper.showNotification(
    id: 1,
    title: "Tenggat waktu tugas!",
    body: "Ada tugas yang mendekati deadline nih. Yuk cek sekarang!",
    payload: "deadline",
  );
  print("NexTask: Notifikasi deadline muncul");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Hubungkan fungsi background handler Firebase
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Ambil data tema sebelum aplikasi jalan
  bool isDark = await ThemeSharedPrefs.getTheme();

  // ➕ Jangan lupa inisialisasi helper notifikasi juga di sini ya!
  await NotificationHelper.init();

  tz.initializeTimeZones();

  // ➕ WAJIB TAMBAHKAN INI: Pastikan data lokalisasi bahasa Indonesia siap digunakan
  await initializeDateFormatting("id", null);

  runApp(MyApp(isDarkMode: isDark));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;

  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  Future<void> getFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print("FCM Token didapatkan: $token");

      if (token != null) {
        // Ambil JWT Access Token dari login
        String? jwtToken = await storage.read(key: "access_token");

        if (jwtToken != null) {
          // Kirim token FCM ini ke endpoint user/update-fcm di backend-mu
          final response = await http.post(
            Uri.parse(
              'https://alwi-zahrawi-nextask-backend.hf.space/save-fcm-token',
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({"fcm_token": token}),
          );

          if (response.statusCode == 200) {
            print(
              "NexTask: Berhasil menyinkronkan FCM token ke Database Neon!",
            );
          } else {
            print(
              "NexTask: Gagal sinkronisasi token. Status: ${response.statusCode}",
            );
          }
        }
      }
    } catch (e) {
      print("Error mengambil/mengirim FCM token: $e");
    }
  }

  // Set up penanganan notifikasi saat aplikasi sedang terbuka (Foreground)
  void setupForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("NexTask Foreground: Mendapat notifikasi saat aplikasi terbuka!");

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // Langsung munculkan notifikasi pop up di atas layar menggunakan helper
        NotificationHelper.showNotification(
          id: notification.hashCode,
          title: notification.title ?? "",
          body: notification.body ?? "",
          payload: message.data["task_id"],
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    requestNotificationPermission();
    ReminderService.checkReminder();
    getFCMToken();
    setupForegroundNotification();
  }

  Future<void> requestNotificationPermission() async {
    // 1. cek status izin notifikasi saat ini
    var status = await Permission.notification.status;

    // 2. Jika belum diizinkan, munculkan pop up "Allow / Don't Allow"
    if (status.isDenied) {
      final result = await Permission.notification.request();

      print(await Permission.scheduleExactAlarm.status);
      if (result.isGranted) {
        print("NexTask: Izin notifikasi diberikan");
      } else {
        print("NexTask: Izin ditolak. Notifikasi tidak akan muncul.");
      }
    }

    var statusAlarm = await Permission.scheduleExactAlarm.status;
    if (statusAlarm.isDenied || statusAlarm.isPermanentlyDenied) {
      print("NexTask: Izin alarm presisi belum aktif. Membuka pengaturan...");
      // Ini akan otomatis melempar user ke halaman pengaturan "Alarms & Reminders" Android
      await Permission.scheduleExactAlarm.request();
    }
  }

  // Fungsi ini nantinya di panggil di halaman settings
  void ToogleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    ThemeSharedPrefs.saveTheme(value); // Simpan ke SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'NextTask',
      theme: ThemeData.light(), // Tema Terang
      darkTheme: ThemeData.dark(), // Tema Gelap
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) {
          return Splashscreen(
            onThemeChanged: ToogleTheme,
            isDarkMode: _isDarkMode,
            isMenuDrawer: false,
          );
        },
      ),
    );
  }
}
