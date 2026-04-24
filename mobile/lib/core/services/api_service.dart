import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class ApiService {
  final _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  String? get _token => Supabase.instance.client.auth.currentSession?.accessToken;

  Options get _authOptions => Options(headers: {'Authorization': 'Bearer $_token'});

  Future<Map<String, dynamic>> diagnosa(Map<String, dynamic> gejala, {String? fotoUrl}) async {
    final res = await _dio.post(
      '/diagnosa/',
      data: {'gejala': gejala, if (fotoUrl != null) 'foto_url': fotoUrl},
      options: _authOptions,
    );
    return res.data;
  }

  Future<List<dynamic>> getRiwayat() async {
    final res = await _dio.get('/riwayat/', options: _authOptions);
    return res.data;
  }

  Future<Map<String, dynamic>> getDetail(String id) async {
    final res = await _dio.get('/diagnosa/$id', options: _authOptions);
    return res.data;
  }

  Future<List<dynamic>> getPenyakitList() async {
    final res = await _dio.get('/diagnosa/penyakit/list');
    return res.data;
  }

  Future<String> uploadFoto(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/diagnosa/upload-foto', data: form, options: _authOptions);
    return res.data['foto_url'] as String;
  }
}
