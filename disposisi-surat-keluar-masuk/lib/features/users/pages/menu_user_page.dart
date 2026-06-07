import 'package:flutter/material.dart';

import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/helpers/navigation_helper.dart';

import 'package:ta_mobile_disposisi_surat/features/users/pages/detail_surat_users_unified.dart';

import 'package:ta_mobile_disposisi_surat/shared/widgets/custom_navbar.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/api_ui_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/data_loader.dart';
import 'package:ta_mobile_disposisi_surat/features/notifications/notification_page.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/search_bar.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/surat_card.dart';
//menampilkan daftar surat yang diterima, notifikasi serta fitur pencarian
class MenuUser extends StatefulWidget {
  final String nama;
  final String email;
  final String jabatan;
  final Role role;

  const MenuUser({
    super.key,
    required this.nama,
    required this.email,
    required this.jabatan,
    required this.role,
  });

  @override
  State<MenuUser> createState() => _MenuUserState();
}

class _MenuUserState extends State<MenuUser> {
  /// Menyimpan kata kunci pencarian surat.
  String searchQuery = '';
  //menyimpan seluruh data notifikasi dan daftar surat
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> _inbox = [];
  bool _loading = true;
  String? _error;
  //menyimpan jumlah notif yang belum dibaca
  int _unreadNotif = 0;
//memuat data surat dan notifikasi saat halaman dibuka
  @override
  void initState() {
    super.initState();
    _loadData();
  }
//mengambil data diposisi dan notif pengguna
//mengatifkan indikator loading dan eror jika terajdi kesalahan
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      //mengambil data surat dan notifikasi
      final inbox = await DataLoader.loadDisposisiInbox(
        search: searchQuery.isEmpty ? null : searchQuery,
      );
      final notif = await DataLoader.loadNotifications();
      if (!mounted) return;
      setState(() {
        //menyimpan data surat yang berhasil diperoleh dan menyimpan data notifikasi
        _inbox = inbox;
        notifications = notif.items;
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
//menghitung jumlah notifikasi yang belum dibaca
  int get notifCount =>
      _unreadNotif > 0
          ? _unreadNotif
          : notifications.where((n) => n['isRead'] == false).length;

  /// Membuka halaman notifikasi lalu menandai semua notifikasi sebagai dibaca.
  Future<void> _openNotification() async {
    //berpindah ke halaaman notifikasi
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NotificationPage(role: widget.role, notifications: notifications),
      ),
    );
    await _loadData();
  }
  List<Map<String, dynamic>> get suratMasukList => _inbox;

  /// Memfilter surat berdasarkan kata kunci pencarian pada field utama.
  List<Map<String, dynamic>> get filteredSurat {
    if (searchQuery.isEmpty) {
      return suratMasukList;
    }

    return suratMasukList.where((surat) {
      final query = searchQuery.toLowerCase();
    //digunakanuntuk mengmbil data dari surat yang difilter
      final jenis = surat["jenisSurat"].toString().toLowerCase();

      final tanggal = surat["tanggal"].toString().toLowerCase();

      final status = surat["status"].toString().toLowerCase();

      final dari = (surat["data"]?["Dari"] ?? '').toString().toLowerCase();

      final perihal = (surat["data"]?["Perihal"] ?? '')
          .toString()
          .toLowerCase();
      //surat akan ditampilkanjika mengandung kata kunci
      return jenis.contains(query) ||
          tanggal.contains(query) ||
          status.contains(query) ||
          dari.contains(query) ||
          perihal.contains(query);
    }).toList();
  }
//mengambil ukuran layar untuk responsive
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final w = size.width;
    final h = size.height;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    double rf(double size) {
      return (w * (size / 375)).clamp(size * 0.85, size * 1.2);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,

      /// Navigasi bawah untuk perpindahan antar halaman utama user.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            //berpindah ke halaman lain
            child: CustomNavbar(
              role: widget.role,
              currentIndex: 0,
              onTap: (index) {
                //menentukan halaman yang akan dituju
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
          ),

          ColoredBox(
            color: AppColors.bg,
            child: SizedBox(height: bottomPadding, width: double.infinity),
          ),
        ],
      ),

      /// Konten utama halaman menu disposisi user.
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.03),

                  /// Header berisi logo dan akses cepat notifikasi.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        "assets/images/logosmk.jpg",
                        width: w * 0.1,
                        height: w * 0.1,
                        fit: BoxFit.cover,
                      ),
                     //membuka halaman notifikasi saat ikon ditekan
                      GestureDetector(
                        onTap: _openNotification,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: w * 0.075,
                              color: AppColors.bluePrimary,
                            ),

                            /// Badge jumlah notifikasi belum dibaca.
                            if (notifCount > 0)
                              Positioned(
                                right: -(w * 0.008),
                                top: -(w * 0.008),
                                child: Container(
                                  padding: EdgeInsets.all(w * 0.008),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: w * 0.045,
                                    minHeight: w * 0.045,
                                  ),
                                  child: Center(
                                    child: Text(
                                      notifCount > 9
                                          ? '9+'
                                          : notifCount.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: rf(9),
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
                    ],
                  ),

                  SizedBox(height: h * 0.02),

                  /// Judul halaman disposisi surat.
                  Text(
                    "Disposisi Surat",
                    style: TextStyle(
                      fontSize: rf(22),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: h * 0.025),

                  /// Kolom pencarian surat disposisi.
                  SearchBarInput(
                    hintText: 'Cari surat...',
              onChanged: (value) {
                //memeperbarui kata kunci pencarian dan memuat ulang
                setState(() => searchQuery = value);
                _loadData();
              },
                  ),

                  SizedBox(height: h * 0.012),

                  /// Daftar surat hasil filter pencarian.
                  Expanded(
                    child: _loading
                        ? buildLoading()
                        : _error != null
                            ? buildError(_error!, _loadData)
                            : filteredSurat.isEmpty
                                ? buildEmpty('Belum ada disposisi')
                                : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(bottom: h * 0.015),
                      itemCount: filteredSurat.length,
                      itemBuilder: (context, index) {
                        //mengambil satu data surat yang difilter
                        final surat = filteredSurat[index];

                        return Padding(
                          padding: EdgeInsets.only(bottom: h * 0.002),
                          child: SuratCard(
                            jenisSurat: surat["jenisSurat"].toString(),

                            tanggal: surat["tanggal"].toString(),

                            status: surat["status"]?.toString(),

                            role: CardRole.users,

                            type: CardType.menu,

                            data: Map<String, String>.from(surat["data"]),

                            diteruskanKe: surat["diteruskanKe"]?.toString(),

                            lampiran: List<String>.from(surat['lampiran'] ?? []),
                          //membuka  halaman detail surat
                            onDetail: () async {
                              final refreshed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailSuratUsers(surat: surat),
                                ),
                              );
                              //memuat ulang data apabila ada perubahan status pada halaman
                              if (refreshed == true) _loadData();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
