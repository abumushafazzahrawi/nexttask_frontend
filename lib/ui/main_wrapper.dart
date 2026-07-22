import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:nextask/ui/home.dart'; // Sesuaikan dengan path Home kamu

class MainWrapper extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;
  const MainWrapper({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // Kita buat global controller agar bisa diakses dari halaman Home nanti
  late final ZoomDrawerController _zoomDrawerController;

  @override
  void initState() {
    super.initState();
    _zoomDrawerController = ZoomDrawerController();
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: _zoomDrawerController,
      borderRadius: 24.0,
      showShadow: true,
      angle: -12.0, //Efek miring estetik saat di zoom
      slideWidth: MediaQuery.of(context).size.width * 0.65,
      menuBackgroundColor: widget.isDarkMode ? Colors.grey[900]! : Colors.blue,

      // MENUSCREEN: Menampilkan Drawer (isMenuDrawer: true)
      menuScreen: Home(
        onThemeChanged: widget.onThemeChanged,
        isDarkMode: widget.isDarkMode,
      ),

      // MAINSCREEN: Menampilkan Halaman Utama Tugas (isMenuDrawer: false)
      mainScreen: Home(
        onThemeChanged: widget.onThemeChanged,
        isDarkMode: widget.isDarkMode,
      ),
    );
  }
}
