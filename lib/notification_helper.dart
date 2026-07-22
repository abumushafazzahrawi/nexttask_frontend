import 'dart:io';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nextask/ui/detailtugas.dart';
import 'package:nextask/main.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Pengaturan untuk android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Ambil data payload jika ada (misal id tugas yang dikirim lewat notifikasi)
        String? taskId = response.payload;

        // disini kita bisa menambahkan logika jika notifikasi ditekan / diklik (misal buka halaman detail tugas)
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => Detailtugas(
              tugas: {
                "id":
                    taskId ??
                    "", //Menyesuaikan dengan parameter Map<dynamic, dynamic>
                "title": "Tugas dari notifikasi", // Opsional, sesuaikan isi
              },
            ),
          ),
        );
      },
    );

    // Buat channel Android secara eksplisit (penting di Android 8+)
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'nextask_deadline_channel', // id
        'Pengingat Tenggat Waktu', // title
        description:
            'Notifikasi untuk mengingatkan tugas yang mendekati deadline',
        importance: Importance.max,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    print("NOW : ${DateTime.now()}");
    print("TARGET : $scheduledDate");

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),

      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'nextask_deadline_channel',
          'Pengingat Tenggat Waktu',
          channelDescription: 'Untuk mengingatkan tugas deadline',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Fungsi untuk memunculkan notif
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'nextask_deadline_channel', //id channel
          'Pengingat Tenggat Waktu', // Nama Channel
          channelDescription:
              "Notifikasi untuk mengingatkan tugas yang mendekati deadline",
          importance: Importance.max,
          priority: Priority.high,
        );

    // Tambahkan detail untuk iOS (Darwin)
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
