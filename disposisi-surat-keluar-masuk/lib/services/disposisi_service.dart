import 'package:dio/dio.dart';
import 'package:ta_mobile_disposisi_surat/core/network/dio_client.dart';
import 'package:ta_mobile_disposisi_surat/models/disposisi_model.dart';

class DisposisiService {
  final Dio _dio = DioClient.instance;

  Future<List<DisposisiModel>> list({
    String? status,
    String? verificationStatus,
    String? search,
  }) async {
    try {
      final res = await _dio.get(
        '/api/disposisi',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (verificationStatus != null && verificationStatus.isNotEmpty)
            'verification_status': verificationStatus,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return DioClient.parseData(res, (data) {
        final list = data as List<dynamic>;
        return list
            .map((e) => DisposisiModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on DioException catch (e) {
      throw DioClient.mapError(e);
    }
  }

  Future<void> approve({
    required int disposisiId,
    required bool isApproved,
    String catatan = '',
  }) async {
    try {
      final res = await _dio.post(
        '/api/disposisi/$disposisiId/approve',
        data: {
          'disposisi_id': disposisiId,
          'is_approved': isApproved,
          'catatan': catatan,
        },
      );
      DioClient.parseEnvelope(res);
    } on DioException catch (e) {
      throw DioClient.mapError(e);
    }
  }

  Future<void> create({
    required int suratMasukId,
    required List<int> tujuanIds,
    String catatan = '',
    String sifat = '',
    String batasWaktu = '',
  }) async {
    try {
      final res = await _dio.post('/api/disposisi', data: {
        'surat_masuk_id': suratMasukId,
        'tujuan_ids': tujuanIds,
        'catatan': catatan,
        'sifat': sifat,
        'batas_waktu': batasWaktu,
      });
      DioClient.parseEnvelope(res);
    } on DioException catch (e) {
      throw DioClient.mapError(e);
    }
  }

  /// Mengambil daftar penerima disposisi dari GET /users/disposisi-targets.
  /// Dipanggil oleh DisposisiSuratMasukPage saat kepsek membuat disposisi.
  Future<List<Map<String, dynamic>>> listTargets() async {
    try {
      final res = await _dio.get('/api/users/disposisi-targets');
      return DioClient.parseData(res, (data) {
        final list = data as List<dynamic>;
        return list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } on DioException catch (e) {
      throw DioClient.mapError(e);
    }
  }
}