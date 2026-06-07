import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import 'package:ta_mobile_disposisi_surat/services/auth_service.dart';
import 'package:ta_mobile_disposisi_surat/shared/auth/pages/login_page.dart';

// Halaman untuk membuat password baru setelah reset password
class NewPasswordPage extends StatefulWidget {
  final String email;
  final String resetToken;

  const NewPasswordPage({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  // Controller untuk input dan konfirmasi password
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Mengatur apakah password ditampilkan atau disembunyikan
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  // Validasi password
  bool hasNumber = false;
  bool min8Char = false;
  bool hasUpperLower = false;
  bool passwordMatch = false;

  // ── TOGGLE VISIBILITY ──────────────────────────────────────────────────────
  // FIX: Gunakan obscureText bawaan Flutter — tidak perlu sync manual
  void _toggleShowPassword() {
    setState(() => _showPassword = !_showPassword);
  }

  void _toggleShowConfirm() {
    setState(() => _showConfirm = !_showConfirm);
  }

  // ── VALIDATION ─────────────────────────────────────────────────────────────
  bool get isValid => hasNumber && min8Char && hasUpperLower && passwordMatch;

  void _savePassword() async {
    if (!_formKey.currentState!.validate() || !isValid) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().resetPassword(
        email: widget.email,
        resetToken: widget.resetToken,
        newPassword: _passwordController.text,
        confirmPassword: _confirmController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final sw = MediaQuery.of(context).size.width;
      final sh = MediaQuery.of(context).size.height;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: EdgeInsets.all(sw * 0.06),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: sw * 0.16,
                  height: sw * 0.16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(sw * 0.08),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.bluePrimary,
                    size: sw * 0.09,
                  ),
                ),
                SizedBox(height: sh * 0.020),
                Text(
                  'Password Berhasil Diubah!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: sw * 0.042,
                  ),
                ),
                SizedBox(height: sh * 0.010),
                Text(
                  'Silakan login menggunakan password baru kamu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: sw * 0.033,
                    color: Colors.black45,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: sh * 0.025),
                SizedBox(
                  width: double.infinity,
                  height: sh * 0.055,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                        (route) => false,
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        AppColors.bluePrimary,
                      ),
                      foregroundColor:
                          const WidgetStatePropertyAll(Colors.white),
                      elevation: const WidgetStatePropertyAll(0),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(sw * 0.025),
                        ),
                      ),
                    ),
                    child: Text(
                      'Ke Halaman Login',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: (sw * 0.042).clamp(15.0, 18.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: \$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    required double sw,
    required double sh,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.hinttext, fontSize: sw * 0.036),
      prefixIcon: Icon(prefixIcon, size: sw * 0.05, color: Colors.black38),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: EdgeInsets.symmetric(
        vertical: sh * 0.017,
        horizontal: sw * 0.04,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(sw * 0.03),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(sw * 0.03),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(sw * 0.03),
        borderSide: BorderSide(color: AppColors.bluePrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(sw * 0.03),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sw = size.width;
    final sh = size.height;

    final hPad = sw * 0.06;
    final iconSize = sw * 0.14;
    final iconRadius = sw * 0.04;
    final titleSize = (sw * 0.075).clamp(28.0, 34.0);
    final bodySize = (sw * 0.042).clamp(15.0, 18.0);
    final labelSize = (sw * 0.038).clamp(14.0, 16.0);
    final btnHeight = sh * 0.065;
    final spacingXL = sh * 0.035;
    final spacingL = sh * 0.022;
    final spacingM = sh * 0.016;
    final spacingS = sh * 0.008;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: sw * 0.055,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: hPad,
              right: hPad,
              top: spacingS,
              bottom: spacingM,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: spacingL),

                  // ── Icon ─────────────────────────────
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(iconRadius),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.bluePrimary,
                      size: iconSize * 0.5,
                    ),
                  ),

                  SizedBox(height: spacingL),

                  // ── Title ────────────────────────────
                  Text(
                    'Password Baru',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: spacingS),
                  Text(
                    'Buat password baru untuk akunmu. Pastikan mudah diingat tapi sulit ditebak.',
                    style: TextStyle(
                      fontSize: bodySize,
                      color: Colors.black45,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: spacingL),

                  // ── Password ─────────────────────────
                  // FIX: Gunakan obscureText bawaan Flutter, tidak perlu _passwordReal manual
                  Text(
                    'Password Baru',
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: spacingS),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,      // ← Standard Flutter
                    onChanged: (val) {
                      setState(() {
                        hasNumber = RegExp(r'[0-9]').hasMatch(val);
                        min8Char = val.length >= 8;
                        hasUpperLower =
                            RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(val);
                        passwordMatch = val == _confirmController.text;
                      });
                    },
                    style: TextStyle(fontSize: bodySize),
                    decoration: _inputDecoration(
                      hint: 'Minimal 8 karakter',
                      prefixIcon: Icons.lock_outline,
                      sw: sw,
                      sh: sh,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: sw * 0.055,
                          color: Colors.black38,
                        ),
                        onPressed: _toggleShowPassword,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),

                  if (_passwordController.text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: spacingM),
                      child: Column(
                        children: [
                          _buildValidation(
                            'Mengandung minimal satu angka',
                            hasNumber,
                            sw,
                          ),
                          _buildValidation(
                            'Minimal 8 karakter',
                            min8Char,
                            sw,
                          ),
                          _buildValidation(
                            'Huruf besar & kecil',
                            hasUpperLower,
                            sw,
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: spacingM),

                  // ── Confirm Password ─────────────────
                  Text(
                    'Konfirmasi Password',
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: spacingS),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: !_showConfirm,       // ← Standard Flutter
                    onChanged: (val) {
                      setState(() {
                        passwordMatch = _passwordController.text == val;
                      });
                    },
                    style: TextStyle(fontSize: bodySize),
                    decoration: _inputDecoration(
                      hint: 'Ulangi password baru',
                      prefixIcon: Icons.lock_outline,
                      sw: sw,
                      sh: sh,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: sw * 0.055,
                          color: Colors.black38,
                        ),
                        onPressed: _toggleShowConfirm,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      return null;
                    },
                  ),

                  if (_confirmController.text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: spacingM),
                      child: _buildValidation(
                        passwordMatch
                            ? 'Konfirmasi password cocok'
                            : 'Konfirmasi password tidak cocok',
                        passwordMatch,
                        sw,
                      ),
                    ),

                  SizedBox(height: spacingXL),

                  // ── Button ───────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: btnHeight,
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading || !isValid) ? null : _savePassword,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.disabled)
                              ? AppColors.bluePrimary.withValues(alpha: 0.5)
                              : AppColors.bluePrimary,
                        ),
                        foregroundColor:
                            const WidgetStatePropertyAll(Colors.white),
                        elevation: const WidgetStatePropertyAll(0),
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw * 0.03),
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: sw * 0.05,
                              height: sw * 0.05,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Simpan Password',
                              style: TextStyle(
                                fontSize: (sw * 0.045).clamp(16.0, 18.0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: spacingM),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidation(String text, bool isValid, double sw) {
    return Padding(
      padding: EdgeInsets.only(bottom: sw * 0.015),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error_outline,
            color: isValid ? Colors.green : Colors.red,
            size: sw * 0.05,
          ),
          SizedBox(width: sw * 0.015),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: (sw * 0.036).clamp(13.0, 15.0),
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}