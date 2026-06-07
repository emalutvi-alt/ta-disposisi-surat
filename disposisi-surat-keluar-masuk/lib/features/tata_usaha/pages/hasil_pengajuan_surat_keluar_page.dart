import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/full-images-viewer.dart';
import 'package:ta_mobile_disposisi_surat/shared/widgets/lampiran_viewer.dart';

class OutputSuratkeluar extends StatefulWidget {
  final String catatan;
  final bool isReadOnly;
  final List<String> lampiranUrls;

  const OutputSuratkeluar({
    super.key,
    required this.catatan,
    this.isReadOnly = false,
    this.lampiranUrls = const [],
  });

  @override
  State<OutputSuratkeluar> createState() => _OutputSuratkeluarState();
}

class _OutputSuratkeluarState extends State<OutputSuratkeluar> {
  double rf(double size, double w) {
    return (w * (size / 375)).clamp(size * 0.9, size * 1.15);
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
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.orangePrimary,
                      size: rf(20, w),
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                  Expanded(
                    child: Text(
                      "Detail Surat Keluar",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rf(18, w),
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
                    _buildCatatanCard(w, h),
                    SizedBox(height: h * 0.025),

                    if (widget.lampiranUrls.isNotEmpty) ...[
                      Card(
                        elevation: 3,
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(w * 0.04),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(w * 0.04),
                          child: LampiranViewer(
                            urls: widget.lampiranUrls,
                            accentColor: AppColors.orangePrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.025),
                    ],

                    _buildActionButtons(context, w, h),
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

  Widget _buildCatatanCard(double w, double h) {
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
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: AppColors.orangePrimary,
                  size: rf(18, w),
                ),
                SizedBox(width: w * 0.02),
                Text(
                  "Catatan Verifikasi",
                  style: TextStyle(
                    fontSize: rf(14, w),
                    fontWeight: FontWeight.bold,
                    color: AppColors.orangePrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: h * 0.015),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: h * 0.14),
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.03,
                vertical: h * 0.015,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: Text(
                widget.catatan.isEmpty ? "-" : widget.catatan,
                style: TextStyle(fontSize: rf(14, w)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, double w, double h) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, h * 0.055),
              side: const BorderSide(color: AppColors.orangePrimary, width: 1.2),
              foregroundColor: AppColors.orangePrimary,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.05,
                vertical: h * 0.014,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(w * 0.03),
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
            icon: Icon(Icons.remove_red_eye, size: rf(18, w)),
            label: Text(
              "Lihat Surat",
              style: TextStyle(
                fontSize: rf(14, w),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!widget.isReadOnly)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(0, h * 0.055),
                backgroundColor: AppColors.orangePrimary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.05,
                  vertical: h * 0.014,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Konfirmasi",
                style: TextStyle(
                  fontSize: rf(14, w),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}