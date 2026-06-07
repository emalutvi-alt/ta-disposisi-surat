import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/session.dart';
import 'package:ta_mobile_disposisi_surat/core/helpers/navigation_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import 'package:ta_mobile_disposisi_surat/core/storage/app_session.dart';
import 'package:ta_mobile_disposisi_surat/services/auth_service.dart';
import 'package:ta_mobile_disposisi_surat/shared/auth/change_password_page.dart';
import 'package:ta_mobile_disposisi_surat/shared/auth/pages/login_page.dart';
import 'package:ta_mobile_disposisi_surat/shared/auth/panduan/panduan_page.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/custom_navbar.dart';

class ProfilePage extends StatefulWidget {
  final Role role;

  const ProfilePage({
    super.key,
    required this.role,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _errorMessage;

  String _nama = '';
  String _email = '';
  String _jabatan = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Tampilkan data AppSession dulu supaya tidak blank saat loading
    setState(() {
      _nama = AppSession.nama ?? '';
      _email = AppSession.email ?? '';
      _jabatan = AppSession.jabatan ?? '';
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _authService.fetchProfile();

      // Simpan ke AppSession supaya data terkini tersedia di seluruh app
      await AppSession.save(
        tokenValue: AppSession.token ?? '',
        roleValue: profile['role']?.toString() ?? '',
        userIdValue: profile['id'] is num ? (profile['id'] as num).toInt() : 0,
        emailValue: profile['email']?.toString() ?? '',
        namaValue: profile['nama']?.toString() ?? '',
        jabatanValue: profile['jabatan']?.toString() ?? '',
      );

      if (!mounted) return;
      setState(() {
        _nama = profile['nama']?.toString() ?? '';
        _email = profile['email']?.toString() ?? '';
        _jabatan = profile['jabatan']?.toString() ?? '';
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Data AppSession tetap ditampilkan meski fetch gagal
      });
    }
  }

  bool get _canChangePassword {
    return Session.role != Role.kepsek &&
        Session.role != Role.tu &&
        !Session.isWaka;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    double rf(double size) {
      return (w * (size / 375)).clamp(size * 0.80, size * 1.30);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomNavbar(
            currentIndex: 2,
            role: widget.role,
            onTap: (index) {
              handleNavbarTap(
                context, index, widget.role, _nama, _email, _jabatan,
              );
            },
          ),
          ColoredBox(
            color: AppColors.bg,
            child: SizedBox(height: bottomPadding, width: double.infinity),
          ),
        ],
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: rf(20)),
              child: Column(
                children: [
                  SizedBox(height: rf(20)),

                  // ── TITLE + REFRESH ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          color: AppColors.bluePrimary,
                          fontSize: rf(24),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_isLoading) ...[
                        SizedBox(width: rf(10)),
                        SizedBox(
                          width: rf(16),
                          height: rf(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bluePrimary,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (_errorMessage != null) ...[
                    SizedBox(height: rf(8)),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: rf(12),
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],

                  SizedBox(height: rf(24)),

                  // ── AVATAR ──────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(rf(4)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: rf(44),
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        size: rf(46),
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),

                  SizedBox(height: rf(28)),

                  // ── INFO CARD ────────────────────────────────────────
                  _cardWrapper(
                    rf: rf,
                    child: Column(
                      children: [
                        _profileTile(
                          context,
                          icon: Icons.work_outline,
                          label: 'JABATAN',
                          value: _jabatan.isNotEmpty ? _jabatan : '—',
                          rf: rf,
                        ),
                        SizedBox(height: rf(12)),
                        _profileTile(
                          context,
                          icon: Icons.person_outline,
                          label: 'NAMA',
                          value: _nama.isNotEmpty ? _nama : '—',
                          rf: rf,
                        ),
                        SizedBox(height: rf(12)),
                        _profileTile(
                          context,
                          icon: Icons.email_outlined,
                          label: 'EMAIL',
                          value: _email.isNotEmpty ? _email : '—',
                          rf: rf,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: rf(20)),

                  // ── KEAMANAN CARD ────────────────────────────────────
                  if (_canChangePassword) ...[
                    _cardWrapper(
                      rf: rf,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keamanan',
                            style: TextStyle(
                              fontSize: rf(15),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: rf(16)),
                          InkWell(
                            borderRadius: BorderRadius.circular(rf(14)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GantiKataSandiPage(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(rf(10)),
                                  decoration: BoxDecoration(
                                    color: AppColors.bluePrimary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(rf(12)),
                                  ),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: AppColors.bluePrimary,
                                    size: rf(22),
                                  ),
                                ),
                                SizedBox(width: rf(14)),
                                Expanded(
                                  child: Text(
                                    'Ubah Kata Sandi',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: rf(15),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: rf(26),
                                  color: Colors.grey.shade500,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: rf(20)),
                  ],

                  // ── BANTUAN CARD ─────────────────────────────────────
                  _cardWrapper(
                    rf: rf,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bantuan',
                          style: TextStyle(
                            fontSize: rf(15),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: rf(16)),
                        InkWell(
                          borderRadius: BorderRadius.circular(rf(14)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PanduanPage(
                                  role: widget.role,
                                  nama: _nama,
                                  email: _email,
                                  jabatan: _jabatan,
                                  fromProfile: true,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(rf(10)),
                                decoration: BoxDecoration(
                                  color: AppColors.bluePrimary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(rf(12)),
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: AppColors.bluePrimary,
                                  size: rf(22),
                                ),
                              ),
                              SizedBox(width: rf(14)),
                              Expanded(
                                child: Text(
                                  'Panduan Aplikasi',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: rf(15),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: rf(26),
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: rf(20)),

                  // ── LOGOUT BUTTON ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: rf(50),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade400, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(rf(16)),
                        ),
                      ),
                      onPressed: () => _showLogoutDialog(context, rf),
                      child: Text(
                        'Keluar',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: rf(15),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: rf(20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, double Function(double) rf) {
    final w = MediaQuery.of(context).size.width;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: w * 0.82,
              constraints: const BoxConstraints(maxWidth: 340),
              padding: EdgeInsets.all(rf(24)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(rf(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: rf(54),
                    height: rf(54),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: const Color(0xFFE24B4A),
                      size: rf(25),
                    ),
                  ),
                  SizedBox(height: rf(16)),
                  Text(
                    'Keluar dari akun?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: rf(18),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: rf(8)),
                  Text(
                    'Anda yakin ingin keluar?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: rf(13),
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: rf(20)),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: rf(42),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(rf(11)),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: rf(13),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: rf(10)),
                      Expanded(
                        child: SizedBox(
                          height: rf(42),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE24B4A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(rf(11)),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              await AuthService().logout();
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Login(),
                                ),
                                (route) => false,
                              );
                            },
                            child: Text(
                              'Keluar',
                              style: TextStyle(
                                fontSize: rf(13),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _cardWrapper({required Widget child, required double Function(double) rf}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(rf(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rf(18)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _profileTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required double Function(double) rf,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: rf(14), vertical: rf(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(rf(14)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(rf(9)),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEFF3),
              borderRadius: BorderRadius.circular(rf(10)),
            ),
            child: Icon(icon, size: rf(18), color: AppColors.bluePrimary),
          ),
          SizedBox(width: rf(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: rf(10),
                    letterSpacing: 1,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: rf(3)),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: rf(14),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}