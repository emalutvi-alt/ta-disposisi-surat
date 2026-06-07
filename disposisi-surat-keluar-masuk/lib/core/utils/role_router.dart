import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/storage/app_session.dart';
import 'package:ta_mobile_disposisi_surat/features/home/home.dart';
import 'package:ta_mobile_disposisi_surat/features/users/pages/menu_user_page.dart';
import 'package:ta_mobile_disposisi_surat/shared/auth/pages/login_page.dart';

class RoleRouter {
  static Widget homeForSession() {
    if (!AppSession.isLoggedIn || AppSession.role == null) {
      return const Login();
    }

    final role = AppSession.role!;
    final nama = AppSession.nama ?? '';
    final email = AppSession.email ?? '';
    final jabatan = AppSession.jabatan ?? '';

    final isUserRole = role == Role.users ||
        role == Role.wakaKurikulum ||
        role == Role.wakaKesiswaan ||
        role == Role.wakaHumas ||
        role == Role.wakaSarpras;

    if (isUserRole) {
      return MenuUser(
        nama: nama,
        email: email,
        jabatan: jabatan,
        role: role,
      );
    }

    return Home(
      role: role,
      nama: nama,
      email: email,
      jabatan: jabatan,
    );
  }

  static void goHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => homeForSession()),
      (_) => false,
    );
  }
}
