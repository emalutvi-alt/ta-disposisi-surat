import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ta_mobile_disposisi_surat/core/constants/api_config.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/session.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';

class NotificationService {
  static String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${Session.token ?? ''}',
  };

  Future<void> markAsRead(int notificationId) async {
    final uri = Uri.parse('$baseUrl/api/notifications/$notificationId/read');
    
    final response = await http.put(
      uri,
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal menandai notifikasi: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
  }

  Future<void> markAllAsRead() async {
    final uri = Uri.parse('$baseUrl/api/notifications/read-all');
    
    final response = await http.put(
      uri,
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal menandai semua notifikasi: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
  }

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    String? type,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (unreadOnly) queryParams['unread_only'] = 'true';
    if (type != null) queryParams['type'] = type;
    
    final uri = Uri.parse('$baseUrl/api/notifications').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat notifikasi: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    return body['data'] ?? {};
  }
}