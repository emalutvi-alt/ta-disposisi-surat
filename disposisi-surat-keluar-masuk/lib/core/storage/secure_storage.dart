import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'auth_token';
  static const _keyRole = 'auth_role';
  static const _keyUserId = 'auth_user_id';
  static const _keyEmail = 'auth_email';
  static const _keyNama = 'auth_nama';
  static const _keyJabatan = 'auth_jabatan';

  static Future<void> saveSession({
    required String token,
    required String role,
    required int userId,
    required String email,
    required String nama,
    String jabatan = '',
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyRole, value: role),
      _storage.write(key: _keyUserId, value: userId.toString()),
      _storage.write(key: _keyEmail, value: email),
      _storage.write(key: _keyNama, value: nama),
      _storage.write(key: _keyJabatan, value: jabatan),
    ]);
  }

  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<String?> getRole() => _storage.read(key: _keyRole);

  static Future<int?> getUserId() async {
    final v = await _storage.read(key: _keyUserId);
    if (v == null) return null;
    return int.tryParse(v);
  }

  static Future<String?> getEmail() => _storage.read(key: _keyEmail);

  static Future<String?> getNama() => _storage.read(key: _keyNama);

  static Future<String?> getJabatan() => _storage.read(key: _keyJabatan);

  static Future<void> clear() => _storage.deleteAll();
}
