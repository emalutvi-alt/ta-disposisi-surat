import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';

import 'package:ta_mobile_disposisi_surat/core/helpers/navigation_helper.dart';

import 'package:ta_mobile_disposisi_surat/shared/widgets/custom_navbar.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/api_ui_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/data_loader.dart';
import 'package:ta_mobile_disposisi_surat/features/notifications/notification_page.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/process_dialog.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/surat_card.dart';

import 'package:ta_mobile_disposisi_surat/features/kepsek/input_surat_masuk.dart';
import 'package:ta_mobile_disposisi_surat/features/kepsek/pages/menu_kepsek_page.dart';
import 'package:ta_mobile_disposisi_surat/features/kepsek/pages/pengajuan_suratkeluar.dart';

import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/hasil_disposisi_surat_masuk_page.dart';
import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/hasil_pengajuan_surat_keluar_page.dart';
import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/menu_tu.dart';

class Home extends StatefulWidget {
  final Role role;
  final String nama;
  final String email;
  final String jabatan;
  final List<Map<String, dynamic>>? suratOverride;

  const Home({
    super.key,
    required this.role,
    required this.nama,
    required this.email,
    required this.jabatan,
    this.suratOverride,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> _allSurat = [];
  bool _loading = true;
  String? _error;
  int _unreadNotif = 0;
  //memuat seluruh data surat dan notifikasi
  //saat halaman pertamakali dibuka
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  //mengkatifkan indikator loading
  //dan pesan error sebelumnya
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      //mengambil seluruh data surat
      //dari sumber data aplikasi
      final surat = await DataLoader.loadAllSurat();
      //mengambil data notifikasi pengguna
      final notif = await DataLoader.loadNotifications();
      if (!mounted) return;
      setState(() {
        //menyimpan data surat ke state
        _allSurat = surat;
        notifications = notif.items;
        //menyimpan jumlah notifikasi yang belum dibaca
        _unreadNotif = notif.unread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
//menentukan jumlah badge notifikasi
// yang akan ditampilkan pada icon lonceng
  int get notifCount => _unreadNotif > 0
      ? _unreadNotif
      : notifications.where((e) => e['isRead'] == false).length;

  List<Map<String, dynamic>> get suratTerbaru =>
  //membalik urutan data agar surat terbaruberada di atas
  //lalu mengambil 5 data teratas
      _allSurat.reversed.take(5).toList();

  int get jumlahSuratMasuk =>
      _allSurat.where((e) => e['jenisSurat'] == 'Surat Masuk').length;

  int get jumlahSuratKeluar =>
      _allSurat.where((e) => e['jenisSurat'] == 'Surat Keluar').length;

  // =========================
  // RESPONSIVE
  // =========================

  double rf(
    BuildContext context,
    double size, {
    double min = 0.85,
    double max = 1.10, // ← diturunin dari 1.20
  }) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375).clamp(min, max);
    return size * scale;
  }

  // =========================
  // NOTIFICATION PAGE
  // =========================

  Future<void> openNotification() async {
    //berpindah ke halaman notifiksi
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NotificationPage(role: widget.role, notifications: notifications),
      ),
    );
    await _loadData();
  }

  // =========================
  // NAVIGATION
  // =========================
//jika pengguna adalah TU,maka arahkan ke dashboard TU
  void openDashboard(String jenisSurat) {
    if (widget.role == Role.tu) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TuDashboardPage(jenisSurat: jenisSurat),
        ),
      );
    } else if (widget.role == Role.kepsek) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KepsekDashboardPage(jenisSurat: jenisSurat),
        ),
      );
    }
  }
