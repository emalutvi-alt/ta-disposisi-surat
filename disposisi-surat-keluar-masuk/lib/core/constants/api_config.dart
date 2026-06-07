/// Backend base URL — ganti IP sesuai jaringan WiFi (HP fisik).
/// Emulator Android: bisa pakai http://10.0.2.2:7000
/// HP fisik: http://192.168.x.x:7000 (IP komputer yang menjalankan backend)
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.222.12.2:7000',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
