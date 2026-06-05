class NotificationItem {
  const NotificationItem({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.content,
    required this.notificationType,
    this.referenceId,
    this.entityType,
    this.actionUrl,
    this.payloadJson,
    required this.isRead,
    this.createdAt,
  });

  final int notificationId;
  final String userId;
  final String title;
  final String content;
  final String notificationType;
  final String? referenceId;
  final String? entityType;
  final String? actionUrl;
  final String? payloadJson;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: _asInt(json['notificationId'] ?? json['NotificationId']),
      userId: json['userId']?.toString() ?? json['UserId']?.toString() ?? '',
      title: json['title']?.toString() ?? json['Title']?.toString() ?? '',
      content: json['content']?.toString() ?? json['Content']?.toString() ?? '',
      notificationType: json['notificationType']?.toString() ?? json['NotificationType']?.toString() ?? '',
      referenceId: json['referenceId']?.toString() ?? json['ReferenceId']?.toString(),
      entityType: json['entityType']?.toString() ?? json['EntityType']?.toString(),
      actionUrl: json['actionUrl']?.toString() ?? json['ActionUrl']?.toString(),
      payloadJson: json['payloadJson']?.toString() ?? json['PayloadJson']?.toString(),
      isRead: json['isRead'] == true || json['IsRead'] == true,
      createdAt: _asDateOrNull(json['createdAt'] ?? json['CreatedAt']),
    );
  }

  NotificationItem copyWith({
    int? notificationId,
    String? userId,
    String? title,
    String? content,
    String? notificationType,
    String? referenceId,
    String? entityType,
    String? actionUrl,
    String? payloadJson,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      notificationType: notificationType ?? this.notificationType,
      referenceId: referenceId ?? this.referenceId,
      entityType: entityType ?? this.entityType,
      actionUrl: actionUrl ?? this.actionUrl,
      payloadJson: payloadJson ?? this.payloadJson,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _asDateOrNull(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}
