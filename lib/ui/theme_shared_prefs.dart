import 'package:shared_preferences/shared_preferences.dart';

class ThemeSharedPrefs {
  static const String _key = "isDarkMode";

  // Fungsi untuk menyimpan pilihan tema
  static Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
  }

  // Fungsi untuk ambil data tema yang tersimpan
  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false; // Default nya false (Light Mode)
  }
}
