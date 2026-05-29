import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/core/network/error_message.dart';
import 'dart:async';
import 'package:fe_moblie_flutter/features/notifications/data/models/chat_models.dart';
import 'package:fe_moblie_flutter/features/notifications/data/repositories/chat_repository.dart';
import 'package:fe_moblie_flutter/features/notifications/data/services/chat_realtime_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this._repository, this._realtimeService);

  final ChatRepository _repository;
  final ChatRealtimeService _realtimeService;
  StreamSubscription<ChatMessage>? _realtimeSub;

  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _activeOrderId;
  String? _currentUserId;

  List<ChatConversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String? get activeOrderId => _activeOrderId;

  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations = await _repository.getConversations();
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String orderId) async {
    _activeOrderId = orderId;
    _isLoadingMessages = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await _repository.getMessages(orderId);
      _currentUserId ??= await _realtimeService.getCurrentUserId();
      await _startRealtime(orderId);
      await _markReadInternal(orderId);
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String orderId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _repository.sendMessage(orderId, trimmed);
      _appendMessageIfNeeded(message);
      _updateConversationAfterSend(orderId, message);
      return true;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String orderId) async {
    await _markReadInternal(orderId);
    notifyListeners();
  }

  Future<void> _markReadInternal(String orderId) async {
    try {
      await _repository.markRead(orderId);
      _conversations = _conversations
          .map((item) => item.orderId == orderId
              ? ChatConversation(
                  orderId: item.orderId,
                  otherUserId: item.otherUserId,
                  otherUserName: item.otherUserName,
                  otherUserAvatarUrl: item.otherUserAvatarUrl,
                  lastMessage: item.lastMessage,
                  lastMessageAt: item.lastMessageAt,
                  unreadCount: 0,
                  status: item.status,
                )
              : item)
          .toList();
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
    }
  }

  void _updateConversationAfterSend(String orderId, ChatMessage message) {
    final index = _conversations.indexWhere((item) => item.orderId == orderId);
    if (index == -1) return;

    final current = _conversations[index];
    _conversations[index] = ChatConversation(
      orderId: current.orderId,
      otherUserId: current.otherUserId,
      otherUserName: current.otherUserName,
      otherUserAvatarUrl: current.otherUserAvatarUrl,
      lastMessage: message.content,
      lastMessageAt: message.createdAt,
      unreadCount: 0,
      status: current.status,
    );
  }

  Future<void> _startRealtime(String orderId) async {
    if (_realtimeSub == null) {
      _realtimeSub = _realtimeService.messages.listen(_handleRealtimeMessage);
    }
    await _realtimeService.connect();
    await _realtimeService.joinOrder(orderId);
  }

  void _handleRealtimeMessage(ChatMessage message) {
    final normalized = _normalizeMineFlag(message);
    if (_activeOrderId == normalized.orderId) {
      _appendMessageIfNeeded(normalized);
    }

    final index = _conversations.indexWhere((item) => item.orderId == normalized.orderId);
    if (index == -1) {
      loadConversations();
      return;
    }

    final current = _conversations[index];
    final unread = normalized.isMine ? 0 : (current.unreadCount + 1);
    _conversations[index] = ChatConversation(
      orderId: current.orderId,
      otherUserId: current.otherUserId,
      otherUserName: current.otherUserName,
      otherUserAvatarUrl: current.otherUserAvatarUrl,
      lastMessage: normalized.content,
      lastMessageAt: normalized.createdAt,
      unreadCount: unread,
      status: current.status,
    );

    notifyListeners();
  }

  void _appendMessageIfNeeded(ChatMessage message) {
    if (_activeOrderId != message.orderId) return;
    if (_messages.any((m) => m.messageId == message.messageId)) return;
    _messages = [..._messages, message];
  }

  ChatMessage _normalizeMineFlag(ChatMessage message) {
    if (_currentUserId == null || _currentUserId!.isEmpty) return message;
    final isMine = message.senderId == _currentUserId;
    if (isMine == message.isMine) return message;
    return ChatMessage(
      messageId: message.messageId,
      orderId: message.orderId,
      senderId: message.senderId,
      senderRole: message.senderRole,
      senderName: message.senderName,
      senderAvatarUrl: message.senderAvatarUrl,
      content: message.content,
      createdAt: message.createdAt,
      isMine: isMine,
    );
  }
}
