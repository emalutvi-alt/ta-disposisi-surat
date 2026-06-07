import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';

// ── ENUMS ─────────────────────────────────────────────────────────────────────

enum CardRole { tu, kepsek, users }

enum CardType { home, menu, history }

// ── WIDGET ────────────────────────────────────────────────────────────────────

class SuratCard extends StatelessWidget {
  final String jenisSurat;
  final String tanggal;
  final Map<String, String> data;
  final CardRole role;
  final CardType type;
  final String? status;
  final String? diteruskanKe;
  final VoidCallback onDetail;
  // Lampiran indicator — list of image URLs from the surat
  final List<String> lampiran;

  const SuratCard({
    super.key,
    required this.jenisSurat,
    required this.tanggal,
    required this.data,
    required this.role,
    required this.type,
    required this.onDetail,
    this.status,
    this.diteruskanKe,
    this.lampiran = const [],
  });

  // ── GETTERS ──────────────────────────────────────────────────────────────────

  bool get showStatus {
    // history: hanya TU dan kepsek yang lihat status
    if (isHistory) {
      return role == CardRole.tu || role == CardRole.kepsek;
    }
    // Menu: hanya TU yang lihat status
    if (isMenu) return role == CardRole.tu;

    // Home
    return role == CardRole.tu;
  }

  bool get isHome => type == CardType.home;
  bool get isHistory => type == CardType.history;
  bool get isMenu => type == CardType.menu;
  bool get showDiteruskanKe {
    if (!isHistory && !isMenu) return false;

    return role == CardRole.users &&
        diteruskanKe != null &&
        diteruskanKe!.isNotEmpty;
  }

  bool get hasLampiran => lampiran.isNotEmpty;

  // ── STATUS HELPERS ───────────────────────────────────────────────────────────

