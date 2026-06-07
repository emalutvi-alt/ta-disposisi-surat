import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/surat_card.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/custom_navbar.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/search_bar.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/helpers/navigation_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/hasil_disposisi_surat_masuk_page.dart';
import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/hasil_pengajuan_surat_keluar_page.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/api_ui_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/data_loader.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/filter_date.dart';

/// Halaman riwayat surat Tata Usaha.
/// Menampilkan seluruh surat yang telah selesai diproses dengan status disetujui atau ditolak.
class HistoryTUPage extends StatefulWidget {
  /// Data surat pengganti yang digunakan untuk testing atau pengiriman data dari halaman lain.
  final List<Map<String, dynamic>>? suratOverride;
  const HistoryTUPage({super.key, this.suratOverride});

  @override
  State<HistoryTUPage> createState() => _HistoryTUPageState();
}
/// State yang mengatur data, filter, pencarian, dan tampilan riwayat surat.
class _HistoryTUPageState extends State<HistoryTUPage> {
  /// Menyimpan kata kunci pencarian.
  String _searchQuery = '';
  /// Menyimpan status filter yang sedang aktif.
  String _statusFilter = 'semua';
  /// Menyimpan seluruh data surat yang berhasil dimuat.
  List<Map<String, dynamic>> _allSurat = [];
  /// Menandakan proses loading data.
  bool _loading = true;
  /// Menyimpan pesan error apabila terjadi kegagalan.
  String? _error;
/// menyimpan label filter tanggal yang sedang aktif
  String _dateFilter = 'Hari ini';
  /// menyinpan label chip tanggal yang sedang aktif
  String _activeChip = 'Hari ini';
/// menyimpan tanggal mulai untuk filter 
  DateTime? _startDate;
  /// menyimpan tanggal akhir untuk filter
  DateTime? _endDate;

/// Inisialisasi data saat halaman pertama kali dibuka
  @override
  void initState() {
    super.initState();

      /// Mengambil tanggal saat ini
    final now = DateTime.now();
      /// Mengatur awal rentang filter ke awal hari ini.
    _startDate = DateTime(now.year, now.month, now.day);
      /// mengatur akhir rentang filter ke akhir hari ini
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    /// Memuat data riwayat surat dari sumber data
    _loadHistory();
  }
    /// memuat data riwayat surat dari sumber data
  Future<void> _loadHistory() async {
    /// mengatur state menjadi loading dan menghapus error sebelumnya
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      /// Mengambil seluruh data surat dari penyimpanan
      final list = await DataLoader.loadAllSurat();
      /// Menghentikan proses jika widget sudah tidak aktif
      if (!mounted) return;
        /// Menyimpan hasil data ke state
      setState(() {
        _allSurat = list;
        _loading = false;
      });
    } catch (e) {
      /// Menyimpan pesan error apabila proses gagal dan menghentikan ;oading
      if (!mounted) return;
    
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  
   /// Menggunakan data override jika tersedia, jika tidak menggunakan data hasil loading
  List<Map<String, dynamic>> get _historySurat =>
      widget.suratOverride ?? _allSurat;
   /// menghasilkan daftar surat yang sudah difilter berdasarkan status, pencarian, dan rentang tanggal
  List<Map<String, dynamic>> get _filteredSurat {
    return _historySurat.where((s) {
      /// Mengambil status surat
      final status = s['status'].toString().toLowerCase();
        /// Hanya menampilkan surat yang sudah selesai diproses.
      if (status != 'disetujui' && status != 'ditolak') {
        return false;
      }
       /// mengubah query pencarian menjadi huruf kecil
      final query = _searchQuery.toLowerCase();
       /// Mengambil data yang digunakan untuk pencarian
      final jenis = s['jenisSurat'].toString().toLowerCase();

      final tanggal = s['tanggal'].toString().toLowerCase();

      final dari = s['data']['Dari'].toString().toLowerCase();

      final perihal = s['data']['Perihal'].toString().toLowerCase();

       /// Mencocokkan data surat dengan kata kunci pencarian dan filter status
      final matchSearch =
          _searchQuery.isEmpty ||
          jenis.contains(query) ||
          tanggal.contains(query) ||
          dari.contains(query) ||
          perihal.contains(query);
           /// Memfilter data berdasarkan status yang dipilih
      final matchStatus = _statusFilter == 'semua' || status == _statusFilter;
       //// memfilter data berdasarkan rentang tanggal yang dipilih
      bool matchDate = true;
      /// Mengambil objek tanggal surat dan mengonversikannya menjadi DateTime
      final tanggalObj = s['tanggal_obj'];
      DateTime? suratDate;
      if (tanggalObj is DateTime) {
        suratDate = tanggalObj;
      } else if (tanggalObj != null) {
        suratDate = DateTime.tryParse(tanggalObj.toString());
      }

      if (suratDate != null && _startDate != null && _endDate != null) {
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
        /// Memastikan tanggal surat berada dalam rentang filter yang dipilih
        matchDate =
            suratDate.isAfter(start.subtract(const Duration(days: 1))) &&
            suratDate.isBefore(end.add(const Duration(seconds: 1)));
      }
       /// Mengembalikan hasil filter gabungan dari pencarian,status, dan tanggal
      return matchSearch && matchStatus && matchDate;
    }).toList();
  }
    /// Menampilkan bottom sheet pemilihan tanggal
  void _showDateFilter() async {
    /// Membuka filter rentang tanggal
    final result = await DateRangeFilterBottomSheet.show(
      context: context,
      initialStartDate: _startDate,
      initialEndDate: _endDate,
      initialChip: _activeChip,
    );
      /// Menghentikan proses jika tidak ada perubahan
    if (result == null) return;
      /// Menyimpan hasil filter tanggal yang dipilih
    setState(() {
      _startDate = result.startDate;
      _endDate = result.endDate;
      _activeChip = result.activeChip;
      _dateFilter = result.dateFilterLabel;
    });
  }
   /// Membangun seluruh tampilan halaman riwayat sura
  @override
  Widget build(BuildContext context) {
    /// Mengambil ukuran layar perangka
    final w = MediaQuery.of(context).size.width;

    final h = MediaQuery.of(context).size.height;
    /// Mengambil padding bawah perangkat untuk menghindari bentrok dengan navbar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
     /// Menghasilkan ukuran font responsif berdasarkan lebar layar dengan batasan minimum dan maksimum
    double rf(double size) {
      return (w * (size / 375)).clamp(size * 0.9, size * 1.15);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.018, w * 0.04, 0),
              child: Column(
                children: [
                  Text(
                    "Riwayat",
                    style: TextStyle(
                      fontSize: rf(24),
                      fontWeight: FontWeight.w800,
                      color: AppColors.bluePrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  SizedBox(height: h * 0.016),

                  SearchBarInput(
                    /// Memperbarui kata kunci pencarian secara realtime
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),

                  SizedBox(height: h * 0.014),
                    /// Filter status surat:
                    /// Semua, Disetujui, dan Ditolak
                  Wrap(
                    spacing: w * 0.02,
                    runSpacing: h * 0.01,
                    children: [
                      SizedBox(
                        width: (w - (w * 0.12)) / 3,
                        child: _filterChip("semua"),
                      ),

                      SizedBox(
                        width: (w - (w * 0.12)) / 3,
                        child: _filterChip("disetujui"),
                      ),

                      SizedBox(
                        width: (w - (w * 0.12)) / 3,
                        child: _filterChip("ditolak"),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.012),

                  GestureDetector(
                    /// Membuka dialog filter tanggal saat ditekan
                    onTap: _showDateFilter,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.035,
                        vertical: h * 0.018,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(w * 0.03),
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

                  SizedBox(height: h * 0.016),
                ],
              ),
            ),

            Expanded(
              /// Menampilkan indikator loading
              /// selama data sedang dimuat
              child: _loading
                  ? buildLoading()
                  /// Menampilkan pesan error apabila gagal memuat data
                  : _error != null
                      ? buildError(_error!, _loadHistory)
                      /// Menampilkan informasi apabila tidak ada data riwayat yang sesui dengan filter
                      : _filteredSurat.isEmpty
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
                              size: (w * 0.1).clamp(36, 60),
                              color: Colors.grey.shade300,
                            ),
                          ),

                          SizedBox(height: h * 0.016),

                          Text(
                            "Belum ada riwayat surat",
                            style: TextStyle(
                              fontSize: rf(15),
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                    /// Menampilkan daftar riwayat surat yang lolos filter
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        w * 0.04,
                        0,
                        w * 0.04,
                        h * 0.02,
                      ),
                      itemCount: _filteredSurat.length,
                      itemBuilder: (context, index) {
                        /// Mengambil data surat berdasarkan indeks
                        final surat = _filteredSurat[index];
                         /// Menentukan apakah surat termasuk surat masuk
                        final isMasuk = surat['jenisSurat'] == 'Surat Masuk';

                        return SuratCard(
                          jenisSurat: surat['jenisSurat'] ?? '',
                          tanggal: surat['tanggal'] ?? '-',
                          data: Map<String, String>.from(surat['data'] ?? {}),
                          role: CardRole.tu,
                          type: CardType.history,
                          status: surat['status'],
                          lampiran: List<String>.from(surat['lampiran'] ?? []),
                          /// Membuka halaman detail surat sesuai jenis surat
                          onDetail: () {
                            /// Navigasi menuju halaman hasil disposisi surat masuk atau surat keluar
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => isMasuk
                                      /// Menampilkan detail hasil disposisi surat masuk
                                    ? OutputSuratmasuk(
                                        isApproved:
                                            surat['status'] == 'disetujui',
                                        catatan: surat['catatan'] ?? '-',
                                        tujuan: surat['tujuan'] ?? '-',
                                        instruksi: surat['instruksi'] ?? '-',
                                        koordinasi: surat['koordinasi'] ?? '-',
                                        diteruskanKe:
                                            surat['diteruskanKe'] ?? '-',
                                        isReadOnly: true,
                                        lampiranUrls: List<String>.from(
                                          surat['lampiran'] ?? [],
                                        ),
                                      )
                                      /// Menampilkan detail hasil disposisi surat keluar
                                    : OutputSuratkeluar(
                                        catatan: surat['catatan'] ?? '-',
                                        isReadOnly: true,
                                        lampiranUrls: List<String>.from(
                                          surat['lampiran'] ?? [],
                                        ),
                                      ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
        /// Navbar utama Tata Usaha
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: w * 0.03,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: CustomNavbar(
              role: Role.tu,
              currentIndex: 1,
              /// Menangani perpindahan halaman melalui navbar
              onTap: (index) {
                /// Menjalankan navigasi sesuai menu yang dipilih
                handleNavbarTap(
                  context,
                  index,
                  Role.tu,
                  "Tata Usaha",
                  "tu@gmail.com",
                  "Tata Usaha",
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
    );
  }
   /// Widget filter status surat
  Widget _filterChip(String label) {
    final w = MediaQuery.of(context).size.width;

    double rf(double size) {
      return (w * (size / 375)).clamp(size * 0.9, size * 1.1);
    }
      /// Mengecek apakah filter sedang aktif brdasarkan label dan status filter yang dipilih
    final isActive = _statusFilter == label;

    Color activeColor;
      /// Menentukan warna berdasarkan status filter
    switch (label) {
      case 'disetujui':
        activeColor = const Color(0xFF3F9142);
        break;

      case 'ditolak':
        activeColor = const Color(0xFFB63A3A);
        break;

      default:
        activeColor = AppColors.bluePrimary;
    }
     /// Mengubah huruf pertama menjadi kapital
    final displayLabel = label[0].toUpperCase() + label.substring(1);

    return GestureDetector(
      /// Mengubah status filter ketika chip dipilih
      onTap: () {
        setState(() {
          _statusFilter = label;
        });
      },
        /// Memberikan animasi saat filter berubah
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFD1D5DB),
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          displayLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: rf(13),
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
