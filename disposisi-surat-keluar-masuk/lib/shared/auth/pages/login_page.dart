import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ta_mobile_disposisi_surat/core/constants/session.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import '../panduan/panduan_page.dart';

import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/storage/app_session.dart';
import 'package:ta_mobile_disposisi_surat/services/auth_service.dart';
import 'package:ta_mobile_disposisi_surat/shared/auth/reset_kata_sandi/input_email_page.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();
  final AuthService _authService = AuthService();

  String? _emailError;
  String? _passwordError;

  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  // ================= VALIDASI LOKAL (REAL-TIME) =================

  /// Membersihkan error email saat user mulai mengetik
  void _onEmailChanged(String value) {
    if (_emailError != null) {
      setState(() => _emailError = null);
    }
  }

  /// Membersihkan error password saat user mulai mengetik
  void _onPasswordChanged(String value) {
    if (_passwordError != null) {
      setState(() => _passwordError = null);
    }
  }

  /// Validasi format email lokal — cek apakah ada @
  bool _isValidEmailFormat(String email) {
    return email.contains('@');
  }

  // ================= LOGIN =================

  Future<void> _login() async {
    if (_isLoading) return;

    final email = _emailC.text.trim();
    final password = _passwordC.text.trim();

    // ── Step 1: Validasi lokal (kosong / format) ──
    setState(() {
      _emailError = null;
      _passwordError = null;

      if (email.isEmpty) {
        _emailError = 'Email wajib diisi';
      } else if (!_isValidEmailFormat(email)) {
        // ← BARU: Cek email tanpa @ sebelum kirim ke backend
        _emailError = 'Email wajib mengandung tanda @ (contoh: nama@email.com)';
      }

      if (password.isEmpty) {
        _passwordError = 'Kata sandi wajib diisi';
      }
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    try {
      await _authService.login(email: email, password: password);
      final role = AppSession.role ?? Role.users;
      final jabatan = AppSession.jabatan ?? '';

      await _navigateAfterLogin(
        role: role,
        nama: AppSession.nama ?? '',
        email: AppSession.email ?? '',
        jabatan: jabatan,
      );
    } on ApiException catch (e) {
      // ← PERBAIKAN UTAMA: Parse error per field dari backend
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        // Ambil map errors dari response backend
        // Format: {"email": "...", "password": "..."}
        final errors = _parseFieldErrors(e.errors);

        if (errors != null) {
          // Error spesifik per field — tampilkan di bawah field yang bersangkutan
          _emailError = errors['email'];
          _passwordError = errors['password'];
        } else {
          // Error umum (bukan per field) — tampilkan di password sebagai fallback
          _passwordError = e.message.isNotEmpty ? e.message : 'Gagal login';
        }
      });
    } catch (e) {
      // Error tidak terduga (network, timeout, dll)
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _passwordError = 'Terjadi kesalahan. Periksa koneksi internet Anda.';
      });
    }
  }

  // ================= PARSER ERROR BACKEND =================

  /// Mengubah dynamic errors dari ApiException menjadi Map<String, String>
  /// 
  /// Format backend:
  ///   {"email": "Email tidak terdaftar...", "password": "Kata sandi salah..."}
  /// 
  /// Return null jika bukan format map yang valid
  Map<String, String>? _parseFieldErrors(dynamic errors) {
    if (errors == null) return null;

    // Jika sudah Map<String, dynamic>
    if (errors is Map<String, dynamic>) {
      return errors.map((key, value) => MapEntry(key, value?.toString() ?? ''));
    }

    // Jika Map<String, String> langsung
    if (errors is Map<String, String>) {
      return errors;
    }

    return null;
  }

  // ================= NAVIGATE AFTER LOGIN =================

  Future<void> _navigateAfterLogin({
    required Role role,
    required String nama,
    required String email,
    required String jabatan,
  }) async {
    if (!mounted) return;

    Session.nama = nama;
    Session.email = email;
    Session.jabatan = jabatan;
    Session.role = role;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PanduanPage(role: role, nama: nama, email: email, jabatan: jabatan),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFEFF3F7),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF2F2F2),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ================= ICON =================
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F6E7A).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        size: 38,
                        color: Color(0xFF0F6E7A),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ================= TITLE =================
                    const Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F6E7A),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Silakan masuk untuk melanjutkan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),

                    const SizedBox(height: 34),

                    // ================= CARD =================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ================= EMAIL =================
                          const _FieldLabel(text: 'Email'),
                          const SizedBox(height: 10),
                          _buildEmailField(),

                          const SizedBox(height: 22),

                          // ================= PASSWORD =================
                          const _FieldLabel(text: 'Kata Sandi'),
                          const SizedBox(height: 10),
                          _buildPasswordField(),

                          const SizedBox(height: 10),

                          // ================= FORGOT PASSWORD =================
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InputEmailPage(),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Lupa Kata sandi?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.bluePrimary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ================= LOGIN BUTTON =================
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppColors.bluePrimary,
                                disabledBackgroundColor: AppColors.bluePrimary
                                    .withValues(alpha: 0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ================= COPYRIGHT =================
                    const SizedBox(height: 24),

                    Text(
                      '© 2025 SMKN 2 Singosari',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= FIELD BUILDERS =================

  Widget _buildEmailField() {
    return TextField(
      controller: _emailC,
      onChanged: _onEmailChanged,  // ← BARU: Bersihkan error saat ngetik
      cursorColor: AppColors.bluePrimary,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      keyboardType: TextInputType.emailAddress,
      decoration: _fieldDecoration(
        hint: 'Email',
        error: _emailError,  // ← Error email muncul DI BAWAH input email
        prefixIcon: Icons.mail_outline_rounded,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordC,
      obscureText: _obscure,
      onChanged: _onPasswordChanged,  // ← BARU: Bersihkan error saat ngetik
      cursorColor: AppColors.bluePrimary,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      decoration: _fieldDecoration(
        hint: 'Kata sandi',
        error: _passwordError,  // ← Error password muncul DI BAWAH input password
        prefixIcon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey.shade500,
            size: 20,
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    String? error,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    const focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: AppColors.bluePrimary, width: 1.4),
    );

    // ── BARU: Border merah saat ada error ──
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red, width: 1.2),
    );

    return InputDecoration(
      isDense: true,
      hintText: hint,
      errorText: error,  // ← Tampilkan error di bawah field
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: AppColors.hinttext.withValues(alpha: 0.35),
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      enabledBorder: border,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,           // ← Border merah saat error
      focusedErrorBorder: errorBorder,    // ← Border merah saat fokus + error
    );
  }
}

// ================= FIELD LABEL =================

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.hinttext,
      ),
    );
  }
}