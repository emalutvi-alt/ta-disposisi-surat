import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';

//kepsek
import 'package:ta_mobile_disposisi_surat/features/kepsek/input_surat_masuk.dart';
import 'package:ta_mobile_disposisi_surat/features/kepsek/pages/pengajuan_suratkeluar.dart';
import 'package:ta_mobile_disposisi_surat/features/kepsek/pages/menu_kepsek_page.dart';

//tu
import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/history_tu.dart';
import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/menu_tu.dart';
import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/hasil_disposisi_surat_masuk_page.dart';

//user
import 'package:ta_mobile_disposisi_surat/features/users/pages/detail_surat_users_unified.dart';
import 'package:ta_mobile_disposisi_surat/features/users/pages/menu_user_page.dart';

import 'package:ta_mobile_disposisi_surat/features/home/home.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/search_bar.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/surat_card.dart';

import 'panduan_app_preview_frame.dart';
import 'panduandummy.dart';
import 'panduan_step.dart';

class PanduanPreviewBuilder {
  PanduanPreviewBuilder._();

  static Map<String, dynamic> get _sampleSurat =>
      Map<String, dynamic>.from(PanduanDummy.suratMasuk);

  static bool _isUserRole(Role role) =>
      role == Role.users ||
      role == Role.wakaKesiswaan ||
      role == Role.wakaKurikulum ||
      role == Role.wakaHumas ||
      role == Role.wakaSarpras;

  static Widget build({
    required BuildContext context,
    required Role role,
    required PanduanPreviewType type,
    required String nama,
    required String email,
    required String jabatan,
  }) {
    final preview = switch (type) {
      PanduanPreviewType.home => _homePreview(role, nama, email, jabatan),
      PanduanPreviewType.menu => _menuPreview(role, nama, email, jabatan),
      PanduanPreviewType.suratCard => _suratCardPreview(role),
      PanduanPreviewType.detailSurat => _detailPreview(role),
      PanduanPreviewType.disposisiMasuk => _disposisiPreview(),
      PanduanPreviewType.pengajuanKeluar => _pengajuanKeluarPreview(),
      PanduanPreviewType.riwayat => _riwayatPreview(role),
    };

    // alignment khusus untuk detailSurat role user
    final alignment = (type == PanduanPreviewType.detailSurat && _isUserRole(role))
        ? const Alignment(0, 0.9) // ← geser ke bawah, kalibrasi nilai ini
        : _alignment(type);

    return PanduanAppPreviewFrame(
      logicalHeight: _logicalHeight(type),
      frameHeight: _frameHeight(type),
      alignment: alignment,
      child: Material(color: AppColors.bg, child: preview),
    );
  }

  static double _logicalHeight(PanduanPreviewType type) => switch (type) {
    PanduanPreviewType.home => 450,
    PanduanPreviewType.menu => 500,
    PanduanPreviewType.suratCard => 320,
    PanduanPreviewType.detailSurat => 600,
    PanduanPreviewType.disposisiMasuk => 820,
    PanduanPreviewType.pengajuanKeluar => 730,
    PanduanPreviewType.riwayat => 500,
  };

  static double _frameHeight(PanduanPreviewType type) => switch (type) {
    PanduanPreviewType.suratCard => 200,
    _ => 260,
  };

  static Alignment _alignment(PanduanPreviewType type) => switch (type) {
    PanduanPreviewType.detailSurat => Alignment.topCenter,
    PanduanPreviewType.riwayat => Alignment.topCenter,
    _ => Alignment.center,
  };

