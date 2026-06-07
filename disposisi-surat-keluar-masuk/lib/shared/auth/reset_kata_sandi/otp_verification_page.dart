import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:ta_mobile_disposisi_surat/services/auth_service.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import 'new_password_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final AuthService _authService = AuthService();

  // 6 controller untuk 6 digit OTP
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  // Timer resend OTP
  int _secondsLeft = 60;
  Timer? _timer;

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // FIX P0: Hapus Future.delayed dummy, panggil POST /auth/verify-otp
  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      _showNotif('error', 'Masukkan 6 digit kode OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resetToken = await _authService.verifyOtp(
        email: widget.email,
        otp: _otpCode,
      );

      if (!mounted) return;
      // Teruskan resetToken ke halaman berikutnya
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NewPasswordPage(
            email: widget.email,
            resetToken: resetToken,
          ),
        ),
      );
    } on ApiException catch (e) {
      _showNotif('error', e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FIX P0: Hapus Future.delayed dummy, panggil POST /auth/resend-otp
  Future<void> _resendOtp() async {
    if (_secondsLeft > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await _authService.resendOtp(widget.email);
      _showNotif('success', 'Kode OTP baru telah dikirim');
      _startTimer();
      // Reset semua field OTP
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } on ApiException catch (e) {
      _showNotif('error', e.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showNotif(String type, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: type == 'error' ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

// Gunakan KeyboardListener untuk deteksi backspace saat field kosong
Widget _buildOtpBox(int index) {
  return SizedBox(
    width: 46,
    height: 56,
    child: KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        // Deteksi backspace saat field sudah kosong
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[index].text.isEmpty &&
            index > 0) {
          _focusNodes[index - 1].requestFocus();
        }
      },
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kode OTP dikirim ke\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // 6 kotak OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _buildOtpBox(i)),
            ),
            const SizedBox(height: 32),

            // Tombol Verifikasi
            ElevatedButton(
              onPressed:
                  (_otpCode.length == 6 && !_isLoading) ? _verifyOtp : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verifikasi'),
            ),
            const SizedBox(height: 16),

            // Tombol Kirim Ulang OTP
            TextButton(
              onPressed: (_secondsLeft == 0 && !_isResending)
                  ? _resendOtp
                  : null,
              child: _isResending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _secondsLeft > 0
                          ? 'Kirim ulang OTP (${_secondsLeft}s)'
                          : 'Kirim Ulang OTP',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}