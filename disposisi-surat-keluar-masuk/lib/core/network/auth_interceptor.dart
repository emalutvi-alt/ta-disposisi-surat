import 'package:dio/dio.dart';
import 'package:ta_mobile_disposisi_surat/core/storage/app_session.dart';

typedef OnUnauthorized = Future<void> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.onUnauthorized});

  final OnUnauthorized? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final t = AppSession.token;
    if (t != null && t.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $t';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isAuthEndpoint = path.endsWith('/auth/login') ||
                             path.endsWith('/auth/forgot-password') ||
                             path.endsWith('/auth/verify-otp') ||
                             path.endsWith('/auth/reset-password');

      await AppSession.clear();

      if (!isAuthEndpoint) {
        await onUnauthorized?.call();
      }
    }
    handler.next(err);
  }
}