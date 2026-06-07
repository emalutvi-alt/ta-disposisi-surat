import 'package:flutter/material.dart';

void showProcessDialog(BuildContext context) {
  final w = MediaQuery.of(context).size.width;

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFFF3F0F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: w * 0.20), 
        child: Padding(
          padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.08, w * 0.06, w * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.10,
                height: w * 0.10,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A4A4A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: w * 0.05,
                ),
              ),

              SizedBox(height: w * 0.04),

              Text(
                "Surat Dalam Proses",
                style: TextStyle(
                  fontSize: (w * 0.045).clamp(15.0, 18.0),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: w * 0.02),

              Text(
                "Surat masih dalam proses\npengajuan.",
                style: TextStyle(
                  fontSize: (w * 0.036).clamp(12.0, 15.0),
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ],
          ),
        ),
      );
    },
  );
}