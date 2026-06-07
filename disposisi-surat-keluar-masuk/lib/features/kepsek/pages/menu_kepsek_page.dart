import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';

import 'package:ta_mobile_disposisi_surat/shared/widgets/search_bar.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/surat_card.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/api_ui_helper.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/data_loader.dart';

import 'package:ta_mobile_disposisi_surat/features/kepsek/pages/disposisi_suratmasuk.dart';
import 'package:ta_mobile_disposisi_surat/features/kepsek/pages/pengajuan_suratkeluar.dart';

class KepsekDashboardPage extends StatefulWidget {
  final String jenisSurat;

  const KepsekDashboardPage({super.key, required this.jenisSurat});

  @override
  State<KepsekDashboardPage> createState() => _KepsekDashboardPageState();
}

class _KepsekDashboardPageState extends State<KepsekDashboardPage> {
  /// Menyimpan kata kunci pencarian dari komponen search bar.
  String _searchQuery = '';
  List<Map<String, dynamic>> _allSurat = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurat();
  }

  Future<void> _loadSurat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await DataLoader.loadSuratByJenis(
        widget.jenisSurat,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
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

  /// Memfilter surat berdasarkan jenis surat dan input pencarian.
  List<Map<String, dynamic>> get _filteredSurat {
    return _allSurat.where((s) => s['jenisSurat'] == widget.jenisSurat).where((
      s,
    ) {
      if (_searchQuery.isEmpty) {
        return true;
      }

      final query = _searchQuery.toLowerCase();

      final dari = (s['data']?['Dari'] ?? '').toString().toLowerCase();

      final perihal = (s['data']?['Perihal'] ?? '').toString().toLowerCase();

      return dari.contains(query) || perihal.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: AppColors.bg,

      /// App bar dengan identitas visual pengguna.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFFF2F2F2),
        surfaceTintColor: Colors.transparent,

        actions: [
          Padding(
            padding: EdgeInsets.only(right: w * 0.04),

            child: SizedBox(
              width: w * 0.1,
              height: w * 0.1,

              child: ClipOval(
                child: Image.asset(
                  'assets/images/logosmk.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),

      /// Area utama berisi judul, pencarian, dan daftar surat.
      body: Padding(
        padding: EdgeInsets.all(w * 0.04),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// Judul halaman disposisi surat.
            Text(
              'Disposisi Surat',

              style: TextStyle(
                fontSize: (w * 0.055).clamp(18.0, 24.0),

                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: h * 0.015),

            /// Pencarian surat berdasarkan pengirim atau perihal.
            SearchBarInput(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadSurat();
              },
            ),

            SizedBox(height: h * 0.015),

            /// Daftar surat hasil filter yang dapat dibuka detailnya.
            Expanded(
              child: _loading
                  ? buildLoading()
                  : _error != null
                      ? buildError(_error!, _loadSurat)
                      : _filteredSurat.isEmpty
                          ? buildEmpty('Belum ada surat')
                          : ListView.builder(
                padding: EdgeInsets.only(bottom: h * 0.03),

                itemCount: _filteredSurat.length,

                itemBuilder: (context, index) {
                  final surat = _filteredSurat[index];

                  return Padding(
                    padding: EdgeInsets.only(bottom: h *0.01),
                    child: SuratCard(
                      jenisSurat: surat['jenisSurat'],
                      tanggal: surat['tanggal'],
                      status: surat['status'],
                      data: Map<String, String>.from(surat['data']),
                      role: CardRole.kepsek,
                      type: CardType.menu,
                      lampiran: List<String>.from(surat['lampiran'] ?? []),

                      onDetail: () async {
                        final isMasuk = surat['jenisSurat'] == 'Surat Masuk';

                        final refreshed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => isMasuk
                                ? DisposisiSuratMasukPage(surat: surat)
                                : InputSuratKeluar(surat: surat),
                          ),
                        );
                        if (refreshed == true) {
                          _loadSurat();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
