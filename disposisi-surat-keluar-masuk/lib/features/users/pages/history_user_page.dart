import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/surat_card.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/custom_navbar.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/search_bar.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/helpers/navigation_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/filter_date.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/api_ui_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/data_loader.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/full-images-viewer.dart';

//halaman riwayat surat yang disetujui, fitur pencarian
//filter tanggal dan melihat lampiran surat
class HistoryUsersPage extends StatefulWidget {
  final Role role;
  final String nama;
  final String email;
  final String jabatan;

  const HistoryUsersPage({
    super.key,
    required this.role,
    required this.nama,
    required this.email,
    required this.jabatan,
  });

  @override
  State<HistoryUsersPage> createState() => _HistoryUsersPageState();
}

class _HistoryUsersPageState extends State<HistoryUsersPage> {
  /// Menyimpan kata kunci pencarian riwayat surat.
  String _searchQuery = '';

  //menyimpan seluruh data dari surat hasil data
  List<Map<String, dynamic>> _allSurat = [];
  bool _loading = true;
  String? _error;

  /// Label filter tanggal yang tampil di UI.
  String _dateFilter = 'Hari ini';

  /// Menyimpan chip filter tanggal yang sedang aktif.
  String _activeChip = 'Hari ini';

  /// Menyimpan tanggal awal rentang filter.
  DateTime? _startDate;

  /// Menyimpan tanggal akhir rentang filter.
  DateTime? _endDate;

  //inisialisasi halaman, filter surat, dan data riwayat
  @override
  void initState() {
    super.initState();
    //mengambil tanggal dan waktu saat ini
    final now = DateTime.now();
    //menetapkan awal hari, sebagai awal filter
    _startDate = DateTime(now.year, now.month, now.day);
    //menetapkan akhir hari, sebagai akhir filter
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadHistory();
  }

  /// Mengambil riwayat surat masuk sebagai sumber data halaman.
  List<Map<String, dynamic>> get _historySurat => _allSurat;

