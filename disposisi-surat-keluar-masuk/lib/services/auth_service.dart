import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ta_mobile_disposisi_surat/core/constants/api_config.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/session.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import 'package:ta_mobile_disposisi_surat/core/storage/app_session.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${Session.token ?? ''}',
  };

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');  // ← tambah /api
    
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(body['message'] ?? 'Login gagal: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    final data = body['data'] ?? {};
    final user = data['user'] ?? {};
    
    await AppSession.save(
      tokenValue: data['token'] ?? '',
      roleValue: user['role'] ?? '',
      userIdValue: user['id'] ?? 0,
      emailValue: user['email'] ?? '',
      namaValue: user['nama'] ?? '',
      jabatanValue: user['jabatan'] ?? '',
    );
    
    return data;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final uri = Uri.parse('$baseUrl/api/profile');  // ← tetap /api
    
    final response = await http.get(uri, headers: _authHeaders);
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat profil: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    final data = body['data'] ?? {};
    
    await AppSession.save(
      tokenValue: Session.token ?? '',
      roleValue: data['role'] ?? Session.role ?? '',
      userIdValue: data['id'] ?? Session.userId ?? 0,
      emailValue: data['email'] ?? Session.email ?? '',
      namaValue: data['nama'] ?? Session.nama ?? '',
      jabatanValue: data['jabatan'] ?? Session.jabatan ?? '',
    );
    
    return data;
  }

  Future<void> logout() async {
    final uri = Uri.parse('$baseUrl/api/logout');  // ← tetap /api
    
    try {
      await http.post(uri, headers: _authHeaders);
    } catch (e) {
      // Ignore error
    }
    
    await AppSession.clear();
  }

  Future<void> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl/api/auth/forgot-password');  // ← tambah /api
    
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw ApiException(body['message'] ?? 'Gagal mengirim OTP: ${response.statusCode}');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Gagal mengirim OTP: ${response.statusCode}');
      }
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
  }

  Future<void> resendOtp(String email) async {
    final uri = Uri.parse('$baseUrl/api/auth/resend-otp');  // ← tambah /api
    
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw ApiException(body['message'] ?? 'Gagal mengirim ulang OTP: ${response.statusCode}');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Gagal mengirim ulang OTP: ${response.statusCode}');
      }
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
  }

  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/verify-otp');  // ← tambah /api
    
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );
    
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw ApiException(body['message'] ?? 'Verifikasi OTP gagal: ${response.statusCode}');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Verifikasi OTP gagal: ${response.statusCode}');
      }
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
    
    final data = body['data'] ?? {};
    return data['reset_token'] ?? '';
  }

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/reset-password');  // ← tambah /api
    
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'reset_token': resetToken,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );
    
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw ApiException(body['message'] ?? 'Reset password gagal: ${response.statusCode}');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Reset password gagal: ${response.statusCode}');
      }
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/change-password');  // ← tetap /api
    
    final response = await http.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );
    
    if (response.statusCode != 200) {
      throw ApiException('Gagal mengubah password: ${response.statusCode}');
    }
    
    final body = jsonDecode(response.body);
    if (!body['success']) throw ApiException(body['message'] ?? 'Unknown error');
  }
}