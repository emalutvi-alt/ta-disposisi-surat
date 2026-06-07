import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/api_config.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/session.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';

class SuratService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${Session.token ?? ''}',
  };

  Future<Map<String, dynamic>> createSuratMasuk({
    required String noSurat,
    required String perihal,
    required String asalSurat,
    required String tanggalSurat,
    required String filePath,
  }) async {
    final uri = Uri.parse('$baseUrl/api/surat-masuk');
    final request = http.MultipartRequest('POST', uri);
    
    request.headers.addAll(_headers);
    request.fields['no_surat'] = noSurat;
    request.fields['perihal_surat'] = perihal;
    request.fields['asal_surat'] = asalSurat;
    request.fields['tanggal_surat'] = tanggalSurat;
    
    final file = await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType('application', 'pdf'),
    );
    request.files.add(file);
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Gagal membuat surat masuk: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    return body['data'] ?? {};
  }

  Future<Map<String, dynamic>> createSuratKeluar({
    required int kodeSurat,
    required String noSurat,
    required String perihal,
    required String tanggalSurat,
    required String filePath,
    String? tujuan,
    String? catatan,
  }) async {
    final uri = Uri.parse('$baseUrl/api/surat-keluar');
    final request = http.MultipartRequest('POST', uri);
    
    request.headers.addAll(_headers);
    request.fields['kode_surat'] = kodeSurat.toString();
    request.fields['no_surat'] = noSurat;
    request.fields['perihal'] = perihal;
    request.fields['tanggal_surat'] = tanggalSurat;
    if (tujuan != null) request.fields['tujuan'] = tujuan;
    if (catatan != null) request.fields['catatan'] = catatan;
    
    final file = await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType('application', 'pdf'),
    );
    request.files.add(file);
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Gagal membuat surat keluar: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    return body['data'] ?? {};
  }

  Future<Map<String, dynamic>> verifikasiSuratMasuk({
    required int suratId,
    required bool isApproved,
    String? catatan,
    List<String>? tujuan,
    String? tanggapanSaran,
    String? prosesLanjut,
    String? koordinasiKonfirmasi,
  }) async {
    final uri = Uri.parse('$baseUrl/api/surat-masuk/$suratId/disposisi');
    
    final body = {
      'status': isApproved ? 'disetujui' : 'ditolak',
      'catatan': catatan ?? '',
      if (isApproved && tujuan != null) 'tujuan': tujuan,
      if (isApproved && tanggapanSaran != null) 'tanggapan_saran': tanggapanSaran,
      if (isApproved && prosesLanjut != null) 'proses_lanjut': prosesLanjut,
      if (isApproved && koordinasiKonfirmasi != null) 'koordinasi_konfirmasi': koordinasiKonfirmasi,
    };
    
    final response = await http.post(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal verifikasi surat masuk: ${response.statusCode}');
    }
    
    final responseBody = jsonDecode(response.body);
    if (!responseBody['success']) throw ApiException(responseBody['message'] ?? 'Unknown error');
    
    return responseBody['data'] ?? {};
  }

  Future<Map<String, dynamic>> verifikasiSuratKeluar({
    required int suratId,
    required bool isApproved,
    String? catatan,
    List<String>? tujuan,
  }) async {
    final uri = Uri.parse('$baseUrl/api/surat-keluar/$suratId/verifikasi-unified');
    
    final body = {
      'status': isApproved ? 'disetujui' : 'ditolak',
      'catatan': catatan ?? '',
      if (isApproved && tujuan != null) 'tujuan': tujuan,
    };
    
    final response = await http.post(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal verifikasi surat keluar: ${response.statusCode}');
    }
    
    final responseBody = jsonDecode(response.body);
    if (!responseBody['success']) throw ApiException(responseBody['message'] ?? 'Unknown error');
    
    return responseBody['data'] ?? {};
  }

  Future<void> markSuratAsRead({
    required int suratId,
    required String jenis,
  }) async {
    final uri = Uri.parse('$baseUrl/api/surat/$suratId/dibaca?jenis=$jenis');
    
    final response = await http.put(
      uri,
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal menandai surat dibaca: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getSuratMasukDetail(int id) async {
    final uri = Uri.parse('$baseUrl/api/surat-masuk/$id');
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat detail surat: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    return body['data'] ?? {};
  }

  Future<Map<String, dynamic>> getSuratKeluarDetail(int id) async {
    final uri = Uri.parse('$baseUrl/api/surat-keluar/$id');
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat detail surat: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    return body['data'] ?? {};
  }
}