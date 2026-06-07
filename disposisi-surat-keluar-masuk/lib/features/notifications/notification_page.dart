import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/role.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';
import 'package:ta_mobile_disposisi_surat/services/notification_service.dart';

// ── MAIN PAGE ─────────────────────────────────────────────────────────────────

class NotificationPage extends StatefulWidget {
  final Role role;
  final List<Map<String, dynamic>> notifications;

  const NotificationPage({
    super.key,
    required this.role,
    required this.notifications,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  late List<Map<String, dynamic>> _items;
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    _items = widget.notifications
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupNotifications();

    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    double rf(double size) {
      return (w * (size / 375)).clamp(size * 0.9, size * 1.2);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.03),

              _buildHeader(context, rf, w),

              SizedBox(height: h * 0.025),

              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada notifikasi',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: rf(15),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.only(bottom: h * 0.02),
                        children: grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: rf(14),
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              SizedBox(height: h * 0.01),

                              ...entry.value.map(
                                (notif) => _NotificationCard(
                                  title: notif['title'],
                                  desc: notif['desc'],
                                  color: notif['color'],
                                  isRead: notif['isRead'] == true,
                                  onTap: () => _onTapNotification(notif),
                                ),
                              ),

                              SizedBox(height: h * 0.01),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }


// ── HELPERS ──────────────────────────────────────────────────────────────────

Map<String, List<Map<String, dynamic>>> _groupNotifications() {
  final Map<String, List<Map<String, dynamic>>> grouped = {};

  for (final notif in _items) {
    final rawDate = notif['createdAt'];

    final date = rawDate is DateTime
        ? rawDate
        : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();

    final group = _timeGroup(date);

    grouped.putIfAbsent(group, () => []).add(notif);
  }

  return grouped;
}

String _timeGroup(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;

  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  return 'Sebelumnya';
}

  Future<void> _onTapNotification(Map<String, dynamic> notif) async {
    if (_marking || notif['isRead'] == true) return;

    final id = (notif['id'] as num?)?.toInt();
    if (id == null) return;

    setState(() => _marking = true);
    try {
      await _notificationService.markAsRead(id);
      if (!mounted) return;
      setState(() {
        notif['isRead'] = true;
      });
    } catch (e) {
      if (!mounted) return;
      final message =
          e is ApiException ? e.message : 'Gagal menandai notifikasi dibaca';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _marking = false);
      }
    }
  }

  Widget _buildHeader(
    BuildContext context,
    double Function(double) rf,
    double w,
  ) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.bluePrimary,
            size: rf(22),
          ),
        ),

        SizedBox(width: w * 0.025),

        Expanded(
          child: Text(
            'Notifikasi',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rf(24),
              fontWeight: FontWeight.bold,
              color: AppColors.bluePrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── NOTIFICATION CARD ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final String title;
  final String desc;
  final Color color;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.desc,
    required this.color,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    double rf(double size) {
      return (w * (size / 375)).clamp(size * 0.9, size * 1.2);
    }

    final radius = rf(14);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: h * 0.012),
        // Outer: border + radius
        decoration: BoxDecoration(
          color: isRead ? Colors.white : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.black.withValues(alpha: 0.07), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                if (!isRead) Container(width: rf(3.5), color: color),

                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(rf(14)),
                    child: Stack(
                      children: [
                        // Dot indicator
                        if (!isRead)
                          Positioned(
                            right: 0,
                            top: 2,
                            child: Container(
                              width: rf(8),
                              height: rf(8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                        Padding(
                          padding: EdgeInsets.only(right: w * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: rf(14),
                                  fontWeight: isRead
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                  color: isRead ? Colors.black54 : Colors.black87,
                                  height: 1.3,
                                ),
                              ),

                              SizedBox(height: h * 0.006),

                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: rf(12.5),
                                  height: 1.5,
                                  color: isRead ? Colors.black38 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
