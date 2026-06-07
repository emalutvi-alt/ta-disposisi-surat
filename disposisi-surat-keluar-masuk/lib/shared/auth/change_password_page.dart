import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import 'package:ta_mobile_disposisi_surat/services/auth_service.dart';
import 'package:ta_mobile_disposisi_surat/shared/auth/reset_kata_sandi/input_email_page.dart';

class GantiKataSandiPage extends StatefulWidget {
  const GantiKataSandiPage({super.key});

  @override
  State<GantiKataSandiPage> createState() => _GantiKataSandiPageState();
}
//controller untuk inputan lama,baru dan konfirmasi password
class _GantiKataSandiPageState extends State<GantiKataSandiPage> {
  final _authService = AuthService();

  final TextEditingController _oldPassC = TextEditingController();
  final TextEditingController _newPassC = TextEditingController();
  final TextEditingController _confirmPassC = TextEditingController();
//untuk menyembunyikan atau menampilkan password
  bool _showOld = false;
  bool _showNew = false;
//menampilkan atau menyembunyikan konfirmasi password
  bool _showConfirm = false;

  // Validasi PASSWORD BARU (lokal, hanya untuk UX — bukan validasi password lama)
  bool _hasNumber = false;
  bool _min8Char = false;
  bool _hasUpperLower = false;
  bool _passwordMatch = false;

  bool _isLoading = false;

  // ── VALIDATION ─────────────────────────────────────
// dipanggil setiap kali user mengetik
  void _onNewChanged(String value) {
    setState(() {
      //validasi password baru angka, 8 karakter, huruf besar kecil
      _hasNumber = RegExp(r'[0-9]').hasMatch(value);
      _min8Char = value.length >= 8;
      _hasUpperLower = RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(value);
    //mengecek apakah password baru sama dengan konfirmasi password
      _passwordMatch = value == _confirmPassC.text;
    });
  }
//dipanggil ketika konfirmasi password berubah dan sinkronisasi password
  void _onConfirmChanged(String value) {
    setState(() {
      _passwordMatch = value == _newPassC.text;
    });
  }

  // ── TOGGLE ─────────────────────────────────────────
//menampilkan atau menyembunyikan password lama, baru, dan konfirmasi password
  void _toggleOld() => setState(() => _showOld = !_showOld);
  void _toggleNew() => setState(() => _showNew = !_showNew);
  void _toggleConfirm() => setState(() => _showConfirm = !_showConfirm);

  // ── BUTTON VALID ───────────────────────────────────
//mengecek apakah semua validasi terpenuhi
  bool get _isValid =>
      _oldPassC.text.isNotEmpty &&
      _hasNumber &&
      _min8Char &&
      _hasUpperLower &&
      _passwordMatch &&
      !_isLoading;

  // ── SUBMIT → API ───────────────────────────────────

  Future<void> _submit() async {
    //validasi terakhir sebelum submit
    if (!_isValid) return;
    //tampilkan loading
    setState(() => _isLoading = true);

    try {
      await _authService.changePassword(
        oldPassword: _oldPassC.text,
        newPassword: _newPassC.text,
        confirmPassword: _confirmPassC.text,  // ← Tambahkan ini
        );

      if (!mounted) return;
      //taampilan dialog sukses
      _showSuccessDialog();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── SUCCESS DIALOG ─────────────────────────────────
  // Hanya muncul jika API berhasil (dipanggil dari _submit setelah await selesai)

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.bluePrimary,
                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Password Berhasil Diubah',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Kata sandi akun kamu berhasil diperbarui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                // ketika ditekan ok akan menutup kembali
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  Navigator.pop(context); // kembali ke profile
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────

  @override
  void dispose() {
    _oldPassC.dispose();
    _newPassC.dispose();
    _confirmPassC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // HEADER
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.bluePrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ganti Kata Sandi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bluePrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keamanan Akun',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Perbarui kata sandi Anda secara berkala untuk menjaga keamanan akun.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CARD
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // PASSWORD LAMA — tidak ada validasi lokal,
                            // backend yang menentukan benar/salah
                            _buildLabel('KATA SANDI LAMA'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _oldPassC,
                              hint: 'Masukkan kata sandi lama',
                              isVisible: _showOld,
                              onChanged: (_) => setState(() {}),
                              onToggle: _toggleOld,
                            ),

                            const SizedBox(height: 20),

                            // PASSWORD BARU
                            _buildLabel('KATA SANDI BARU'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _newPassC,
                              hint: 'Masukkan kata sandi baru',
                              isVisible: _showNew,
                              onChanged: _onNewChanged,
                              onToggle: _toggleNew,
                            ),

                            if (_newPassC.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  children: [
                                    _buildValidationRow(
                                      'Mengandung minimal satu angka',
                                      _hasNumber,
                                    ),
                                    _buildValidationRow(
                                      'Terdiri dari minimal 8 karakter',
                                      _min8Char,
                                    ),
                                    _buildValidationRow(
                                      'Mengandung huruf besar & huruf kecil',
                                      _hasUpperLower,
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 20),

                            // KONFIRMASI PASSWORD
                            _buildLabel('KONFIRMASI KATA SANDI BARU'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _confirmPassC,
                              hint: 'Ulangi kata sandi baru',
                              isVisible: _showConfirm,
                              onChanged: _onConfirmChanged,
                              onToggle: _toggleConfirm,
                            ),

                            if (_confirmPassC.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _buildValidationRow(
                                  _passwordMatch
                                      ? 'Konfirmasi password cocok'
                                      : 'Konfirmasi password tidak cocok',
                                  _passwordMatch,
                                ),
                              ),

                            const SizedBox(height: 8),

                            // LUPA PASSWORD
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const InputEmailPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Lupa kata sandi?',
                                  style: TextStyle(
                                    color: AppColors.bluePrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // BUTTON
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 4),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _isValid
                          ? AppColors.bluePrimary
                          : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isValid ? _submit : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LABEL ──────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.black45,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── FIELD ──────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      enableSuggestions: false,
      autocorrect: false,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.hinttext,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F4F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.bluePrimary,
            width: 1.4,
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ── VALIDATION ROW ─────────────────────────────────

  Widget _buildValidationRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error_outline,
            color: isValid ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: isValid ? Colors.green : Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
