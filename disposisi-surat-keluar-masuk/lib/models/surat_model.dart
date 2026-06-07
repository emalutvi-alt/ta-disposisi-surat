class SuratModel {
  final int id;
  final String noSurat;
  final String perihal;
  final String? asalSurat;
  final String? tujuan;
  final String status;
  final String? statusVerifikasi;
  final String? previewUrl;
  final String? fileUrl;
  final DateTime? createdAt;
  final bool isMasuk;
  final String? catatanVerifikasi; // ← DITAMBAH: catatan verifikasi dari Kepsek

  SuratModel({
    required this.id,
    required this.noSurat,
    required this.perihal,
    this.asalSurat,
    this.tujuan,
    required this.status,
    this.statusVerifikasi,
    this.previewUrl,
    this.fileUrl,
    this.createdAt,
    required this.isMasuk,
    this.catatanVerifikasi, // ← DITAMBAH
  });

  factory SuratModel.fromMasukJson(Map<String, dynamic> json) {
    return SuratModel(
      id: (json['id'] as num).toInt(),
      noSurat: json['no_surat']?.toString() ?? '',
      perihal: json['perihal']?.toString() ?? '',
      asalSurat: json['asal_surat']?.toString(),
      status: json['status']?.toString() ?? 'diproses',
      statusVerifikasi: json['status_verifikasi']?.toString(),
      previewUrl: json['preview_url']?.toString(),
      fileUrl: json['file_url']?.toString(),
      createdAt: _parseDate(json['created_at']),
      isMasuk: true,
      catatanVerifikasi: json['catatan_verifikasi']?.toString(), // ← DITAMBAH
    );
  }

  factory SuratModel.fromKeluarJson(Map<String, dynamic> json) {
    return SuratModel(
      id: (json['id'] as num).toInt(),
      noSurat: json['no_surat']?.toString() ?? '',
      perihal: json['perihal']?.toString() ?? '',
      tujuan: json['tujuan']?.toString(),
      status: json['status']?.toString() ?? 'diproses',
      statusVerifikasi: json['status_verifikasi']?.toString(),
      previewUrl: json['preview_url']?.toString(),
      fileUrl: json['file_url']?.toString(),
      createdAt: _parseDate(json['created_at']),
      isMasuk: false,
      catatanVerifikasi: json['catatan_verifikasi']?.toString(), // ← DITAMBAH
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}