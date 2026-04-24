import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _supabase = Supabase.instance.client;
  final _namaCtrl   = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _hpCtrl     = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final res = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (res != null && mounted) {
      setState(() {
        _namaCtrl.text   = res['nama'] ?? '';
        _lokasiCtrl.text = res['lokasi_kebun'] ?? '';
        _hpCtrl.text     = res['no_hp'] ?? '';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('profiles').upsert({
        'id': userId,
        'nama': _namaCtrl.text.trim(),
        'lokasi_kebun': _lokasiCtrl.text.trim(),
        'no_hp': _hpCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan profil')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _lokasiCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _supabase.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar placeholder
          const Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(email, style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 24),

          TextField(
            controller: _namaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lokasiCtrl,
            decoration: const InputDecoration(
              labelText: 'Lokasi Kebun',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hpCtrl,
            decoration: const InputDecoration(
              labelText: 'No. HP',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Simpan Profil'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Keluar', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