  //menampilkan data surat yang telah disetujui
  Future<void> _loadHistory() async {
    //mengaktifkan indikator loading dan menghapus error sebelumnya
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      //mengambil data surat yang statusnya disetujui dari data loader
      final list = await DataLoader.loadDisposisiInbox(
        verificationStatus: 'disetujui',
      );
      //memastikan widget masih terpasang sebelum memperbarui state
      if (!mounted) return;
      setState(() {
        _allSurat = list;
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

  /// Menggabungkan filter pencarian teks dan rentang tanggal.
  List<Map<String, dynamic>> get _filteredSurat {
    return _historySurat.where((s) {
      //mengubah kata pencarian jadi huruf kecil
      final query = _searchQuery.toLowerCase();
      final jenis = s['jenisSurat'].toString().toLowerCase();
      final tanggal = s['tanggal'].toString().toLowerCase();
      final dari = s['data']['Dari'].toString().toLowerCase();
      final perihal = s['data']['Perihal'].toString().toLowerCase();

      //mengecek apakah data surat sudah sesuai dengan pencarian
      final matchSearch =
          _searchQuery.isEmpty ||
          jenis.contains(query) ||
          tanggal.contains(query) ||
          dari.contains(query) ||
          perihal.contains(query);

      //nilai awal filter tanggal, akan berubah jika rentang tanggal diubah
      bool matchDate = true;
      final tanggalObj = s['tanggal_obj'];
      DateTime? suratDate;
      //mengecek format data tanggal dari sumber data
      if (tanggalObj is DateTime) {
        suratDate = tanggalObj;
      } else if (tanggalObj != null) {
        suratDate = DateTime.tryParse(tanggalObj.toString());
      }

      if (suratDate != null && _startDate != null && _endDate != null) {
        //membuat batas awal tanggal filter
        final start = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        final end = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        //memastikan surat berada pada rentang tanggal yang dipilih
        matchDate =
            suratDate.isAfter(start.subtract(const Duration(days: 1))) &&
            suratDate.isBefore(end.add(const Duration(seconds: 1)));
      }

      //menampilkan surat yang sesuai dengan pencarian filter
      return matchSearch && matchDate; // FIX #1: return tidak boleh di dalam komentar
    }).toList();
  }

  /// Menampilkan pemilih rentang tanggal lalu menerapkan hasilnya.
  void _showDateFilter() async {
    final result = await DateRangeFilterBottomSheet.show(
      context: context,
      initialStartDate: _startDate,
      initialEndDate: _endDate,
      initialChip: _activeChip,
    );

    //keluar jika pengguna membatalkan pemilihan tanggal
    if (result == null) return; // FIX #2: null check tidak boleh di dalam komentar

    setState(() {
      _startDate = result.startDate;
      _endDate = result.endDate;
      _activeChip = result.activeChip;
      _dateFilter = result.dateFilterLabel;
    });
  }

  /// Membuka lampiran surat; menampilkan notifikasi jika lampiran kosong.
  void _openLampiran(BuildContext context, Map<String, dynamic> surat) {
    final List<String> lampiran = List<String>.from(surat['lampiran'] ?? []);

    if (lampiran.isEmpty) {
      //menampilkan snackbar jika tidak ada lampiran
      ScaffoldMessenger.of(context).showSnackBar( // FIX #3: pemanggilan tidak boleh di dalam komentar
        SnackBar(
          content: const Text("Tidak ada lampiran"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    //untuk melihat lampiran surat
    Navigator.push( // FIX #4: Navigator.push tidak boleh di dalam komentar
      context,
      MaterialPageRoute(
        builder: (_) =>
            FullScreenImageViewer(imageUrls: lampiran, initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //mengambil ukuran layar
    final size = MediaQuery.of(context).size; // FIX #5: deklarasi tidak boleh di dalam komentar

    //responsive font
    final w = size.width; // FIX #6: deklarasi tidak boleh di dalam komentar
    final h = size.height;

    double rf(double size) {
      return (w * (size / 375)).clamp(size * 0.9, size * 1.15);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),

          child: Column(
            children: [
              SizedBox(height: h * 0.025),

              // Judul halaman riwayat surat.
              Text(
                "Riwayat",
                style: TextStyle(
                  fontSize: rf(22),
                  fontWeight: FontWeight.bold,
                  color: AppColors.bluePrimary,
                ),
              ),

              SizedBox(height: h * 0.025),

              // Input pencarian riwayat surat.
              SearchBarInput( // FIX #7: SearchBarInput tidak boleh di dalam komentar
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    //memperbarui kata kunci pencarian
                  }); // FIX #8: penutup setState tidak boleh di dalam komentar
                },
              ),

              SizedBox(height: h * 0.016),

              // Pemilih rentang tanggal riwayat surat.
              GestureDetector(
                onTap: _showDateFilter,

                child: Container(
                  width: double.infinity,

                  padding: EdgeInsets.symmetric(
                    horizontal: rf(14),
                    vertical: rf(10),
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(rf(12)),
                    border: Border.all(color: const Color(0xFFE2E5EA)),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: rf(18),
                            color: AppColors.bluePrimary,
                          ),

                          SizedBox(width: w * 0.02),

                          Text(
                            _dateFilter,
                            style: TextStyle(
                              fontSize: rf(13),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: rf(18),
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: h * 0.022),

              // Daftar riwayat surat atau state kosong.
              Expanded(
                child: _loading
                    ? buildLoading()
                    //menampilkan loading saat pengambilan data
                    : _error != null
                        ? buildError(_error!, _loadHistory)
                        : _filteredSurat.isEmpty
                            //menampilkan kosong jika data tidak sesuai filter
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    Container(
                                      width: w * 0.2,
                                      height: w * 0.2,

                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),

                                      child: Icon(
                                        Icons.inbox_outlined,
                                        size: rf(40),
                                        color: Colors.grey.shade300,
                                      ),
                                    ),

                                    SizedBox(height: h * 0.016),

                                    Text(
                                      "Belum ada riwayat surat",
                                      style: TextStyle(
                                        fontSize: rf(14),
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                //riwayat surat secara dinamis berdasarkan hasil filter
                                itemCount: _filteredSurat.length,

                                itemBuilder: (context, index) {
                                  final surat = _filteredSurat[index]; // FIX #9: hapus stray semicolon
                                  //mengambil data surat pada posisi index

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: rf(8)),

                                    child: SuratCard(
                                      //menampilkan informasi surat
                                      jenisSurat: surat['jenisSurat'].toString(),
                                      tanggal: surat['tanggal'].toString(),
                                      role: CardRole.users, // FIX #10: Users → users
                                      type: CardType.history,
                                      data: Map<String, String>.from(surat['data']),
                                      diteruskanKe: surat['diteruskanKe']?.toString(),
                                      lampiran: List<String>.from(surat['lampiran'] ?? []),
                                      //membuka lampiran surat ketika kartu surat ditekan
                                      onDetail: () => _openLampiran(context, surat),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          CustomNavbar(
            //navigasi utama untuk berpindah halaman
            role: widget.role,
            currentIndex: 1,
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

          ColoredBox(
            color: AppColors.bg,

            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}