import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'panduan_preview_builder.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/features/users/pages/menu_user_page.dart';
import 'package:ta_mobile_disposisi_surat/features/home/home.dart';

import 'panduan_step.dart';
import 'panduan_step_card.dart';

class PanduanPage extends StatefulWidget {
  final Role role;
  final String nama;
  final String email;
  final String jabatan;
  final bool fromProfile;

  const PanduanPage({
    super.key,
    required this.role,
    required this.nama,
    required this.email,
    required this.jabatan,
    this.fromProfile = false,
  });

  @override
  State<PanduanPage> createState() => _PanduanPageState();
}

class _PanduanPageState extends State<PanduanPage> {
  static const Color _primary = Color(0xFF0F6E7A);
  static const Color _bg = Color(0xFFF2F2F2);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<PanduanStepData> _steps;

  @override
  void initState() {
    super.initState();
    _steps = PanduanSteps.forRole(widget.role);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _steps.length - 1;

  String get _roleLabel => switch (widget.role) {
    Role.kepsek => 'Kepala Sekolah',
    Role.tu => 'Tata Usaha',
    Role.users => 'Pengguna',
    Role.wakaKurikulum => 'Waka Kurikulum',
    Role.wakaKesiswaan => 'Waka Kesiswaan',
    Role.wakaHumas => 'Waka Humas',
    Role.wakaSarpras => 'Waka Sarpras',
  };

  void _onContinue() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    // kalau buka dari profile → cukup kembali
    if (widget.fromProfile) {
      Navigator.pop(context);
      return;
    }

    // kalau onboarding pertama login
    final Widget destination =
        widget.role == Role.users ||
            widget.role == Role.wakaKesiswaan ||
            widget.role == Role.wakaKurikulum ||
            widget.role == Role.wakaHumas ||
            widget.role == Role.wakaSarpras
        ? MenuUser(
            nama: widget.nama,
            email: widget.email,
            jabatan: widget.jabatan,
            role: widget.role,
          )
        : Home(
            role: widget.role,
            nama: widget.nama,
            email: widget.email,
            jabatan: widget.jabatan,
          );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _steps.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (context, index) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: SingleChildScrollView(
                            key: ValueKey(index),
                            padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
                            child: Column(
                              children: [
                                PanduanStepCard(
                                  step: _steps[index],
                                  stepNumber: index + 1,
                                  totalSteps: _steps.length,
                                  preview: PanduanPreviewBuilder.build(
                                    context: context,
                                    role: widget.role,
                                    type: _steps[index].previewType,
                                    nama: widget.nama,
                                    email: widget.email,
                                    jabatan: widget.jabatan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildDotIndicator(),
                  _buildBottomActions(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _roleLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _finish,
                child: Text(
                  'Lewati',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const SizedBox(height: 18),
          const Text(
            'Panduan Penggunaan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _primary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pelajari langkah singkat menggunakan aplikasi disposisi surat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length, (i) {
          final isActive = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? _primary : _primary.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(100),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _onContinue,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            _isLastPage ? 'Selesai' : 'Lanjutkan',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
