class AppConstants {
  // Set via --dart-define=API_BASE_URL=https://your-app.railway.app/api/v1
  // Default: emulator localhost (10.0.2.2 = host machine dari Android emulator)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String diagnosaEndpoint = '$baseUrl/diagnosa';
}
