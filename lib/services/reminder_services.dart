import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nextask/notification_helper.dart';

class ReminderService {
  static Future<void> checkReminder() async {
    final storage = FlutterSecureStorage();

    try {
      String? token = await storage.read(key: "access_token");

      final response = await http.get(
        Uri.parse(
          "https://alwi-zahrawi-nextask-backend.hf.space/reminder/check",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List reminders = data["data"];

        for (var item in reminders) {
          await NotificationHelper.showNotification(
            id: item["id"],
            title: "Deadline Mendekat!",
            body: "${item["judul"]} hampir dateline",
            payload: item["id"].toString(),
          );
        }
      }
    } catch (e) {
      print("Reminder Error: $e");
    }
  }
}
