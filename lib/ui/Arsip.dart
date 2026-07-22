import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nextask/ui/detailtugas.dart';

class Arsip extends StatefulWidget {
  const Arsip({super.key});

  @override
  State<Arsip> createState() => _ArsipState();
}

class _ArsipState extends State<Arsip> {
  List<dynamic> _localDaftarArsip = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDataArsip();
  }

  // Fungsi untuk refresh data dari API lokal
  Future<void> _fetchDataArsip() async {
    setState(() {
      _isLoading = true;
    });

    final storage = const FlutterSecureStorage();
    try {
      String? token = await storage.read(key: "access_token");
      final response = await http.get(
        Uri.parse("https://alwi-zahrawi-nextask-backend.hf.space/arsip/tugas"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _localDaftarArsip = List.from(data["data"] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _localDaftarArsip = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _localDaftarArsip = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Arsip")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _localDaftarArsip.isEmpty
          ? const Center(child: Text("Belum ada arsip"))
          : ListView.builder(
              itemCount: _localDaftarArsip.length,
              itemBuilder: (context, index) {
                final tugas = _localDaftarArsip[index];

                Widget itemTugas = Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: ListTile(
                    leading: Icon(Icons.archive, color: Colors.green),
                    title: Text(tugas["judul"]),
                    subtitle: const Text("Sudah selesai"),

                    onTap: () async {
                      final hasilRefresh = await Navigator.push<bool?>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Detailtugas(tugas: tugas),
                        ),
                      );
                      // agar UI list nya refresh di tempat
                      if (hasilRefresh == true) {
                        await _fetchDataArsip();
                      }
                    },
                  ),
                );

                return Dismissible(
                  key: Key(tugas["id"].toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),

                  direction: DismissDirection.endToStart,

                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Hapus tugas"),
                        content: Text(
                          "Yakin ingin menghapus tugas ${tugas["judul"]}",
                        ),
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
                            },
                            child: Text("Ya"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: itemTugas,
                );
              },
            ),
    );
  }
}
