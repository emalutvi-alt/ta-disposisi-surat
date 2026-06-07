import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/full-images-viewer.dart';

/// Halaman detail surat untuk role users (penerima disposisi).
/// Menampilkan info surat masuk/keluar beserta lampirannya.
class DetailSuratUsers extends StatelessWidget {
  final Map<String, dynamic> surat;

  const DetailSuratUsers({super.key, required this.surat});

  double rf(double size, double w) =>
      (w * (size / 375)).clamp(size * 0.9, size * 1.15);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    final data = Map<String, String>.from(surat['data'] ?? {});
    final lampiran = List<String>.from(surat['lampiran'] ?? []);
    final jenis = surat['jenisSurat']?.toString() ?? '';
    final tanggal = surat['tanggal']?.toString() ?? '-';
    final status = surat['status']?.toString() ?? '';
    final diteruskanKe = surat['diteruskanKe']?.toString() ?? '';
    final catatan = surat['catatan']?.toString() ?? '';

    final isMasuk = jenis == 'Surat Masuk';
    final color = isMasuk ? AppColors.bluePrimary : AppColors.orangePrimary;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.025, w * 0.05, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: color,
                      size: rf(20, w),
                    ),
                  ),
                  SizedBox(width: w * 0.015),
                  Expanded(
                    child: Text(
                      'Detail ${isMasuk ? "Surat Masuk" : "Surat Keluar"}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rf(18, w),
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.02),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    if (status.isNotEmpty) _buildStatusBadge(status, w, h),

                    SizedBox(height: h * 0.018),

                    // Info surat
                    _sectionCard(
                      w: w,
                      children: [
                        _infoRow('Jenis', jenis, w, h),
                        _infoRow('Tanggal', tanggal, w, h),
                        if (data['Dari'] != null && data['Dari']!.isNotEmpty)
                          _infoRow('Dari', data['Dari']!, w, h),
                        if (data['Perihal'] != null && data['Perihal']!.isNotEmpty)
                          _infoRow('Perihal', data['Perihal']!, w, h),
                        if (data['Kepada'] != null && data['Kepada']!.isNotEmpty)
                          _infoRow('Kepada', data['Kepada']!, w, h),
                        if (data['Nomor'] != null && data['Nomor']!.isNotEmpty)
                          _infoRow('Nomor Surat', data['Nomor']!, w, h),
                      ],
                    ),

                    SizedBox(height: h * 0.018),

                    // Diteruskan ke
                    if (diteruskanKe.trim().isNotEmpty) ...[
                      _sectionCard(
                        w: w,
                        children: [
                          _infoRow('Diteruskan Ke', diteruskanKe, w, h,
                              labelColor: color),
                        ],
                      ),
                      SizedBox(height: h * 0.018),
                    ],

                    // Catatan
                    if (catatan.trim().isNotEmpty) ...[
                      _sectionCard(
                        w: w,
                        children: [
                          Text(
                            'Catatan',
                            style: TextStyle(
                              fontSize: rf(13, w),
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          SizedBox(height: h * 0.01),
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(minHeight: h * 0.08),
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.03,
                              vertical: h * 0.012,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(w * 0.02),
                            ),
                            child: Text(
                              catatan,
                              style: TextStyle(fontSize: rf(13, w)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: h * 0.018),
                    ],

                    // Lampiran
                    if (lampiran.isNotEmpty) ...[
                      _sectionCard(
                        w: w,
                        children: [
                          Text(
                            'Lampiran',
                            style: TextStyle(
                              fontSize: rf(13, w),
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          SizedBox(height: h * 0.012),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: lampiran
                                .asMap()
                                .entries
                                .map(
                                  (e) => GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FullScreenImageViewer(
                                          imageUrls: lampiran,
                                          initialIndex: e.key,
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: w * 0.03,
                                        vertical: h * 0.01,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(w * 0.02),
                                        border: Border.all(
                                            color:
                                                color.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.attach_file,
                                              size: rf(14, w), color: color),
                                          SizedBox(width: w * 0.01),
                                          Text(
                                            'Lampiran ${e.key + 1}',
                                            style: TextStyle(
                                              fontSize: rf(13, w),
                                              color: color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                      SizedBox(height: h * 0.018),
                    ],

                    // Tombol lihat surat
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, h * 0.055),
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.05,
                            vertical: h * 0.014,
                          ),
                          side: BorderSide(color: color, width: 1.2),
                          foregroundColor: color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: lampiran.isEmpty
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      imageUrls: lampiran,
                                      initialIndex: 0,
                                    ),
                                  ),
                                ),
                        icon: Icon(Icons.remove_red_eye, size: rf(18, w)),
                        label: Text(
                          'Lihat Surat',
                          style: TextStyle(
                            fontSize: rf(14, w),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

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

  Widget _buildStatusBadge(String status, double w, double h) {
    final isApproved = status.toLowerCase() == 'disetujui';
    final isPending = status.toLowerCase() == 'diproses';
    final color = isApproved
        ? Colors.green
        : isPending
            ? Colors.orange
            : Colors.red;
    final icon = isApproved
        ? Icons.check_circle
        : isPending
            ? Icons.hourglass_top
            : Icons.cancel;

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: rf(16, w)),
          SizedBox(width: w * 0.02),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: rf(13, w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
      {required List<Widget> children, required double w}) {
    return Card(
      elevation: 3,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(w * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(w * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    double w,
    double h, {
    Color? labelColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: h * 0.012),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: w * 0.3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: rf(13, w),
                fontWeight: FontWeight.w600,
                color: labelColor ?? Colors.black54,
              ),
            ),
          ),
          Text(': ',
              style: TextStyle(
                  fontSize: rf(13, w), color: Colors.black54)),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(fontSize: rf(13, w)),
            ),
          ),
        ],
      ),
    );
  }
}
