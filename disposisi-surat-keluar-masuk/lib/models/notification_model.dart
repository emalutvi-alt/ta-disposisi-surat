import 'package:flutter/material.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final int referenceId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.referenceId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      isRead: json['is_read'] == true,
      referenceId: (json['reference_id'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Map ke format UI NotificationPage yang sudah ada.
  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'title': title,
      'desc': message,
      'color': _colorForType(type),
      'isRead': isRead,
      'createdAt': createdAt,
      'type': type,
      'referenceId': referenceId,
    };
  }

  Color _colorForType(String t) {
    switch (t) {
      case 'disposisi':
        return Colors.blue;
      case 'approval':
        return Colors.orange;
      case 'distribusi':
        return Colors.teal;
      case 'surat_masuk':
      case 'surat_keluar':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class NotificationListResult {
  final List<NotificationModel> items;
  final int unreadCount;

  NotificationListResult({required this.items, required this.unreadCount});

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return NotificationListResult(
      items: raw
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}
