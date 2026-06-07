import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/api_config.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import 'package:ta_mobile_disposisi_surat/core/network/auth_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio? _dio;
  static OnUnauthorized? _onUnauthorized;

  static void init({OnUnauthorized? onUnauthorized}) {
    _onUnauthorized = onUnauthorized;
    _dio = null;
  }

  static Dio get instance {
    _dio ??= _build();
    return _dio!;
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(onUnauthorized: _onUnauthorized),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }

  static Map<String, dynamic> parseEnvelope(Response response) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiException('Format response tidak valid');
    }
    final success = data['success'] == true;
    if (!success) {
      throw ApiException(
        data['message']?.toString() ?? 'Request gagal',
        statusCode: response.statusCode,
        errors: data['errors'],
      );
    }
    return data;
  }

  static T parseData<T>(
    Response response,
    T Function(dynamic json) fromJson,
  ) {
    final envelope = parseEnvelope(response);
    return fromJson(envelope['data']);
  }

  static ApiException mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException('Koneksi timeout, coba lagi');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        'Tidak dapat terhubung ke server. Periksa BASE_URL (${ApiConfig.baseUrl})',
      );
    }
    final res = e.response;
    if (res?.data is Map<String, dynamic>) {
      final m = res!.data as Map<String, dynamic>;
      return ApiException(
        m['message']?.toString() ?? 'Terjadi kesalahan',
        statusCode: res.statusCode,
        errors: m['errors'],
      );
    }
    if (res?.statusCode == 403) {
      return ApiException('Akses ditolak', statusCode: 403);
    }
    return ApiException(e.message ?? 'Terjadi kesalahan jaringan');
  }
}