//mengecek jenis surat apakah surat masuk apakah surat keluar
  void openDetail(Map<String, dynamic> surat) async {
    final isMasuk = surat['jenisSurat'] == 'Surat Masuk';
//kepala sekolah memberikan disposisi sehingga diarahkan input
    if (widget.role == Role.kepsek) {
      final refreshed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => isMasuk
              ? InputSuratMasuk(surat: surat)
              : InputSuratKeluar(surat: surat),
        ),
      );
      if (refreshed == true) {
        _loadData();
      }
      return;
    }

    final status = surat['status']?.toString().toLowerCase() ?? '';

    if (status == 'diproses') {
      showProcessDialog(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isMasuk
            ? OutputSuratmasuk(
                isApproved: status == 'disetujui',
                catatan: surat['catatan'] ?? '',
                tujuan: surat['tujuan'] ?? '',
                instruksi: surat['instruksi'] ?? '',
                koordinasi: surat['koordinasi'] ?? '',
                diteruskanKe: surat['diteruskanKe'] ?? '',
                lampiranUrls: List<String>.from(surat['lampiran'] ?? []),
              )
            : OutputSuratkeluar(
                catatan: surat['catatan'] ?? '-',
                isReadOnly: false,
                lampiranUrls: List<String>.from(surat['lampiran'] ?? []),
              ),
      ),
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    //mengambil area aman perangkat agartidak tertutup sisitem android
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomNavbar(
            role: widget.role,
            currentIndex: 0,
            onTap: (index) {
              handleNavbarTap(
                context,
                index,
                widget.role,
                widget.nama,
                widget.email,
                widget.jabatan,
              );
            },
          ),
          SizedBox(height: bottomPadding),
        ],
      ),

      body: SafeArea(
        child: _loading
        //menampilkan loading ketika proses
            ? buildLoading()
            : _error != null
            ? buildError(_error!, _loadData)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================
                  // HEADER — FIXED (tidak ikut scroll)
                  // =========================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: rf(context, 20)),

                        // Logo + Notifikasi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              "assets/images/logosmk.jpg",
                              width: rf(context, 42),
                              height: rf(context, 42),
                            ),
                            // area yang dapat ditekan untuk membuka halaman notifikasi
                            GestureDetector(
                              onTap: openNotification,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  right: 4,
                                ), // ← kompensasi overflow badge
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: rf(context, 28),
                                      color: AppColors.bluePrimary,
                                    ),
                                    //badge yang muncul jika ada yang belum dibaca
                                    if (notifCount > 0)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE53935),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              notifCount > 9
                                                  ? '9+'
                                                  : notifCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: rf(context, 18)),

                        // Judul
                        Text(
                          "Disposisi Surat",
                          style: TextStyle(
                            fontSize: rf(context, 22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: rf(context, 22)),

                        // Stat Cards
                        Row(
                          children: [
                            Expanded(
                              //card untuk menghitung surat masuk
                              child: _StatCard(
                                onTap: () => openDashboard('Surat Masuk'),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6DA8B4),
                                    Color(0xFF0F6E7A),
                                  ],
                                ),
                                iconPath: "assets/icons/ic_inmail.svg",
                                jumlah: jumlahSuratMasuk.toString(),
                                label: "Masuk",
                              ),
                            ),
                            SizedBox(width: rf(context, 14)),
                            Expanded(
                              child: _StatCard(
                                onTap: () => openDashboard('Surat Keluar'),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD6A66B),
                                    Color(0xFFDA7B17),
                                  ],
                                ),
                                iconPath: "assets/icons/ic_outmail.svg",
                                jumlah: jumlahSuratKeluar.toString(),
                                label: "Keluar",
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: rf(context, 26)),

                        // Label section
                        Text(
                          "Surat Terbaru",
                          style: TextStyle(
                            fontSize: rf(context, 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: rf(context, 14)),
                      ],
                    ),
                  ),

                  // =========================
                  // LIST — SCROLLABLE
                  // =========================
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      //mennampilan data surat terbaru berdasarkan jumlah data
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: suratTerbaru.length,
                        itemBuilder: (context, index) {
                          final surat = suratTerbaru[index];
                          //menampilkan satu item surat terbaru pada daftar surat
                          return SuratCard(
                            jenisSurat: surat['jenisSurat'] ?? '',
                            tanggal: surat['tanggal'] ?? '-',
                            data: Map<String, String>.from(surat['data'] ?? {}),
                            role: widget.role == Role.kepsek
                                ? CardRole.kepsek
                                : CardRole.tu,
                            type: CardType.home,
                            status: widget.role == Role.kepsek
                                ? null
                                : surat['status'],
                            onDetail: () => openDetail(surat),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: rf(context, 20)),
                ],
              ),
      ),
    );
  }
}

// ======================================
// STAT CARD
// ======================================

class _StatCard extends StatelessWidget {
  final VoidCallback onTap;
  final LinearGradient gradient;
  final String iconPath;
  final String jumlah;
  final String label;

  const _StatCard({
    required this.onTap,
    required this.gradient,
    required this.iconPath,
    required this.jumlah,
    required this.label,
  });

  double rf(
    BuildContext context,
    double size, {
    double min = 0.85,
    double max = 1.10,
  }) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375).clamp(min, max);
    return size * scale;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: rf(context, 72)),

        padding: EdgeInsets.symmetric(
          horizontal: rf(context, 12),
          vertical: rf(context, 10),
        ),

        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(rf(context, 16)),
        ),

        child: Row(
          children: [
            CircleAvatar(
              radius: rf(context, 17),
              backgroundColor: Colors.white.withValues(alpha: 0.25),
//menampilkan icon SVG sesuai jenis surat
              child: SvgPicture.asset(
                iconPath,
                width: rf(context, 18),
                height: rf(context, 18),

                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),

            SizedBox(width: rf(context, 9)),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,

                    child: Text(
                      jumlah,
                      style: TextStyle(
                        fontSize: rf(context, 17),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),

                  SizedBox(height: rf(context, 2)),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,

                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: rf(context, 12),
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
