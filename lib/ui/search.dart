import 'package:flutter/material.dart';
import 'package:nextask/ui/detailtugas.dart';

class Search extends SearchDelegate {
  final List<dynamic> daftarTugas;

  Search(this.daftarTugas);

  // Tombol dikiri appBar Search
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = "";
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  // Tombol Back
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  // Hasil Search
  @override
  Widget buildResults(BuildContext context) {
    final hasilsearch = daftarTugas.where((tugas) {
      return tugas["judul"].toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (hasilsearch.isEmpty) {
      return Center(child: Text("Tugas tidak ditemukan"));
    }

    return ListView.builder(
      itemCount: hasilsearch.length,
      itemBuilder: (context, index) {
        final tugas = hasilsearch[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(tugas["judul"]),
            trailing: Icon(
              tugas["done"] == true
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: tugas["done"] == true ? Colors.green : Colors.grey,
            ),

            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Detailtugas(tugas: tugas),
                ),
              );

              if (result == true && context.mounted) {
                close(context, true);
              }
            },
          ),
        );
      },
    );
  }

  // Tampilan realtime saat mengetik
  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
