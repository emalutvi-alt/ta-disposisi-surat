import 'package:flutter/material.dart';

/// Frame mini-mockup: non-interaktif, clipped, shadow halus.
class PanduanAppPreviewFrame extends StatelessWidget {
  final Widget child;
  final double logicalWidth;
  final double logicalHeight;
  final double frameHeight;
  final Alignment alignment;

  const PanduanAppPreviewFrame({
    super.key,
    required this.child,
    this.logicalWidth = 375,
    this.logicalHeight = 640,
    this.frameHeight = 260,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: frameHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: alignment, // ← pakai parameter
          child: SizedBox(
            width: logicalWidth,
            height: logicalHeight,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(logicalWidth, logicalHeight),
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                textScaler: TextScaler.noScaling,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
