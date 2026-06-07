import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';

class CustomNavbar extends StatelessWidget {
  final Role role;
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavbar({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    double rf(double size) {
      return (w * (size / 375)).clamp(size * 0.80, size * 1.30);
    }

    return Padding(
      padding: EdgeInsets.only(
        left: rf(16),
        right: rf(16),
        bottom: rf(12),
      ),
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(rf(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: rf(62),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _navIcon(context, rf, 'assets/icons/ic_home.svg', 0)),
              Expanded(child: _navIcon(context, rf, 'assets/icons/ic_history.svg', 1)),
              Expanded(child: _navIcon(context, rf, 'assets/icons/ic_profile.svg', 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon(
    BuildContext context,
    double Function(double) rf,
    String asset,
    int index,
  ) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1, end: isActive ? 1.1 : 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, scale, _) {
          return Transform.scale(
            scale: scale,
            child: SvgPicture.asset(
              asset,
              width: rf(22),
              height: rf(22),
              colorFilter: ColorFilter.mode(
                isActive
                    ? const Color(0xFF2E8BC0)
                    : const Color(0xFF9FB8C2),
                BlendMode.srcIn,
              ),
            ),
          );
        },
      ),
    );
  }
}