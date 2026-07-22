import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

final storage = const FlutterSecureStorage();

class Statistik extends StatefulWidget {
  const Statistik({super.key});

  @override
  State<Statistik> createState() => _StatistikState();
}

class _StatistikState extends State<Statistik> {
  int totalTugas = 0;
  int tugasSelesai = 0;
  int tugasBelum = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStatistik();
  }

  Future<void> fetchStatistik() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? token = await storage.read(key: "access_token");
      final response = await http.get(
        Uri.parse('https://alwi-zahrawi-nextask-backend.hf.space/statistik'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalTugas = data["data"]["total_tugas"];
          tugasSelesai = data["data"]["tugas_selesai"];
          tugasBelum = data["data"]["tugas_belum"];

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Stack khusus Chart + total
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 70,
                            sectionsSpace: 2,

                            sections: [
                              PieChartSectionData(
                                value: tugasSelesai.toDouble(),
                                color: Colors.green,
                                title: "$tugasSelesai",
                                radius: 100,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),

                              PieChartSectionData(
                                value: tugasBelum.toDouble(),
                                color: Colors.blue,
                                title: "$tugasBelum",
                                radius: 100,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Total di tengah donat
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),

                          Text(
                            totalTugas.toString(),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 15, height: 15, color: Colors.green),

                      const SizedBox(width: 5),

                      const Text("Selesai", style: TextStyle(fontSize: 16)),

                      const SizedBox(width: 25),

                      Container(width: 15, height: 15, color: Colors.blue),

                      const SizedBox(width: 5),

                      const Text(
                        "Belum Selesai",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Card Statistik
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 40,
                                    color: Colors.green,
                                  ),

                                  const SizedBox(height: 10),

                                  const Text("Tugas Selesai"),

                                  const SizedBox(height: 10),

                                  Text(
                                    "$tugasSelesai",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.pending_actions,
                                    size: 40,
                                    color: Colors.blue,
                                  ),

                                  const SizedBox(height: 10),

                                  const Text("Belum Selesai"),

                                  const SizedBox(height: 10),

                                  Text(
                                    "$tugasBelum",
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
