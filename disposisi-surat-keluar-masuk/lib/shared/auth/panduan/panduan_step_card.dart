import 'package:flutter/material.dart';
import 'panduan_step.dart';

class PanduanStepCard extends StatelessWidget {
  final PanduanStepData step;
  final int stepNumber;
  final int totalSteps;
  final Widget preview;

  const PanduanStepCard({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.preview,
  });

  static const Color _primary = Color(0xFF0F6E7A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(step.icon, color: _primary, size: 26),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$stepNumber / $totalSteps',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 18),

          preview,
        ],
      ),
    );
  }
}
