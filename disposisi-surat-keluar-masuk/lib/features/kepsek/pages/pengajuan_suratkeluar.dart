import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/full-images-viewer.dart';
import 'package:ta_mobile_disposisi_surat/services/surat_service.dart';

class InputSuratKeluar extends StatefulWidget {
  final Map<String, dynamic>? surat;

  const InputSuratKeluar({super.key, this.surat});

  @override
  State<InputSuratKeluar> createState() => _InputSuratKeluarState();
}

class _InputSuratKeluarState extends State<InputSuratKeluar> {
  final SuratService _suratService = SuratService();
  final TextEditingController _catatanController = TextEditingController();
  bool _submitting = false;
  bool _isApproved = true;
  String? _catatanError;

  int? get _suratId => widget.surat?['id'] is num ? (widget.surat!['id'] as num).toInt() : null;
  List<String> get _lampiran => List<String>.from(widget.surat?['lampiran'] ?? []);

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() => _catatanError = null);
    if (!_isApproved && _catatanController.text.trim().isEmpty) {
      setState(() => _catatanError = 'Catatan wajib diisi saat menolak surat');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_suratId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID surat tidak valid')),
      );
      return;
    }
    
    if (!_validate()) return;
    
    setState(() => _submitting = true);
    
    try {
      await _suratService.verifikasiSuratKeluar(
        suratId: _suratId!,
        isApproved: _isApproved,
        catatan: _catatanController.text.trim(),
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isApproved 
                ? 'Surat keluar berhasil disetujui' 
                : 'Surat keluar berhasil ditolak',
          ),
        ),
      );
      
      Navigator.pop(context, true);
      
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memverifikasi surat')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.025, w * 0.05, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.orangePrimary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                  const Expanded(
                    child: Text(
                      "Verifikasi Surat Keluar",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orangePrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: h * 0.025),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(w, h),
                    SizedBox(height: h * 0.02),
                    
                    if (_lampiran.isNotEmpty) ...[
                      _buildLampiranPreview(w, h),
                      SizedBox(height: h * 0.02),
                    ],
                    
                    _buildToggle(w),
                    SizedBox(height: h * 0.02),
                    
                    _buildCatatanField(w, h),
                    SizedBox(height: h * 0.03),
                    
                    _buildSubmitButton(w),
                    SizedBox(height: h * 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(double w, double h) {
    final data = widget.surat?['data'] ?? {};
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(Icons.description_outlined, 'Nomor Surat', data['Nomor Surat'] ?? '-'),
          _detailRow(Icons.calendar_today_outlined, 'Tanggal', widget.surat?['tanggal'] ?? '-'),
          _detailRow(Icons.person_outline, 'Pengirim', data['Dari'] ?? 'SMKN 2 Singosari'),
          _detailRow(Icons.notes, 'Perihal', data['Perihal'] ?? '-'),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLampiranPreview(double w, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lampiran Surat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: h * 0.01),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    imageUrls: _lampiran,
                    initialIndex: 0,
                  ),
                ),
              );
            },
            child: Container(
              height: h * 0.2,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, color: AppColors.orangePrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Lihat ${_lampiran.length} Lampiran',
                      style: TextStyle(
                        color: AppColors.orangePrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keputusan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: w * 0.03),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isApproved = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: w * 0.03),
                    decoration: BoxDecoration(
                      color: _isApproved ? const Color(0xFF66BB6A) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isApproved ? const Color(0xFF66BB6A) : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _isApproved ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Setuju',
                            style: TextStyle(
                              color: _isApproved ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isApproved = false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: w * 0.03),
                    decoration: BoxDecoration(
                      color: !_isApproved ? const Color(0xFFEF5350) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_isApproved ? const Color(0xFFEF5350) : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cancel,
                            color: !_isApproved ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tolak',
                            style: TextStyle(
                              color: !_isApproved ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanField(double w, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isApproved ? 'Catatan (opsional)' : 'Catatan Penolakan *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: h * 0.015),
          TextField(
            controller: _catatanController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _isApproved 
                  ? 'Tambahkan catatan jika diperlukan...'
                  : 'Berikan alasan penolakan...',
              errorText: _catatanError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.orangePrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(double w) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isApproved ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isApproved ? 'Setuju Surat Keluar' : 'Tolak Surat Keluar',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
