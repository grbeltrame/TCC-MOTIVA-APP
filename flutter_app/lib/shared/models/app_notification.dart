import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/shared/models/profile_option.dart';

enum AppNotificationRole {
  athlete('athlete'),
  coach('coach');

  final String value;
  const AppNotificationRole(this.value);

  static AppNotificationRole fromValue(String? value) {
    return switch (value) {
      'coach' => AppNotificationRole.coach,
      _ => AppNotificationRole.athlete,
    };
  }

  String get prefix {
    return switch (this) {
      AppNotificationRole.athlete => '[atleta]',
      AppNotificationRole.coach => '[coach]',
    };
  }
}

class AppNotification {
  final String id;
  final AppNotificationRole role;
  final String type;
  final String title;
  final String body;
  final String status;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String? routeName;
  final Map<String, dynamic> routeArgs;
  final String? sourceId;

  const AppNotification({
    required this.id,
    required this.role,
    required this.type,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.readAt,
    required this.routeName,
    required this.routeArgs,
    required this.sourceId,
  });

  bool get isUnread => status != 'read';

  String displayTitle(String? profileType) {
    if (!profileTypeIsHybrid(profileType)) return title;
    if (title.startsWith(role.prefix)) return title;
    return '${role.prefix} $title';
  }

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      role: AppNotificationRole.fromValue(data['role'] as String?),
      type: (data['type'] as String?) ?? 'general',
      title: (data['title'] as String?) ?? 'Notificacao',
      body: (data['body'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'unread',
      createdAt: _timestampToDate(data['createdAt']),
      readAt: _timestampToDate(data['readAt']),
      routeName: data['routeName'] as String?,
      routeArgs: _mapFromDynamic(data['routeArgs']),
      sourceId: data['sourceId'] as String?,
    );
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static Map<String, dynamic> _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return const {};
  }
}
