import 'package:intl/intl.dart';
import 'package:ta_mobile_disposisi_surat/models/disposisi_model.dart';
import 'package:ta_mobile_disposisi_surat/models/surat_model.dart';

class SuratUiMapper {
  static final _dateFmt = DateFormat('d MMM yyyy');

  static Map<String, dynamic> fromSurat(SuratModel s) {
    final jenis = s.isMasuk ? 'Surat Masuk' : 'Surat Keluar';
    final lampiran = <String>[];
    if (s.previewUrl != null && s.previewUrl!.isNotEmpty) {
      lampiran.add(s.previewUrl!);
    }

    return {
      'id': s.id,
      'jenisSurat': jenis,
      'tanggal': s.createdAt != null ? _dateFmt.format(s.createdAt!) : '-',
      'tanggal_obj': s.createdAt,
      'status': s.status,
      'data': {
        'Nomor Surat': s.noSurat,
        'Tanggal Surat': s.createdAt != null ? _dateFmt.format(s.createdAt!) : '-',
        'Dari': s.isMasuk ? (s.asalSurat ?? '-') : 'SMKN 2 Singosari',
        'Perihal': s.perihal,
      },
      'lampiran': lampiran,
      'preview_url': s.previewUrl ?? '',
      'file_url': s.fileUrl ?? '',
      'catatan': s.catatanVerifikasi ?? '', // ← FIX: ambil dari API, bukan hardcode ''
      'diteruskanKe': s.tujuan ?? '',
    };
  }

  static Map<String, dynamic> fromDisposisi(DisposisiModel d) {
    final lampiran = <String>[];
    if (d.previewUrl.isNotEmpty) {
      lampiran.add(d.previewUrl);
    }

    String uiStatus = 'diproses';
    if (d.status == 'ditolak' || d.verificationStatus == 'ditolak') {
      uiStatus = 'ditolak';
    } else if (d.status == 'selesai' || d.verificationStatus == 'disetujui') {
      uiStatus = 'disetujui';
    }

    return {
      'id': d.suratId,
      'disposisi_id': d.id,
      'jenisSurat': 'Surat Masuk',
      'tanggal': d.createdAt != null ? _dateFmt.format(d.createdAt!) : '-',
      'tanggal_obj': d.createdAt,
      'status': uiStatus,
      'verification_status': d.verificationStatus,
      'data': {
        'Nomor Surat': d.suratNo,
        'Tanggal Surat': d.createdAt != null ? _dateFmt.format(d.createdAt!) : '-',
        'Dari': '-',
        'Perihal': d.perihal,
      },
      'lampiran': lampiran,
      'preview_url': d.previewUrl,
      'catatan': d.catatan ?? '',
      'diteruskanKe': d.tujuanNama,
    };
  }
}