import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/error_handler.dart';
import 'detail_penyakit_screen.dart';

class PenyakitScreen extends StatefulWidget {
  const PenyakitScreen({super.key});

  @override
  State<PenyakitScreen> createState() => _PenyakitScreenState();
}

class _PenyakitScreenState extends State<PenyakitScreen> {
  late final Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getPenyakitList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Penyakit')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text(handleError(snap.error!)));

          final data = snap.data ?? [];
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = data[i];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2E7D32),
                  child: Icon(Icons.eco, color: Colors.white, size: 20),
                ),
                title: Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  p['deskripsi'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailPenyakitScreen(penyakit: p)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
