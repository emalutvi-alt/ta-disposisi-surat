import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/full-images-viewer.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/lampiran_viewer.dart';

class OutputSuratmasuk extends StatefulWidget {
  final bool isApproved;
  final String catatan;
  final String tujuan;
  final String instruksi;
  final String koordinasi;
  final String diteruskanKe;
  final bool isReadOnly;
  final List<String> lampiranUrls;

  const OutputSuratmasuk({
    super.key,
    required this.isApproved,
    required this.catatan,
    required this.tujuan,
    required this.instruksi,
    required this.koordinasi,
    required this.diteruskanKe,
    this.isReadOnly = false,
    this.lampiranUrls = const [],
  });

  @override
  State<OutputSuratmasuk> createState() => _OutputSuratmasukState();
}

class _OutputSuratmasukState extends State<OutputSuratmasuk> {
  double rf(double size, double w) {
    return (w * (size / 375)).clamp(size * 0.9, size * 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.025, w * 0.05, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.bluePrimary,
                          size: rf(20, w),
                        ),
                      ),
                      SizedBox(width: w * 0.015),
                      Text(
                        "Detail Surat Masuk",
                        style: TextStyle(
                          fontSize: rf(18, w),
                          fontWeight: FontWeight.bold,
                          color: AppColors.bluePrimary,
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
                        _buildStatusBadge(w, h),
                        SizedBox(height: h * 0.02),

                        if (widget.diteruskanKe.trim().isNotEmpty) ...[
                          _sectionCard(
                            w: w,
                            children: [
                              _readOnlyField(
                                label: "Diteruskan Ke",
                                value: widget.diteruskanKe,
                                w: w,
                                h: h,
                              ),
                            ],
                          ),
                          SizedBox(height: h * 0.02),
                        ],

                        if (widget.catatan.trim().isNotEmpty) ...[
                          _sectionCard(
                            w: w,
                            children: [
                              _labeledTextArea(
                                label: "Catatan Kepala Sekolah",
                                value: widget.catatan,
                                w: w,
                                h: h,
                                labelColor: AppColors.bluePrimary,
                              ),
                            ],
                          ),
                          SizedBox(height: h * 0.02),
                        ],

                        if (widget.isApproved &&
                            (widget.tujuan.trim().isNotEmpty ||
                                widget.instruksi.trim().isNotEmpty ||
                                widget.koordinasi.trim().isNotEmpty)) ...[
                          _sectionCard(
                            w: w,
                            children: [
                              _buildSectionHeader("Detail Disposisi", Colors.green),
                              SizedBox(height: h * 0.015),
                              if (widget.tujuan.trim().isNotEmpty)
                                _labeledTextArea(
                                  label: "Tanggapan dan Saran",
                                  value: widget.tujuan,
                                  w: w,
                                  h: h,
                                ),
                              if (widget.tujuan.trim().isNotEmpty &&
                                  (widget.instruksi.trim().isNotEmpty ||
                                      widget.koordinasi.trim().isNotEmpty))
                                SizedBox(height: h * 0.015),
                              if (widget.instruksi.trim().isNotEmpty)
                                _labeledTextArea(
                                  label: "Proses Lebih Lanjut",
                                  value: widget.instruksi,
                                  w: w,
                                  h: h,
                                ),
                              if (widget.instruksi.trim().isNotEmpty &&
                                  widget.koordinasi.trim().isNotEmpty)
                                SizedBox(height: h * 0.015),
                              if (widget.koordinasi.trim().isNotEmpty)
                                _labeledTextArea(
                                  label: "Koordinasi / Konfirmasi",
                                  value: widget.koordinasi,
                                  w: w,
                                  h: h,
                                ),
                            ],
                          ),
                          SizedBox(height: h * 0.02),
                        ],

                        // ── Lampiran viewer (tampil always jika ada) ─────────────
                        if (widget.lampiranUrls.isNotEmpty) ...[
                          _sectionCard(
                            w: w,
                            children: [
                              LampiranViewer(
                                urls: widget.lampiranUrls,
                                accentColor: AppColors.bluePrimary,
                              ),
                            ],
                          ),
                          SizedBox(height: h * 0.025),
                        ],

                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(0, h * 0.055),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.05,
                                    vertical: h * 0.014,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.bluePrimary,
                                    width: 1.2,
                                  ),
                                  foregroundColor: AppColors.bluePrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  if (widget.lampiranUrls.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('File surat tidak tersedia')),
                                    );
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImageViewer(
                                        imageUrls: widget.lampiranUrls,
                                        initialIndex: 0,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.remove_red_eye, size: w * 0.045),
                                label: Text(
                                  "Lihat Surat",
                                  style: TextStyle(
                                    fontSize: rf(14, w),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              if (!widget.isReadOnly) ...[
                                if (widget.isApproved)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(0, h * 0.055),
                                      backgroundColor: AppColors.bluePrimary,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: w * 0.05,
                                        vertical: h * 0.014,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    icon: Icon(Icons.send, size: w * 0.045),
                                    label: Text(
                                      "Teruskan",
                                      style: TextStyle(
                                        fontSize: rf(14, w),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(0, h * 0.055),
                                      backgroundColor: AppColors.bluePrimary,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: w * 0.05,
                                        vertical: h * 0.014,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text(
                                      "Konfirmasi",
                                      style: TextStyle(
                                        fontSize: rf(14, w),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
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
        ),
      ),
    );
  }

  Widget _buildStatusBadge(double w, double h) {
    final color = widget.isApproved ? Colors.green : Colors.red;
    final text = widget.isApproved ? 'Disetujui' : 'Ditolak';
    final icon = widget.isApproved ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
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
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: rf(14, w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: rf(14, 375),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required List<Widget> children, required double w}) {
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

  Widget _readOnlyField({
    required String label,
    required String value,
    required double w,
    required double h,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: h * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: rf(14, w),
              fontWeight: FontWeight.bold,
              color: AppColors.bluePrimary,
            ),
          ),
          SizedBox(height: h * 0.008),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.03,
              vertical: h * 0.012,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(w * 0.02),
            ),
            child: Text(
              value.isEmpty ? "-" : value,
              style: TextStyle(fontSize: rf(14, w)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledTextArea({
    required String label,
    required String value,
    required double w,
    required double h,
    Color? labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: rf(14, w),
            fontWeight: FontWeight.bold,
            color: labelColor ?? AppColors.bluePrimary,
          ),
        ),
        SizedBox(height: h * 0.008),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: h * 0.1),
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.03,
            vertical: h * 0.012,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(w * 0.02),
          ),
          child: Text(
            value.isEmpty ? "" : value,
            style: TextStyle(fontSize: rf(14, w)),
          ),
        ),
      ],
    );
  }
}
