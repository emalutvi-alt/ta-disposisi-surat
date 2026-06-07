   import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/services/surat_service.dart';
import 'package:ta_mobile_disposisi_surat/services/disposisi_service.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';

class DisposisiSuratMasukPage extends StatefulWidget {
  final Map<String, dynamic> surat;
  const DisposisiSuratMasukPage({super.key, required this.surat});

  @override
  State<DisposisiSuratMasukPage> createState() =>
      _DisposisiSuratMasukPageState();
}

class _DisposisiSuratMasukPageState extends State<DisposisiSuratMasukPage> {
  final SuratService _suratService = SuratService();

  // FIX P0: Tambah DisposisiService
  final DisposisiService _disposisiService = DisposisiService();

  final catatanTerimaController = TextEditingController();
  final catatanTolakController = TextEditingController();

  bool isApproved = true;
  bool _submitting = false;

  // FIX P0: _tujuanOptions diisi dari API, bukan list kosong
  List<String> _tujuanOptions = [];
  List<Map<String, dynamic>> _tujuanRawList = [];
  List<String> selectedTujuan = [];
  bool _loadingTargets = false;

  @override
  void initState() {
    super.initState();
    _loadTujuanOptions(); // FIX P0: Load dari API saat halaman dibuka
  }

  // FIX P0: Fetch target disposisi dari GET /users/disposisi-targets
  Future<void> _loadTujuanOptions() async {
    setState(() => _loadingTargets = true);
    try {
      final targets = await _disposisiService.listTargets();
      setState(() {
        _tujuanRawList = targets;
        _tujuanOptions = targets.map((e) => e['nama'] as String).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat daftar penerima: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTargets = false);
    }
  }

  // FIX P0: _submitDisposisi sekarang:
  //   Step 1 → verifikasi surat (sudah ada sebelumnya)
  //   Step 2 → buat disposisi via POST /disposisi (ini yang hilang sebelumnya)
  Future<void> _submitDisposisi() async {
    final suratId = (widget.surat['id'] as num?)?.toInt();
    if (suratId == null) return;

    final approved = isApproved;
    final catatan = approved
        ? catatanTerimaController.text.trim()
        : catatanTolakController.text.trim();

    if (approved && selectedTujuan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu penerima disposisi')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // Step 1: Verifikasi surat masuk
      await _suratService.verifikasiSuratMasuk(
        suratId: suratId,
        isApproved: approved,
        catatan: catatan,
      );

      // Step 2: Jika disetujui, buat disposisi ke backend
      if (approved && selectedTujuan.isNotEmpty) {
        // Konversi nama tujuan → ID
        final tujuanIds = selectedTujuan.map((nama) {
          final match = _tujuanRawList.firstWhere(
            (e) => e['nama'] == nama,
            orElse: () => {'id': 0},
          );
          return (match['id'] as num).toInt();
        }).where((id) => id != 0).toList();

        if (tujuanIds.isNotEmpty) {
          await _disposisiService.create(
            suratMasukId: suratId,
            tujuanIds: tujuanIds,
            catatan: catatanTerimaController.text.trim(),
            sifat: widget.surat['sifat']?.toString() ?? '',
            batasWaktu: '',
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Surat disetujui & disposisi berhasil dikirim'
                : 'Surat berhasil ditolak',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // true = ada perubahan, refresh list
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    catatanTerimaController.dispose();
    catatanTolakController.dispose();
    super.dispose();
  }
void _showPenerimaBottomSheet() {
  String query = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _tujuanOptions
              .where((nama) => nama.toLowerCase().contains(query.toLowerCase()))
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih Penerima Disposisi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Cari penerima...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (val) => setModalState(() => query = val),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                // List
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Tidak ada hasil',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final nama = filtered[index];
                            final isSelected = selectedTujuan.contains(nama);
                            return CheckboxListTile(
                              title: Text(nama),
                              value: isSelected,
                              onChanged: (val) {
                                setModalState(() {});
                                setState(() {
                                  if (val == true) {
                                    selectedTujuan.add(nama);
                                  } else {
                                    selectedTujuan.remove(nama);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),

                const Divider(height: 1),
                const SizedBox(height: 8),

                // Tombol selesai
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        selectedTujuan.isEmpty
                            ? 'Selesai'
                            : 'Selesai (${selectedTujuan.length} dipilih)',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disposisi Surat Masuk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info surat
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.surat['perihal']?.toString() ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No: ${widget.surat['nomor_surat'] ?? '-'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Dari: ${widget.surat['asal_surat'] ?? '-'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle Setuju / Tolak
            RadioGroup<bool>(
              groupValue: isApproved,
              onChanged: (v) => setState(() => isApproved = v!),
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Setujui'),
                      value: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Tolak'),
                      value: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Jika disetujui: tampilkan pilihan penerima & catatan terima
  if (isApproved) ...[
  Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penerima Disposisi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          if (_loadingTargets)
            const Center(child: CircularProgressIndicator())
          else
            InkWell(
              onTap: _tujuanOptions.isEmpty ? null : _showPenerimaBottomSheet,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedTujuan.isEmpty
                            ? 'Pilih penerima...'
                            : selectedTujuan.join(', '),
                        style: TextStyle(
                          color: selectedTujuan.isEmpty
                              ? Colors.grey
                              : Colors.black,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          const Text(
            'Catatan',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: catatanTerimaController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
  ),
],

            // Jika ditolak: tampilkan catatan tolak
            if (!isApproved) ...[
              TextField(
                controller: catatanTolakController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan penolakan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitting ? null : _submitDisposisi,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: isApproved ? Colors.blue : Colors.red,
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isApproved ? 'Setujui & Kirim Disposisi' : 'Tolak Surat'),
            ),
          ],
        ),
      ),
    );
  }
}

