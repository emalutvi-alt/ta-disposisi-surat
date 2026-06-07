class DisposisiModel {
  final int id;
  final int suratId;
  final String suratNo;
  final String perihal;
  final String tujuanNama;
  final int tujuanId;
  final String status;
  final String verificationStatus;
  final String? catatan;
  final String previewUrl;
  final String? batasWaktu;
  final DateTime? createdAt;

  DisposisiModel({
    required this.id,
    required this.suratId,
    required this.suratNo,
    required this.perihal,
    required this.tujuanNama,
    required this.tujuanId,
    required this.status,
    required this.verificationStatus,
    this.catatan,
    this.previewUrl = '',
    this.batasWaktu,
    this.createdAt,
  });

  factory DisposisiModel.fromJson(Map<String, dynamic> json) {
    final tujuan = json['tujuan'];
    String nama = '';
    int tid = 0;
    if (tujuan is Map<String, dynamic>) {
      nama = tujuan['nama']?.toString() ?? '';
      tid = (tujuan['id'] as num?)?.toInt() ?? 0;
    }
    return DisposisiModel(
      id: (json['id'] as num).toInt(),
      suratId: (json['surat_id'] as num).toInt(),
      suratNo: json['surat_no']?.toString() ?? '',
      perihal: json['perihal']?.toString() ?? '',
      tujuanNama: nama,
      tujuanId: tid,
      status: json['status']?.toString() ?? 'pending',
      verificationStatus: json['verification_status']?.toString() ?? 'menunggu',
      catatan: json['catatan']?.toString(),
      previewUrl: json['preview_url']?.toString() ?? '',
      batasWaktu: json['batas_waktu']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
