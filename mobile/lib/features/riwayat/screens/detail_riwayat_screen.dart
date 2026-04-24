import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../diagnosa/models/diagnosa_result.dart';

class DetailRiwayatScreen extends StatefulWidget {
  final String diagnosaId;
  const DetailRiwayatScreen({super.key, required this.diagnosaId});

  @override
  State<DetailRiwayatScreen> createState() => _DetailRiwayatScreenState();
}

class _DetailRiwayatScreenState extends State<DetailRiwayatScreen> {
  late Future<DiagnosaResult> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService()
        .getDetail(widget.diagnosaId)
        .then(DiagnosaResult.fromJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Diagnosa')),
      body: FutureBuilder<DiagnosaResult>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(handleError(snap.error!)));
          }
          final d = snap.data!;
          return _buildBody(context, d);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DiagnosaResult d) {
    final colors = [
      Colors.green, Colors.red, Colors.orange,
      Colors.blue, Colors.purple, Colors.teal,
    ];
    final entries = d.semuaSkor.entries.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tanggal
        Text(
          '${d.createdAt.day}/${d.createdAt.month}/${d.createdAt.year} '
          '${d.createdAt.hour.toString().padLeft(2, '0')}:${d.createdAt.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),

        // Hasil utama
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.eco, size: 48),
                const SizedBox(height: 8),
                Text(d.penyakit,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Confidence: ${d.confidence.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16)),
                Chip(label: Text(d.metode.toUpperCase())),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Foto jika ada
        if (d.fotoUrl != null) ...[
          const Text('Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(d.fotoUrl!, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
        ],

        // Pie chart
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
          Wrap(
            spacing: 8,
            runSpacing: 4,
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
        if (d.treatment != null) ...[
          const Text('Rekomendasi Treatment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(d.treatment!),
            ),
          ),
        ],
      ],
    );
  }
}
