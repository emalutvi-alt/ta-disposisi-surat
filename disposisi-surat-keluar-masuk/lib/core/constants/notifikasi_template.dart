import 'package:flutter/material.dart';

// ── DUMMY DATA ────────────────────────────────────────────────────────────────

final List<Map<String, dynamic>> notifTU = [
  {
    //ketika kepsek mengklik button tolak di detail surat yang ada di kepsek (file:diposisi_suratmasuk.dart)
    'title': 'Surat Masuk Ditolak',
    'desc':
        'Surat masuk telah ditolak Kepala Sekolah. Silakan periksa kembali dan tindak lanjuti.',
    'color': Colors.red,
    'isRead': false,
    'createdAt': DateTime.now(),
  },
  {
    //ketika kepsek mengklik button terima di detail surat yang ada di kepsek (file:diposisi_suratmasuk.dart)
    'title': 'Surat Masuk Diterima',
    'desc':
        'Surat masuk telah diterima Kepala Sekolah. Silakan lanjutkan proses.',
    'color': Colors.green,
    'isRead': false,
    'createdAt': DateTime.now(),
  },
  {
    //ketika kepsek mengklik button tolak di detail surat yang ada di kepsek (file:pengajuan_suratkeluar.dart)
    'title': 'Surat Keluar Ditolak',
    'desc':
        'Surat keluar ditolak Kepala Sekolah. Periksa kembali dan tindak lanjuti.',
    'color': Colors.red,
    'isRead': true,
    'createdAt': DateTime.now(),
  },
  {
    //ketika kepsek mengklik button terima di detail surat yang ada di kepsek (file:pengajuan_suratkeluar.dart)
    'title': 'Surat Keluar Diterima',
    'desc':
        'Surat keluar telah diterima Kepala Sekolah. Silakan lanjutkan proses.',
    'color': Colors.green,
    'isRead': true,
    'createdAt': DateTime.now(),
  },
  {
    //ketika kepsek mengklik button konfirmasi di detail surat yang ada di detail user dan jika waka meneruskan surat ke guru biasa meskipun button nya 'teruskan' maka sistem mengirimkan pesan ini juga sebagai bukti sudah dibaca (file:detail_surat_user.dart)
    'title': 'Surat Masuk Dikonfirmasi',
    'desc': 'Surat masuk sudah dikonfirmasi oleh penerima.',
    'color': Colors.blue,
    'isRead': true,
    'createdAt': DateTime.now(),
  },
];

final List<Map<String, dynamic>> notifKepsek = [
  {
    //ketika ada data surat keluar yang masuk dari platform web dan dekstop
    'title': 'Pemberitahuan Pengajuan Surat Keluar',
    'desc':
        'Terdapat pengajuan surat keluar yang memerlukan peninjauan dari Anda.',
    'color': Colors.orange,
    'isRead': false,
    'createdAt': DateTime.now(),
  },
  {
    //ketika ada data surat masuk yang masuk dari platform web dan dekstop
    'title': 'Pemberitahuan Pengajuan Disposisi Surat Masuk',
    'desc':
        'Terdapat pengajuan disposisi surat masuk yang memerlukan persetujuan Anda.',
    'color': Colors.blue,
    'isRead': false,
    'createdAt': DateTime.now(),
  },
];

final List<Map<String, dynamic>> notifUser = [
  {
    //ketika tu atau waka mengklik button teruskan (file: hasil_disposisi_surat_masuk.dart dan menu_user_page.dart)
    'title': 'Pemberitahuan Surat Masuk',
    'desc':
        'Anda menerima surat masuk baru. Silakan periksa detail surat untuk informasi lebih lanjut.',
    'color': Colors.blue,
    'isRead': false,
    'createdAt': DateTime.now(),
  },
];