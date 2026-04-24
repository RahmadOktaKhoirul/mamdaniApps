import 'package:dio/dio.dart';

String handleError(Object e) {
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa jaringan internet kamu.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa jaringan internet kamu.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final msg  = e.response?.data?['detail'];
        if (code == 401) return 'Sesi habis. Silakan login kembali.';
        if (code == 400) return msg ?? 'Permintaan tidak valid.';
        if (code == 404) return 'Data tidak ditemukan.';
        if (code == 500) return 'Terjadi kesalahan pada server.';
        return msg ?? 'Terjadi kesalahan (kode $code).';
      default:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tidak terduga.';
}
