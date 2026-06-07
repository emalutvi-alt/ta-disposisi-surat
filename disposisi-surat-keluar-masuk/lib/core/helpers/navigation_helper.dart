import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/features/users/pages/history_user_page.dart';
import 'package:ta_mobile_disposisi_surat/features/home/home.dart';
import 'package:ta_mobile_disposisi_surat/features/profile/profile_page.dart';
import 'package:ta_mobile_disposisi_surat/features/users/pages/menu_user_page.dart';

void handleNavbarTap(
  BuildContext context,
  int index,
  Role role,
  String nama,
  String email,
  String jabatan,
) {
  switch (index) {
    /// HOME / MENU
    case 0:
      final isUserRole =
          role == Role.users ||
          role == Role.wakaKurikulum ||
          role == Role.wakaKesiswaan ||
          role == Role.wakaHumas ||
          role == Role.wakaSarpras;

      if (isUserRole) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuUser(
              nama: nama,
              email: email,
              jabatan: jabatan,
              role: role,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                Home(role: role, nama: nama, email: email, jabatan: jabatan),
          ),
        );
      }
      break;

    /// HISTORY
    case 1:
      if (role == Role.tu) {
        Navigator.pushNamed(context, '/history_tu');
      } else if (role == Role.kepsek) {
        Navigator.pushNamed(context, '/history_kepsek');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryUsersPage(
              role: role,
              nama: nama,
              email: email,
              jabatan: jabatan,
            ),
          ),
        );
      }
      break;

    /// PROFILE
    case 2:
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProfilePage(role: role),
    ),
  );
  }
}
