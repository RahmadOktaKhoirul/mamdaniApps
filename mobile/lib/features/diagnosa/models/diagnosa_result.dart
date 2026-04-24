class DiagnosaResult {
  final String id;
  final String penyakit;
  final double confidence;
  final String metode;
  final Map<String, dynamic> semuaSkor;
  final String? treatment;
  final String? fotoUrl;
  final DateTime createdAt;

  DiagnosaResult.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        penyakit = j['penyakit'],
        confidence = (j['confidence'] as num).toDouble(),
        metode = j['metode'],
        semuaSkor = Map<String, dynamic>.from(j['semua_skor'] ?? {}),
        treatment = j['treatment'],
        fotoUrl = j['foto_url'],
        createdAt = DateTime.parse(j['created_at']);
}