  String _label() {
    switch (status?.toLowerCase()) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'menunggu':
      case 'diproses':
        return 'Diproses';
      default:
        return '';
    }
  }

  Color _bgColor() {
    switch (status?.toLowerCase()) {
      case 'disetujui':
        return const Color(0xFFDDEEDC);
      case 'ditolak':
        return const Color(0xFFF4D6D8);
      case 'menunggu':
      case 'diproses':
        return const Color(0xFFF1E2BF);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _textColor() {
    switch (status?.toLowerCase()) {
      case 'disetujui':
        return const Color(0xFF2E7D32);
      case 'ditolak':
        return const Color(0xFFB4232C);
      case 'menunggu':
      case 'diproses':
        return const Color(0xFF8A6D1F);
      default:
        return Colors.grey;
    }
  }

  Color _accentColor() {
    return jenisSurat.toLowerCase() == 'surat keluar'
        ? AppColors.orangePrimary
        : AppColors.bluePrimary;
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // History & menu pakai left stroke, home tidak
    final bool hasStroke = isHistory || isMenu;

    return GestureDetector(
      onTap: isHome ? onDetail : null,
      child: Container(
        margin: EdgeInsets.only(bottom: w * 0.025),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: w * 0.05,
              offset: Offset(0, w * 0.025),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(w * 0.04),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left stroke — history & menu
                if (hasStroke)
                  Container(width: w * 0.015, color: _accentColor()),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hasStroke ? w * 0.03 : w * 0.045,
                      vertical: hasStroke ? w * 0.025 : w * 0.038,
                    ),
                    child: isHome
                        ? _buildHomeCard(w)
                        : isHistory
                        ? _buildHistoryCard(w)
                        : _buildMenuCard(w),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HOME CARD ────────────────────────────────────────────────────────────────

  Widget _buildHomeCard(double w) {
    final isMasuk = jenisSurat == 'Surat Masuk';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: w * 0.115,
          height: w * 0.115,
          decoration: BoxDecoration(
            color: isMasuk ? const Color(0xFFE7F6F8) : const Color(0xFFFFF1E3),
            borderRadius: BorderRadius.circular(w * 0.035),
          ),
          child: Center(
            child: SvgPicture.asset(
              isMasuk
                  ? 'assets/icons/ic_inmail.svg'
                  : 'assets/icons/ic_outmail.svg',
              width: w * 0.058,
              height: w * 0.058,
              colorFilter: ColorFilter.mode(
                isMasuk ? AppColors.bluePrimary : AppColors.orangePrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),

        SizedBox(width: w * 0.035),

        // Perihal & Dari
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data['Perihal'] ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: w * 0.042,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: w * 0.007),
              Text(
                data['Dari'] ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: w * 0.036,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: w * 0.02),

        // Kolom kanan: tanggal + badge
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: w * 0.042 * 1.4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  tanggal,
                  style: TextStyle(
                    fontSize: w * 0.036,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            SizedBox(height: w * 0.007),
            SizedBox(
              height: w * 0.036 * 1.4,
              child: Align(
                alignment: Alignment.centerRight,
                child: showStatus && status != null
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.03,
                          vertical: w * 0.004,
                        ),
                        decoration: BoxDecoration(
                          color: _bgColor(),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _label(),
                          style: TextStyle(
                            fontSize: w * 0.032,
                            fontWeight: FontWeight.w700,
                            color: _textColor(),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── HISTORY CARD ─────────────────────────────────────────────────────────────
  // Layout:
  //   [Icon + Jenis Surat + badge]  [tanggal]
  //   ─────────────────────────────────────
  //   [Perihal]                     [eye]
  //   [Dari   ]
  //   [lampiran indicator?]

  Widget _buildHistoryCard(double w) {
    final isMasuk = jenisSurat == 'Surat Masuk';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Baris atas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: w * 0.075,
                    height: w * 0.075,
                    decoration: BoxDecoration(
                      color: isMasuk
                          ? const Color(0xFFE7F6F8)
                          : const Color(0xFFFFF1E3),
                      borderRadius: BorderRadius.circular(w * 0.02),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        isMasuk
                            ? 'assets/icons/ic_inmail.svg'
                            : 'assets/icons/ic_outmail.svg',
                        width: w * 0.038,
                        height: w * 0.038,
                        colorFilter: ColorFilter.mode(
                          isMasuk
                              ? AppColors.bluePrimary
                              : AppColors.orangePrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.022),
                  Flexible(
                    child: Text(
                      jenisSurat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: w * 0.042,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (showStatus && status != null) ...[
                    SizedBox(width: w * 0.018),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.025,
                        vertical: w * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: _bgColor(),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _label(),
                        style: TextStyle(
                          fontSize: w * 0.030,
                          fontWeight: FontWeight.w700,
                          color: _textColor(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              tanggal,
              style: TextStyle(
                fontSize: w * 0.032,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),

        SizedBox(height: w * 0.018),
        Divider(height: 1, color: Colors.grey.shade100),
        SizedBox(height: w * 0.018),

        // Baris bawah: perihal + dari + eye button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data['Perihal'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.040,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    data['Dari'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.034,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (showDiteruskanKe) ...[
                    SizedBox(height: w * 0.012),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.022,
                        vertical: w * 0.007,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(w * 0.02),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: w * 0.036,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: w * 0.01),
                          Flexible(
                            child: Text(
                              'Untuk: ${diteruskanKe!}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: w * 0.031,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ── LAMPIRAN INDICATOR ────────────────────────────────────
                  if (hasLampiran) ...[
                    SizedBox(height: w * 0.012),
                    _buildLampiranIndicator(w),
                  ],
                ],
              ),
            ),

            SizedBox(width: w * 0.02),

            // Eye button
            GestureDetector(
              onTap: onDetail,
              child: Container(
                width: w * 0.09,
                height: w * 0.09,
                decoration: BoxDecoration(
                  color: _accentColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(w * 0.025),
                ),
                child: Center(
                  child: Icon(
                    Icons.remove_red_eye_rounded,
                    color: _accentColor(),
                    size: w * 0.048,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── MENU CARD ────────────────────────────────────────────────────────────────
  // Struktur sama persis dengan history card.
  // Beda: button Detail (ElevatedButton) menggantikan eye button.
  //
  // Layout:
  //   [Icon + Jenis Surat + badge]  [tanggal]
  //   ─────────────────────────────────────
  //   [Perihal                  ]   [Detail→]
  //   [Dari                     ]
  //   [chip diteruskanKe?       ]
  //   [lampiran indicator?      ]

  Widget _buildMenuCard(double w) {
    final isMasuk = jenisSurat == 'Surat Masuk';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Baris atas — sama dengan history
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: w * 0.075,
                    height: w * 0.075,
                    decoration: BoxDecoration(
                      color: isMasuk
                          ? const Color(0xFFE7F6F8)
                          : const Color(0xFFFFF1E3),
                      borderRadius: BorderRadius.circular(w * 0.02),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        isMasuk
                            ? 'assets/icons/ic_inmail.svg'
                            : 'assets/icons/ic_outmail.svg',
                        width: w * 0.038,
                        height: w * 0.038,
                        colorFilter: ColorFilter.mode(
                          isMasuk
                              ? AppColors.bluePrimary
                              : AppColors.orangePrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.022),
                  Flexible(
                    child: Text(
                      jenisSurat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: w * 0.042,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (showStatus && status != null) ...[
                    SizedBox(width: w * 0.018),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.025,
                        vertical: w * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: _bgColor(),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _label(),
                        style: TextStyle(
                          fontSize: w * 0.030,
                          fontWeight: FontWeight.w700,
                          color: _textColor(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              tanggal,
              style: TextStyle(
                fontSize: w * 0.032,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),

        SizedBox(height: w * 0.018),
        Divider(height: 1, color: Colors.grey.shade100),
        SizedBox(height: w * 0.018),

        // Baris bawah: perihal + dari + chip + Detail button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data['Perihal'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.040,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    data['Dari'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.034,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (showDiteruskanKe) ...[
                    SizedBox(height: w * 0.012),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.022,
                        vertical: w * 0.007,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(w * 0.02),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: w * 0.036,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: w * 0.01),
                          Flexible(
                            child: Text(
                              'Untuk: ${diteruskanKe!}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: w * 0.031,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ── LAMPIRAN INDICATOR ────────────────────────────────────
                  if (hasLampiran) ...[
                    SizedBox(height: w * 0.012),
                    _buildLampiranIndicator(w),
                  ],
                ],
              ),
            ),

            SizedBox(width: w * 0.02),

            // Detail button
            ElevatedButton(
              onPressed: onDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor(),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size(0, w * 0.085),
                padding: EdgeInsets.symmetric(horizontal: w * 0.034),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.022),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detail',
                    style: TextStyle(
                      fontSize: w * 0.035,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: w * 0.008),
                  Icon(Icons.arrow_forward_rounded, size: w * 0.035),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── LAMPIRAN INDICATOR ────────────────────────────────────────────────────────
  // Chip kecil yang menampilkan jumlah halaman/lampiran surat.
  // Menggunakan mainAxisSize.min + overflow-safe agar tidak overflow.

  Widget _buildLampiranIndicator(double w) {
    final color = _accentColor();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.022,
        vertical: w * 0.007,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.02),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: w * 0.036,
            color: color,
          ),
          SizedBox(width: w * 0.01),
          Text(
            '${lampiran.length} Halaman Surat',
            style: TextStyle(
              fontSize: w * 0.031,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
