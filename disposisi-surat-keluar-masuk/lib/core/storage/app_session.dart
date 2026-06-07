import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/storage/secure_storage.dart';

/// In-memory session mirror (loaded from secure storage on startup).
class AppSession {
  AppSession._();

  static String? token;
  static Role? role;
  static int? userId;
  static String? email;
  static String? nama;
  static String? jabatan;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static Future<void> loadFromStorage() async {
    token = await SecureStorage.getToken();
    final r = await SecureStorage.getRole();
    role = _parseRole(r);
    userId = await SecureStorage.getUserId();
    email = await SecureStorage.getEmail();
    nama = await SecureStorage.getNama();
    jabatan = await SecureStorage.getJabatan();
  }

  static Future<void> save({
    required String tokenValue,
    required String roleValue,
    required int userIdValue,
    required String emailValue,
    required String namaValue,
    String jabatanValue = '',
  }) async {
    token = tokenValue;
    role = _parseRole(roleValue);
    userId = userIdValue;
    email = emailValue;
    nama = namaValue;
    jabatan = jabatanValue;

    await SecureStorage.saveSession(
      token: tokenValue,
      role: roleValue,
      userId: userIdValue,
      email: emailValue,
      nama: namaValue,
      jabatan: jabatanValue,
    );
  }

  static Future<void> clear() async {
    token = null;
    role = null;
    userId = null;
    email = null;
    nama = null;
    jabatan = null;
    await SecureStorage.clear();
  }

  static Role? _parseRole(String? value) {
    switch (value) {
      case 'tu':
      case 'admin':
        return Role.tu;
      case 'kepsek':
        return Role.kepsek;
      case 'users':
      case 'user':
      case 'pegawai':
        return Role.users;
      case 'wakaKurikulum':
      case 'waka_kurikulum':
      case 'wakakurikulum':
        return Role.wakaKurikulum;
      case 'wakaKesiswaan':
      case 'waka_kesiswaan':
      case 'wakakesiswaan':
        return Role.wakaKesiswaan;
      case 'wakaHumas':
      case 'waka_humas':
      case 'wakahumas':
        return Role.wakaHumas;
      case 'wakaSarpras':
      case 'waka_sarpras':
      case 'wakasarpras':
        return Role.wakaSarpras;
      default:
        // Fallback: role tidak dikenali → anggap users biasa
        return Role.users;
    }
  }
}
