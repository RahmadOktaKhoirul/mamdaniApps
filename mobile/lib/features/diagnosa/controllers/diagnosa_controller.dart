import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../models/diagnosa_result.dart';

final apiServiceProvider = Provider((_) => ApiService());

class DiagnosaController {
  final ApiService _api;
  DiagnosaController(this._api);

  Future<DiagnosaResult> diagnosa(Map<String, double> gejala, {String? fotoUrl}) async {
    final data = await _api.diagnosa(gejala, fotoUrl: fotoUrl);
    return DiagnosaResult.fromJson(data);
  }
}

final diagnosaControllerProvider = Provider(
  (ref) => DiagnosaController(ref.read(apiServiceProvider)),
);