  // ── Slide 1 — Home ───────────────────────────────────────────────────────
  static Widget _homePreview(
    Role role,
    String nama,
    String email,
    String jabatan,
  ) {
    final Widget homeWidget = _isUserRole(role)
        ? MenuUser(nama: nama, email: email, jabatan: jabatan, role: role)
        : Home(
            role: role,
            nama: nama,
            email: email,
            jabatan: jabatan,
            suratOverride: PanduanDummy.allSurat,
          );

    final highlightTop = role == Role.tu ? 123.0 : 120.0;
    final highlightHeight = role == Role.tu ? 90.0 : 100.0;

    return Stack(
      children: [
        IgnorePointer(child: homeWidget),
        Positioned(
          top: highlightTop,
          left: 8,
          right: 8,
          child: IgnorePointer(
            child: Container(
              height: highlightHeight,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.spotlight, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Slide 2 — Menu ───────────────────────────────────────────────────────
  static Widget _menuPreview(
    Role role,
    String nama,
    String email,
    String jabatan,
  ) {
    final menuWidget = switch (role) {
      Role.kepsek => const KepsekDashboardPage(jenisSurat: 'Surat Masuk'),
      Role.tu => TuDashboardPage(
        jenisSurat: 'Surat Masuk',
        suratOverride: PanduanDummy.allSurat,
      ),
      Role.users ||
      Role.wakaKesiswaan ||
      Role.wakaKurikulum ||
      Role.wakaHumas ||
      Role.wakaSarpras => MenuUser(
        nama: nama,
        email: email,
        jabatan: jabatan,
        role: role,
      ),
    };

    final highlightTop = switch (role) {
      Role.tu => 155.0,
      Role.kepsek => 150.0,
      _ => 105.0,
    };
    final highlightHeight = switch (role) {
      Role.tu => 55.0,
      Role.kepsek => 45.0,
      _ => 60.0,
    };
    final highlightLeft = switch (role) {
      Role.tu => 10.0,
      Role.kepsek => 265.0,
      _ => 10.0,
    };
    final highlightRight = switch (role) {
      Role.tu => 10.0,
      Role.kepsek => 20.0,
      _ => 10.0,
    };

    return Stack(
      children: [
        IgnorePointer(child: menuWidget),
        if (!_isUserRole(role))
          Positioned(
            top: highlightTop,
            right: highlightRight,
            left: highlightLeft,
            child: IgnorePointer(
              child: Container(
                height: highlightHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.spotlight, width: 3),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Slide 3 — Detail Surat ───────────────────────────────────────────────
  static Widget _detailPreview(Role role) {
    final bool isUser = _isUserRole(role);

    final highlightTop = isUser ? 435.0 : 50.0;
    final highlightHeight = isUser ? 100.0 : 220.0;

    final Widget detailWidget = isUser
        ? DetailSuratUsers(surat: _sampleSurat)
        : OutputSuratmasuk(
            isApproved: true,
            catatan: _sampleSurat['catatan'] ?? '',
            tujuan: _sampleSurat['tujuan'] ?? '',
            instruksi: _sampleSurat['instruksi'] ?? '',
            koordinasi: _sampleSurat['koordinasi'] ?? '',
            diteruskanKe: _sampleSurat['diteruskanKe'] ?? '',
          );

    return Stack(
      children: [
        IgnorePointer(child: detailWidget),
        Positioned(
          top: highlightTop,
          left: 14,
          right: 14,
          child: IgnorePointer(
            child: Container(
              height: highlightHeight,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.spotlight, width: 3),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Disposisi preview — Kepsek ───────────────────────────────────────────
  static Widget _disposisiPreview() {
    return Stack(
      children: [
        IgnorePointer(child: InputSuratMasuk(surat: _sampleSurat)),
        Positioned(
          top: 480,
          left: 14,
          right: 14,
          child: IgnorePointer(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.spotlight, width: 3),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Pengajuan Keluar preview ─────────────────────────────────────────────
  static Widget _pengajuanKeluarPreview() {
    return Stack(
      children: [
        const IgnorePointer(child: InputSuratKeluar()),
        Positioned(
          top: 445,
          left: 33,
          right: 33,
          child: IgnorePointer(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.spotlight, width: 3),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Surat card preview ───────────────────────────────────────────────────
  static Widget _suratCardPreview(Role role) {
    final surat = _sampleSurat;
    final cardRole = switch (role) {
      Role.kepsek => CardRole.kepsek,
      Role.tu => CardRole.tu,
      Role.users ||
      Role.wakaKesiswaan ||
      Role.wakaKurikulum ||
      Role.wakaHumas ||
      Role.wakaSarpras => CardRole.users,
    };

    final highlightTop = switch (role) {
      Role.kepsek => 153.0,
      Role.tu => 18.0,
      _ => 18.0,
    };
    final highlightRight = switch (role) {
      Role.kepsek => 5.0,
      Role.tu => 5.0,
      _ => 5.0,
    };
    final highlightWidth = switch (role) {
      Role.kepsek => 90.0,
      Role.tu => 90.0,
      _ => 90.0,
    };
    final highlightHeight = switch (role) {
      Role.kepsek => 38.0,
      Role.tu => 38.0,
      _ => 38.0,
    };

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disposisi Surat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SearchBarInput(onChanged: (_) {}),
                const SizedBox(height: 12),
                SuratCard(
                  jenisSurat: surat['jenisSurat'] ?? '',
                  tanggal: surat['tanggal'] ?? '',
                  data: Map<String, String>.from(surat['data'] ?? {}),
                  role: cardRole,
                  type: CardType.menu,
                  status: surat['status'],
                  diteruskanKe: surat['diteruskanKe'],
                  onDetail: () {},
                ),
              ],
            ),
            Positioned(
              top: highlightTop,
              right: highlightRight,
              child: IgnorePointer(
                child: Container(
                  width: highlightWidth,
                  height: highlightHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.spotlight, width: 3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Slide 4 — Riwayat ────────────────────────────────────────────────────
  static Widget _riwayatPreview(Role role) {
    return Stack(
      children: [
        IgnorePointer(
          child: HistoryTUPage(suratOverride: PanduanDummy.allSurat),
        ),
        Positioned(
          top: 98,
          left: 10,
          right: 10,
          child: IgnorePointer(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.spotlight, width: 3),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}