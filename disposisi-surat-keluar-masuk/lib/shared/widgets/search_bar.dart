import 'package:flutter/material.dart';

class SearchBarInput extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final double? fontSize;

  const SearchBarInput({
    super.key,
    this.hintText = 'Cari surat...',
    required this.onChanged,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final fs = fontSize ?? (w * 0.038).clamp(13.0, 17.0);

    return Container(
      height: (w * 0.128).clamp(44.0, 56.0),           // lebih tinggi, radius tetap 14
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E5EA), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.035),
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFFB0B7C3),
              size: w * 0.055,
            ),
          ),

          // ── TextField ─────────────────────────────────────────────────
          Expanded(
            child: TextField(
              onChanged: onChanged,
              textAlign: TextAlign.left,             // hint & input kiri
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(fontSize: fs, height: 1.0),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Color(0xFFADB5BD),
                  fontSize: fs,
                  height: 1.0,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),

          SizedBox(width: w * 0.035),
        ],
      ),
    );
  }
}