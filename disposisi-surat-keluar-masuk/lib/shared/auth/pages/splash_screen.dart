import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ta_mobile_disposisi_surat/core/storage/app_session.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/role_router.dart';
import 'package:ta_mobile_disposisi_surat/shared/auth/pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _dotFadeAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF2F2F2),
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _dotFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await AppSession.loadFromStorage();
      if (!mounted) return;
      final destination = AppSession.isLoggedIn
          ? RoleRouter.homeForSession()
          : const Login();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo + name dari asset
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // Logo dari asset
                    Image.asset(
                      'assets/images/logoapk.png',
                      width: size.width * 0.28,
                      height: size.width * 0.28,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) {
                        // Fallback ke CustomPainter jika asset tidak ditemukan
                        return SizedBox(
                          width: size.width * 0.28,
                          height: size.width * 0.35,
                          child: CustomPaint(painter: _LogoPainter()),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'E-Disposisi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF147A94),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Loading dots
            FadeTransition(opacity: _dotFadeAnim, child: const _LoadingDots()),
          ],
        ),
      ),
    );
  }
}

// ─── Logo CustomPainter (fallback) ───────────────────────────────────────────

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double sx = size.width / 192;
    final double sy = size.height / 280;

    final paintBody = Paint()
      ..color = const Color(0xFF147A94)
      ..style = PaintingStyle.fill;

    final paintFold = Paint()
      ..color = const Color(0xFF0D5F73)
      ..style = PaintingStyle.fill;

    final bodyPath = Path()
      ..moveTo(28 * sx, 8 * sy)
      ..lineTo(144 * sx, 8 * sy)
      ..lineTo(184 * sx, 48 * sy)
      ..lineTo(184 * sx, 272 * sy)
      ..quadraticBezierTo(184 * sx, 280 * sy, 176 * sx, 280 * sy)
      ..lineTo(28 * sx, 280 * sy)
      ..quadraticBezierTo(20 * sx, 280 * sy, 20 * sx, 272 * sy)
      ..lineTo(20 * sx, 16 * sy)
      ..quadraticBezierTo(20 * sx, 8 * sy, 28 * sx, 8 * sy)
      ..close();

    canvas.drawPath(bodyPath, paintBody);

    final foldPath = Path()
      ..moveTo(144 * sx, 8 * sy)
      ..lineTo(184 * sx, 48 * sy)
      ..lineTo(144 * sx, 48 * sy)
      ..close();

    canvas.drawPath(foldPath, paintFold);

    final lines = [
      (44.0, 120.0, 100.0, 0.9),
      (44.0, 144.0, 80.0, 0.55),
      (44.0, 168.0, 56.0, 0.28),
    ];

    for (final (lx, ly, lw, op) in lines) {
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: op)
        ..style = PaintingStyle.fill;
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(lx * sx, ly * sy, lw * sx, 9 * sy),
        Radius.circular(4.5 * sy),
      );
      canvas.drawRRect(rr, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Loading Dots ─────────────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _dotController,
          builder: (_, __) {
            final t = ((_dotController.value - i * 0.2) % 1.0).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 11 * scale,
              height: 11 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 0
                    ? const Color(0xFF147A94)
                    : const Color(0xFF4D9CD5).withValues(alpha: i == 1 ? 0.7 : 0.35),
              ),
            );
          },
        );
      }),
    );
  }
}
