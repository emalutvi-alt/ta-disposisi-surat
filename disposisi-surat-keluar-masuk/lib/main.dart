import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ta_mobile_disposisi_surat/core/network/dio_client.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/app_navigator.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  DioClient.init(onUnauthorized: () async {
    navigateToLogin();
  });

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}
