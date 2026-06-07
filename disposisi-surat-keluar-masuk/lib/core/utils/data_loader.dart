import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ta_mobile_disposisi_surat/core/constants/api_config.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/session.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import 'package:flutter/material.dart';

class DataLoader {
  static String get baseUrl => ApiConfig.baseUrl;
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${Session.token ?? ''}',
  };

  static Future<List<Map<String, dynamic>>> loadSuratMasuk({
    String? status,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status != 'semua') queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    final uri = Uri.parse('$baseUrl/api/surat-masuk').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat surat masuk: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    final List<dynamic> data = body['data'] ?? [];
    return data.map((item) => _mapSuratMasukToFrontend(item)).toList();
  }

  static Future<List<Map<String, dynamic>>> loadSuratKeluar({
    String? status,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status != 'semua') queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    final uri = Uri.parse('$baseUrl/api/surat-keluar').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat surat keluar: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    final List<dynamic> data = body['data'] ?? [];
    return data.map((item) => _mapSuratKeluarToFrontend(item)).toList();
  }

  static Future<List<Map<String, dynamic>>> loadAllSurat() async {
    final results = await Future.wait([
      loadSuratMasuk(),
      loadSuratKeluar(),
    ]);
    
    final allSurat = <Map<String, dynamic>>[];
    allSurat.addAll(results[0]);
    allSurat.addAll(results[1]);
    
    allSurat.sort((a, b) {
      final aDate = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(1970);
      final bDate = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    
    return allSurat;
  }

  static Future<List<Map<String, dynamic>>> loadSuratByJenis(
    String jenisSurat, {
    String? status,
    String? search,
  }) async {
    if (jenisSurat == 'Surat Masuk') {
      return loadSuratMasuk(status: status, search: search);
    } else {
      return loadSuratKeluar(status: status, search: search);
    }
  }

  static Future<List<Map<String, dynamic>>> loadDisposisiInbox({
    String? verificationStatus,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (verificationStatus != null) queryParams['verification_status'] = verificationStatus;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    final uri = Uri.parse('$baseUrl/api/disposisi').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat disposisi: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    final List<dynamic> data = body['data'] ?? [];
    return data.map((item) => _mapDisposisiToFrontend(item)).toList();
  }

  static Future<NotificationResult> loadNotifications() async {
    final uri = Uri.parse('$baseUrl/api/notifications');
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat notifikasi: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    final data = body['data'] ?? {};
    final items = (data['items'] as List<dynamic>? ?? []).map((item) => {
      'id': item['id'],
      'title': item['title'],
      'desc': item['message'],
      'isRead': item['is_read'],
      'createdAt': item['created_at'],
      'color': _getNotifColor(item['type']),
    }).toList();
    
    return NotificationResult(
      items: items,
      unread: data['unread_count'] ?? 0,
    );
  }

  static Future<Map<String, dynamic>> loadDashboardStats() async {
    final uri = Uri.parse('$baseUrl/api/dashboard');
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat dashboard: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    return body['data'] ?? {};
  }

  static Map<String, dynamic> _mapSuratMasukToFrontend(dynamic item) {
    final pages = item['pages'] as List<dynamic>? ?? [];
    final lampiran = pages.map((p) => p['image_url']?.toString() ?? '').where((url) => url.isNotEmpty).toList();
    
    return {
      'id': item['id'],
      'jenisSurat': 'Surat Masuk',
      'tanggal': item['created_at']?.toString() ?? '-',
      'tanggal_obj': DateTime.tryParse(item['created_at']?.toString() ?? ''),
      'status': _mapStatusToFrontend(item['status_verifikasi'] ?? 'menunggu'),
      'status_alur': item['status_alur'] ?? 'diterima_tu',
      'catatan': item['catatan_verifikasi'] ?? '',
      'tujuan': item['tanggapan_saran'] ?? '',
      'instruksi': item['proses_lanjut'] ?? '',
      'koordinasi': item['koordinasi_konfirmasi'] ?? '',
      'diteruskanKe': item['diteruskan_ke'] ?? '',
      'lampiran': lampiran,
      'data': {
        'Nomor Surat': item['no_surat']?.toString() ?? '-',
        'Dari': item['asal_surat']?.toString() ?? '-',
        'Perihal': item['perihal']?.toString() ?? '-',
        'Tanggal Surat': item['tanggal_surat']?.toString() ?? '-',
      },
    };
  }

  static Map<String, dynamic> _mapSuratKeluarToFrontend(dynamic item) {
    final pages = item['pages'] as List<dynamic>? ?? [];
    final lampiran = pages.map((p) => p['image_url']?.toString() ?? '').where((url) => url.isNotEmpty).toList();
    
    return {
      'id': item['id'],
      'jenisSurat': 'Surat Keluar',
      'tanggal': item['created_at']?.toString() ?? '-',
      'tanggal_obj': DateTime.tryParse(item['created_at']?.toString() ?? ''),
      'status': _mapStatusToFrontend(item['status_verifikasi'] ?? 'menunggu'),
      'status_alur': item['status_alur'] ?? 'diterima_tu',
      'catatan': item['catatan_verifikasi'] ?? '',
      'lampiran': lampiran,
      'data': {
        'Nomor Surat': item['no_surat']?.toString() ?? '-',
        'Dari': 'SMKN 2 Singosari',
        'Perihal': item['perihal']?.toString() ?? '-',
        'Tanggal Surat': item['tanggal_surat']?.toString() ?? '-',
      },
    };
  }

  static Map<String, dynamic> _mapDisposisiToFrontend(dynamic item) {
    final surat = item['surat_masuk'] ?? {};
    final pages = surat['pages'] as List<dynamic>? ?? [];
    final lampiran = pages
        .map((p) => p['image_url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return {
      'id': item['id'],
      'jenisSurat': 'Surat Masuk',
      'tanggal': item['created_at']?.toString() ?? '-',
      'tanggal_obj': DateTime.tryParse(item['created_at']?.toString() ?? ''),
      'status': _mapDisposisiStatusToFrontend(item['status_disposisi'] ?? 'belum_dibaca'),
      'verification_status': item['status_approval'] ?? 'menunggu',
      'catatan': item['catatan'] ?? '',
      'tujuan': item['tanggapan_saran'] ?? '',
      'instruksi': item['proses_lanjut'] ?? '',
      'koordinasi': item['koordinasi_konfirmasi'] ?? '',
      'diteruskanKe': item['tujuan']?['nama']?.toString() ?? '',
      'tanggapan_saran': item['tanggapan_saran'] ?? '',
      'proses_lanjut': item['proses_lanjut'] ?? '',
      'lampiran': lampiran,
      'data': {
        'Nomor Surat': surat['no_surat']?.toString() ?? '-',
        'Dari': surat['asal_surat']?.toString() ?? '-',
        'Perihal': surat['perihal_surat']?.toString() ?? '-',
      },
    };
  }

  static String _mapStatusToFrontend(String backendStatus) {
    switch (backendStatus) {
      case 'menunggu':
        return 'diproses';
      case 'disetujui':
        return 'disetujui';
      case 'ditolak':
        return 'ditolak';
      default:
        return backendStatus;
    }
  }

  static String _mapDisposisiStatusToFrontend(String status) {
    switch (status) {
      case 'belum_dibaca':
        return 'pending';
      case 'dibaca':
      case 'sedang_dikerjakan':
        return 'diterima';
      case 'selesai':
        return 'selesai';
      default:
        return status;
    }
  }

  static Color _getNotifColor(String? type) {
    switch (type) {
      case 'surat_masuk':
        return const Color(0xFF6DA8B4);
      case 'surat_keluar':
        return const Color(0xFFD6A66B);
      case 'disposisi':
        return const Color(0xFF66BB6A);
      case 'approval':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF6DA8B4);
    }
  }
}

class NotificationResult {
  final List<Map<String, dynamic>> items;
  final int unread;
  
  NotificationResult({required this.items, required this.unread});
}