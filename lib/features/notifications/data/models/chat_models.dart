class ChatConversation {
  const ChatConversation({
    required this.orderId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.status,
  });

  final String orderId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String status;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      orderId: json['orderId']?.toString() ?? '',
      otherUserId: json['otherUserId']?.toString() ?? '',
      otherUserName: json['otherUserName']?.toString() ?? '',
      otherUserAvatarUrl: json['otherUserAvatarUrl']?.toString(),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: _asDateOrNull(json['lastMessageAt']),
      unreadCount: _asInt(json['unreadCount']),
      status: json['status']?.toString() ?? '',
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  final String messageId;
  final String orderId;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderAvatarUrl: json['senderAvatarUrl']?.toString(),
      content: json['content']?.toString() ?? '',
      createdAt: _asDateOrNull(json['createdAt']) ?? DateTime.now(),
      isMine: json['isMine'] == true,
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
