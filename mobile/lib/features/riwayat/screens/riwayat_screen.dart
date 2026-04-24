import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../diagnosa/controllers/diagnosa_controller.dart';
import '../../../core/utils/error_handler.dart';
import 'detail_riwayat_screen.dart';

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});

  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  late Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _future = ref.read(apiServiceProvider).getRiwayat();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Diagnosa')),
      body: _future == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text(handleError(snap.error!)));
          final data = snap.data ?? [];
          if (data.isEmpty) return const Center(child: Text('Belum ada riwayat diagnosa'));

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              final item = data[i];
              return ListTile(
                leading: const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                title: Text(item['penyakit_nama'] ?? '-'),
                subtitle: Text('Confidence: ${(item['confidence_final'] as num).toStringAsFixed(1)}%'),
                trailing: Text(
                  item['metode'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailRiwayatScreen(diagnosaId: item['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
