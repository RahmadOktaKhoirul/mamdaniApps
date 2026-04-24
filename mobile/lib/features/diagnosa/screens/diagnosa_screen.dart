import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/diagnosa_controller.dart';
import '../../../core/utils/error_handler.dart';
import 'hasil_diagnosa_screen.dart';

class DiagnosaScreen extends ConsumerStatefulWidget {
  const DiagnosaScreen({super.key});

  @override
  ConsumerState<DiagnosaScreen> createState() => _DiagnosaScreenState();
}

class _DiagnosaScreenState extends ConsumerState<DiagnosaScreen> {
  final Map<String, double> _gejala = {
    'tingkat_kekuningan': 0.0,
    'luas_bercak': 0.0,
    'kondisi_batang': 0.0,
    'pertumbuhan_terhambat': 0.0,
  };

  final _labels = {
    'tingkat_kekuningan': 'Tingkat Kekuningan Daun',
    'luas_bercak': 'Luas Bercak pada Daun',
    'kondisi_batang': 'Kondisi Kerusakan Batang',
    'pertumbuhan_terhambat': 'Pertumbuhan Terhambat',
  };

  File? _foto;
  bool _loading = false;

  Future<void> _pickFoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final controller = ref.read(diagnosaControllerProvider);
      String? fotoUrl;
      if (_foto != null) {
        fotoUrl = await ref.read(apiServiceProvider).uploadFoto(_foto!.path);
      }
      final hasil = await controller.diagnosa(_gejala, fotoUrl: fotoUrl);
      if (mounted) {
        setState(() => _foto = null);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => HasilDiagnosaScreen(hasil: hasil),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(handleError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnosa Penyakit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Foto opsional
          GestureDetector(
            onTap: _pickFoto,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _foto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_foto!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tambah foto (opsional)', style: TextStyle(color: Colors.grey)),
                        Text('Foto meningkatkan akurasi diagnosa',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Geser slider sesuai kondisi tanaman (0 = normal, 10 = parah)',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ..._gejala.keys.map((key) => _buildSlider(key)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
            label: Text(_loading ? 'Menganalisa...' : 'Diagnosa Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String key) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_labels[key]!, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(_gejala[key]!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _gejala[key]!,
              min: 0,
              max: 10,
              divisions: 20,
              onChanged: (v) => setState(() => _gejala[key] = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Normal', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Parah', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
