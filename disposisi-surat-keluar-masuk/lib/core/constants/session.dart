// lib/core/constants/session.dart
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/storage/app_session.dart';

class Session {
  static String nama = '';
  static String email = '';
  static String jabatan = '';
  static Role role = Role.users;

  static String? get token => AppSession.token;
  static int? get userId => AppSession.userId;

  static bool get isWaka =>
      role == Role.wakaKesiswaan ||
      role == Role.wakaKurikulum ||
      role == Role.wakaHumas ||
      role == Role.wakaSarpras;
}

