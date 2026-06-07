import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/role.dart';
import 'core/utils/app_navigator.dart';
import 'core/storage/app_session.dart';

// ── AUTH ─────────────────────────────────────────────────────────────────────
import 'shared/auth/pages/splash_screen.dart';
import 'shared/auth/pages/login_page.dart';
import 'shared/auth/change_password_page.dart';

// ── SHARED ───────────────────────────────────────────────────────────────────
import 'features/profile/profile_page.dart';
import 'features/notifications/notification_page.dart';

// ── TATA USAHA ───────────────────────────────────────────────────────────────
import 'features/tata_usaha/pages/menu_tu.dart';
import 'features/tata_usaha/pages/history_tu.dart';
import 'features/tata_usaha/pages/hasil_pengajuan_surat_keluar_page.dart';
import 'features/tata_usaha/pages/hasil_disposisi_surat_masuk_page.dart';

// ── KEPALA SEKOLAH ───────────────────────────────────────────────────────────
import 'features/kepsek/pages/menu_kepsek_page.dart';
import 'features/kepsek/input_surat_masuk.dart';
import 'features/kepsek/pages/pengajuan_suratkeluar.dart';
import 'features/kepsek/pages/history_kepsek_page.dart';

// ── USER / OTHER ─────────────────────────────────────────────────────────────
import 'features/users/pages/menu_user_page.dart';
import 'features/users/pages/history_user_page.dart';
import 'features/users/pages/detail_surat_users_unified.dart';

class NoAnimationTransitionBuilder extends PageTransitionsBuilder {
  const NoAnimationTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// ── APP ─────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'E-Disposisi',

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],

      locale: const Locale('id', 'ID'),

      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,

        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoAnimationTransitionBuilder(),
            TargetPlatform.iOS: NoAnimationTransitionBuilder(),
          },
        ),

        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Colors.black26,
          selectionHandleColor: Colors.black,
        ),
      ),

      initialRoute: '/splash_screen',

      routes: {
        '/splash_screen': (context) => const SplashScreen(),

        '/signin': (context) => const Login(),

        '/gantipw': (context) => const GantiKataSandiPage(),

        '/profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
          return ProfilePage(
            role: args['role'] as Role,
            );
            },

        '/notif': (context) =>
            NotificationPage(role: Role.tu, notifications: const []),

        // ── TU ───────────────────────────────────────────────────────────────
        '/menu_tu': (context) =>
            const TuDashboardPage(jenisSurat: 'Surat Masuk'),

        '/history_tu': (context) => const HistoryTUPage(),

        '/output_suratmasuk': (context) => const OutputSuratmasuk(
          isApproved: true,
          catatan: '-',
          tujuan: '-',
          instruksi: '-',
          koordinasi: '-',
          diteruskanKe: '-',
        ),

        '/output_suratkeluar': (context) =>
            const OutputSuratkeluar(catatan: '-'),

        // ── KEPSEK ───────────────────────────────────────────────────────────
        '/menu_kepsek': (context) =>
            const KepsekDashboardPage(jenisSurat: 'Surat Masuk'),

        '/history_kepsek': (context) => const HistoryKepsekPage(),

        '/input_suratmasuk': (context) {
          final surat =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return InputSuratMasuk(surat: surat);
        },

        '/input_suratkeluar': (context) {
          final surat =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return InputSuratKeluar(surat: surat);
        },

        // ── USER ─────────────────────────────────────────────────────────────
        '/menu_other': (context) {
          final role = AppSession.role ?? Role.users;
          return MenuUser(
            nama: AppSession.nama ?? '',
            email: AppSession.email ?? '',
            jabatan: AppSession.jabatan ?? '',
            role: role,
          );
        },

        '/history_other': (context) {
          final role = AppSession.role ?? Role.users;
          return HistoryUsersPage(
            role: role,
            nama: AppSession.nama ?? '',
            email: AppSession.email ?? '',
            jabatan: AppSession.jabatan ?? '',
          );
        },

        '/detail_suratUsers': (context) {
          final surat =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return DetailSuratUsers(surat: surat);
        },
      },
    );
  }

  
}
