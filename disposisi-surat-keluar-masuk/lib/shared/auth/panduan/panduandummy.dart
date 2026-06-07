class PanduanDummy {
  PanduanDummy._();

  static const Map<String, dynamic> suratMasuk = {
    'id': 99,
    'jenisSurat': 'Surat Masuk',
    'tanggal': '24 Juni 2026',
    'status': 'disetujui',
    'fromRole': 'tu',
    'toRole': 'kepsek',
    'diteruskanKe': 'Waka_Kurikulum',
    'catatan': 'Segera ditindaklanjuti sesuai instruksi.',
    'tujuan': 'Untuk dihadiri seluruh waka.',
    'instruksi': 'Harap konfirmasi kehadiran H-1.',
    'koordinasi': 'Koordinasikan dengan Waka Kesiswaan.',

    'data': {
      'Nomor Surat': '421.3/045/SMK-TI/VI/2026',
      'Tanggal Surat': '24 Juni 2026',
      'Dari': 'Dinas Pendidikan',
      'Perihal': 'Undangan Rapat Koordinasi',
    },
    'lampiran': ['assets/images/undangan.png'],
  };

  static const Map<String, dynamic> suratKeluar = {
    'id': 100,
    'jenisSurat': 'Surat Keluar',
    'tanggal': '24 Juni 2026',
    'status': 'disetujui',
    'fromRole': 'tu',
    'toRole': 'kepsek',
    'catatan': 'Mohon ditandatangani sebelum dikirim.',
    'data': {
      'Nomor Surat': '422/046/SMK-TI/VI/2026',
      'Tanggal Surat': '24 Juni 2026',
      'Kepada': 'Dinas Pendidikan Kab. Malang',
      'Perihal': 'Permohonan Izin Kegiatan',
    },
    'lampiran': ['assets/images/undangan.png'],
  };

  static const Map<String, dynamic> suratMasukDitolak = {
    'id': 101,
    'jenisSurat': 'Surat Masuk',
    'tanggal': '23 Juni 2026',
    'status': 'ditolak',
    'fromRole': 'tu',
    'toRole': 'kepsek',
    'diteruskanKe': '',
    'catatan': 'Surat tidak sesuai prosedur.',
    'tujuan': '',
    'instruksi': '',
    'koordinasi': '',
    'data': {
      'Nomor Surat': '421.3/044/SMK-TI/VI/2026',
      'Tanggal Surat': '23 Juni 2026',
      'Dari': 'Komite Sekolah',
      'Perihal': 'Permohonan Dana Kegiatan',
    },
    'lampiran': [],
  };

  // Dipakai untuk preview home (stat cards) + menu (list card) + riwayat
  static const List<Map<String, dynamic>> allSurat = [
    suratMasuk,
    suratKeluar,
    suratMasukDitolak,
  ];
}
