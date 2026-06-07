import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';

enum PanduanPreviewType {
  home,
  menu,
  suratCard,
  detailSurat,
  disposisiMasuk,
  pengajuanKeluar,
  riwayat,
}

class PanduanStepData {
  final IconData icon;
  final String title;
  final String description;
  final PanduanPreviewType previewType;

  const PanduanStepData({
    required this.icon,
    required this.title,
    required this.description,
    required this.previewType,
  });
}

class PanduanSteps {
  static const Color primary = Color(0xFF0F6E7A);

  static List<PanduanStepData> forRole(Role role) => switch (role) {
    Role.kepsek => kepsek,
    Role.tu => tu,

    // Waka tidak memiliki privilege khusus — flow identik dengan user biasa.
    Role.users ||
    Role.wakaKurikulum ||
    Role.wakaKesiswaan ||
    Role.wakaHumas ||
    Role.wakaSarpras => users,
  };

  static const List<PanduanStepData> tu = [
    PanduanStepData(
      icon: Icons.dashboard_outlined,
      title: 'Beranda',
      description:
          'Lihat jumlah surat masuk dan keluar. Ketuk kartu untuk membuka daftarnya.',
      previewType: PanduanPreviewType.home,
    ),
    PanduanStepData(
      icon: Icons.filter_list_outlined,
      title: 'Cari dan Filter Surat',
      description:
          'Gunakan filter status untuk memantau surat yang diproses, disetujui, atau ditolak.',
      previewType: PanduanPreviewType.menu,
    ),
    PanduanStepData(
      icon: Icons.description_outlined,
      title: 'Periksa Detail Surat',
      description:
          'Lihat hasil disposisi dari Kepala Sekolah, termasuk penerima dan catatan yang diberikan.',
      previewType: PanduanPreviewType.detailSurat,
    ),
    PanduanStepData(
      icon: Icons.history_outlined,
      title: 'Riwayat dan Arsip',
      description:
          'Cari kembali surat yang sudah diproses menggunakan pencarian dan filter.',
      previewType: PanduanPreviewType.riwayat,
    ),
  ];

  static const List<PanduanStepData> kepsek = [
    PanduanStepData(
      icon: Icons.dashboard_outlined,
      title: 'Beranda',
      description:
          'Lihat jumlah surat masuk dan keluar. Ketuk kartu untuk membuka daftarnya.',
      previewType: PanduanPreviewType.home,
    ),
    PanduanStepData(
      icon: Icons.inbox_outlined,
      title: 'Daftar Surat',
      description:
          'Semua surat ditampilkan dalam bentuk kartu. Ketuk tombol Detail untuk membuka isi surat.',
      previewType: PanduanPreviewType.suratCard,
    ),
    PanduanStepData(
      icon: Icons.fact_check_outlined,
      title: 'Disposisi Surat Masuk',
      description:
          'Pilih Terima atau Tolak, tentukan penerima, tambahkan catatan, lalu kirim disposisi.',
      previewType: PanduanPreviewType.disposisiMasuk,
    ),
    PanduanStepData(
      icon: Icons.outbound_outlined,
      title: 'Tinjau Surat Keluar',
      description:
          'Periksa pengajuan dari Tata Usaha, baca lampiran, kemudian setujui atau tolak.',
      previewType: PanduanPreviewType.pengajuanKeluar,
    ),
  ];

  static const List<PanduanStepData> users = [
    PanduanStepData(
      icon: Icons.mail_outline,
      title: 'Surat Masuk',
      description: 'Lihat daftar surat yang telah diteruskan kepada Anda.',
      previewType: PanduanPreviewType.menu,
    ),
    PanduanStepData(
      icon: Icons.check_circle_outline,
      title: 'Konfirmasi Penerimaan',
      description:
          'Baca catatan dari Kepala Sekolah untuk menindaklanjuti surat, lalu konfirmasi penerimaannya.',
      previewType: PanduanPreviewType.detailSurat,
    ),
    PanduanStepData(
      icon: Icons.history_outlined,
      title: 'Riwayat Disposisi',
      description:
          'Pantau seluruh surat yang pernah diterima melalui tab Riwayat.',
      previewType: PanduanPreviewType.riwayat,
    ),
  ];
}
