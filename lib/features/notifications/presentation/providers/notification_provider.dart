import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/core/network/error_message.dart';
import 'package:fe_moblie_flutter/features/notifications/data/models/notification_models.dart';
import 'package:fe_moblie_flutter/features/notifications/data/repositories/notification_repository.dart';
import 'package:fe_moblie_flutter/features/notifications/data/services/notification_realtime_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repository, this._realtimeService);

  final NotificationRepository _repository;
  final NotificationRealtimeService _realtimeService;

  StreamSubscription<NotificationItem>? _realtimeSub;
  String? _sessionUserId;

  List<NotificationItem> _items = [];
  bool _isLoading = false;
  bool _isMarkingAllRead = false;
  String? _errorMessage;
  int _unreadCount = 0;

  List<NotificationItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isMarkingAllRead => _isMarkingAllRead;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  Future<void> load({bool unreadOnly = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ensureRealtimeStarted();
      _items = await _repository.getNotifications(unreadOnly: unreadOnly);
      _unreadCount = await _repository.getUnreadCount();
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(unreadOnly: false);

  Future<void> markRead(int notificationId) async {
    final index = _items.indexWhere((item) => item.notificationId == notificationId);
    final wasUnread = index != -1 && !_items[index].isRead;

    try {
      await _repository.markRead(notificationId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(isRead: true);
        if (wasUnread && _unreadCount > 0) {
          _unreadCount -= 1;
        }
      }
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (_isMarkingAllRead) return;

    _isMarkingAllRead = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.markAllRead();
      _items = _items.map((item) => item.copyWith(isRead: true)).toList();
      _unreadCount = 0;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
    } finally {
      _isMarkingAllRead = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    _items = [];
    _unreadCount = 0;
    _errorMessage = null;
    _sessionUserId = null;
    await _realtimeService.disconnect();
    notifyListeners();
  }

  void applyRealtime(NotificationItem item) {
    final index = _items.indexWhere((current) => current.notificationId == item.notificationId);
    if (index != -1) {
      _items[index] = item;
    } else {
      _items = [item, ..._items];
      if (!item.isRead) {
        _unreadCount += 1;
      }
    }
    notifyListeners();
  }

  Future<void> _ensureRealtimeStarted() async {
    final currentUserId = await _realtimeService.getCurrentUserId();
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    if (_sessionUserId != currentUserId) {
      _sessionUserId = currentUserId;
      _items = [];
      _unreadCount = 0;
      await _realtimeService.disconnect();
    }

    _realtimeSub ??= _realtimeService.notifications.listen(applyRealtime);

    await _realtimeService.connect();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
    unawaited(_realtimeService.disconnect());
    super.dispose();
  }
}
