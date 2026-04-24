import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/diagnosa_result.dart';

class HasilDiagnosaScreen extends StatelessWidget {
  final DiagnosaResult hasil;
  const HasilDiagnosaScreen({super.key, required this.hasil});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.green, Colors.red, Colors.orange,
      Colors.blue, Colors.purple, Colors.teal,
    ];
    final entries = hasil.semuaSkor.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Diagnosa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hasil utama
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.eco, size: 48),
                  const SizedBox(height: 8),
                  Text(hasil.penyakit,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Confidence: ${hasil.confidence.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 16)),
                  Text('Metode: ${hasil.metode}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pie chart skor semua penyakit
          if (entries.isNotEmpty) ...[
            const Text('Distribusi Skor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(
                sections: entries.asMap().entries.map((e) {
                  final val = (e.value.value as num).toDouble();
                  return PieChartSectionData(
                    value: val,
                    title: '${val.toStringAsFixed(0)}%',
                    color: colors[e.key % colors.length],
                    radius: 80,
                    titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
                  );
                }).toList(),
              )),
            ),
            // Legend
            Wrap(
              spacing: 8,
              children: entries.asMap().entries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: colors[e.key % colors.length]),
                  const SizedBox(width: 4),
                  Text(e.value.key, style: const TextStyle(fontSize: 12)),
                ],
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Treatment
          if (hasil.treatment != null) ...[
            const Text('Rekomendasi Treatment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(hasil.treatment!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
