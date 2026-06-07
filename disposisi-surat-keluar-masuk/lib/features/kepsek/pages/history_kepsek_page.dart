import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/surat_card.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/custom_navbar.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/search_bar.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/helpers/navigation_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/api_ui_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/data_loader.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/filter_date.dart';
import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/hasil_disposisi_surat_masuk_page.dart';
import 'package:ta_mobile_disposisi_surat/features/tata_usaha/pages/hasil_pengajuan_surat_keluar_page.dart';

class HistoryKepsekPage extends StatefulWidget {
  const HistoryKepsekPage({super.key});

  @override
  State<HistoryKepsekPage> createState() => _HistoryKepsekPageState();
}

class _HistoryKepsekPageState extends State<HistoryKepsekPage> {
  /// Menyimpan teks pencarian riwayat surat.
  String _searchQuery = '';

  /// Menyimpan filter jenis surat (semua/masuk/keluar).
  String _jenisFilter = 'semua';

  /// Label filter tanggal yang tampil di UI.
  String _dateFilter = 'Hari ini';

  /// Menyimpan chip filter tanggal aktif.
  String _activeChip = 'Hari ini';

  /// Tanggal awal rentang filter tanggal.
  DateTime? _startDate;

  /// Tanggal akhir rentang filter tanggal.
  DateTime? _endDate;
  List<Map<String, dynamic>> _allSurat = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _startDate = DateTime(now.year, now.month, now.day);

    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadHistory();
  }

  /// Sumber data riwayat surat.
  List<Map<String, dynamic>> get _historySurat => _allSurat;

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await DataLoader.loadAllSurat();
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

  /// Menggabungkan filter pencarian, jenis surat, dan tanggal.
  List<Map<String, dynamic>> get _filteredSurat {
    return _historySurat.where((s) {
      final query = _searchQuery.toLowerCase();
      final jenis = s['jenisSurat'].toString().toLowerCase();
      final dari = s['data']['Dari'].toString().toLowerCase();
      final perihal = s['data']['Perihal'].toString().toLowerCase();
      final tanggal = s['tanggal'].toString().toLowerCase();

      final matchSearch =
          _searchQuery.isEmpty ||
          jenis.contains(query) ||
          dari.contains(query) ||
          perihal.contains(query) ||
          tanggal.contains(query);

      final matchJenis =
          _jenisFilter == 'semua' ||
          (_jenisFilter == 'masuk' && jenis.contains('masuk')) ||
          (_jenisFilter == 'keluar' && jenis.contains('keluar'));

      bool matchDate = true;
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
        matchDate =
            suratDate.isAfter(start.subtract(const Duration(days: 1))) &&
            suratDate.isBefore(end.add(const Duration(seconds: 1)));
      }
      final status = s['status'].toString().toLowerCase();

      final matchStatus = status == 'disetujui' || status == 'ditolak';

      return matchSearch && matchJenis && matchDate && matchStatus;
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

    if (result == null) return;

    setState(() {
      _startDate = result.startDate;
      _endDate = result.endDate;
      _activeChip = result.activeChip;
      _dateFilter = result.dateFilterLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(height: h * 0.02),

              // Judul halaman riwayat.
              Text(
                "Riwayat",
                style: TextStyle(
                  fontSize: w * 0.07,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bluePrimary,
                ),
              ),

              SizedBox(height: h * 0.02),

              // Input pencarian daftar riwayat surat.
              SearchBarInput(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              SizedBox(height: h * 0.018),

              // Tombol filter jenis surat.
              Row(
                children: [
                  Expanded(child: _filterButton("Semua", "semua")),
                  const SizedBox(width: 10),
                  Expanded(child: _filterButton("Masuk", "masuk")),
                  const SizedBox(width: 10),
                  Expanded(child: _filterButton("Keluar", "keluar")),
                ],
              ),

              SizedBox(height: h * 0.014),

              // Pemilih filter tanggal riwayat surat.
              GestureDetector(
                onTap: _showDateFilter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E5EA)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppColors.bluePrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _dateFilter,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: h * 0.016),

              // Menampilkan data riwayat atau state kosong.
              Expanded(
                child: _loading
                    ? buildLoading()
                    : _error != null
                        ? buildError(_error!, _loadHistory)
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
                                size: w * 0.1,
                                color: Colors.grey.shade300,
                              ),
                            ),
                            SizedBox(height: h * 0.016),
                            Text(
                              "Belum ada riwayat surat",
                              style: TextStyle(
                                fontSize: w * 0.038,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: _filteredSurat.length,
                        itemBuilder: (context, index) {
                          final surat = _filteredSurat[index];

                          return Padding(
                            padding: EdgeInsets.only(bottom: h * 0.001),
                            child: SuratCard(
                              jenisSurat: surat['jenisSurat'],
                              tanggal: surat['tanggal'],
                              status: surat['status'],
                              role: CardRole.kepsek,
                              type: CardType.history,
                              data: Map<String, String>.from(surat['data']),
                              lampiran: List<String>.from(surat['lampiran'] ?? []),
                              onDetail: () {
                                final isMasuk =
                                    surat['jenisSurat'] == 'Surat Masuk';
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => isMasuk
                                        ? OutputSuratmasuk(
                                            isApproved:
                                                surat['status'] == 'disetujui',
                                            catatan: surat['catatan'] ?? '-',
                                            tujuan: surat['tujuan'] ?? '-',
                                            instruksi:
                                                surat['instruksi'] ?? '-',
                                            koordinasi:
                                                surat['koordinasi'] ?? '-',
                                            diteruskanKe:
                                                surat['diteruskanKe'] ?? '-',
                                            isReadOnly: true,
                                            lampiranUrls: List<String>.from(
                                              surat['lampiran'] ?? [],
                                            ),
                                          )
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
            role: Role.kepsek,
            currentIndex: 1,
            onTap: (index) {
              handleNavbarTap(
                context,
                index,
                Role.kepsek,
                "Kepala Sekolah",
                "kepsek@gmail.com",
                "Kepala Sekolah",
              );
            },
          ),

          ColoredBox(
            color: AppColors.bg,
            child: SizedBox(height: bottomPadding, width: double.infinity),
          ),
        ],
      ),
    );
  }

  /// Membangun tombol filter jenis surat dengan status aktif.
  Widget _filterButton(String text, String value) {
    final isActive = _jenisFilter == value;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _jenisFilter = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? AppColors.bluePrimary : Colors.white,
        foregroundColor: isActive ? Colors.white : AppColors.bluePrimary,
        elevation: isActive ? 2 : 0,
        side: BorderSide(color: AppColors.bluePrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(text),
    );
  }
}
