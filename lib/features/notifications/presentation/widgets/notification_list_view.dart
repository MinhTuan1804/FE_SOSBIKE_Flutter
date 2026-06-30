import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_mechanic/find_mechanic_flow_page.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/notifications/data/models/notification_models.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/providers/notification_provider.dart';

String _safeDisplayText(String input) {
  var text = input.trim();
  if (text.isEmpty) return '';

  text = text.replaceAll(
    RegExp(r'#[A-Z0-9]+-\d{4}[A-Za-z0-9\-]*', caseSensitive: false),
    'mã giao dịch',
  );
  text = text.replaceAll(
    RegExp(r'\b[A-Z]{2,}-\d{4}[A-Za-z0-9\-]*\b', caseSensitive: false),
    'mã giao dịch',
  );
  text = text.replaceAll(
    RegExp(
      r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
    ),
    'mã tham chiếu',
  );
  if (text.contains('{') && text.contains('}')) {
    text = text.replaceAll(RegExp(r'\{[^{}]{20,}\}'), 'chi tiết hệ thống');
  }

  return text;
}

class NotificationListView extends StatefulWidget {
  const NotificationListView({super.key});

  @override
  State<NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;

    if (provider.isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && items.isEmpty) {
      return _EmptyState(
        message: provider.errorMessage!,
        onRetry: () => context.read<NotificationProvider>().refresh(),
      );
    }

    if (items.isEmpty) {
      return _EmptyState(
        message: 'Chưa có thông báo nào.',
        onRetry: () => context.read<NotificationProvider>().refresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<NotificationProvider>().refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12, indent: 80),
        itemBuilder: (context, index) {
          final item = items[index];
          return Dismissible(
            key: Key('notif-${item.notificationId}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
            ),
            onDismissed: (_) {
              context.read<NotificationProvider>().deleteNotification(item.notificationId);
            },
            child: _NotificationTile(
              item: item,
              onTap: () => _handleTap(context, item),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, NotificationItem item) async {
    await context.read<NotificationProvider>().markRead(item.notificationId);
    if (!context.mounted) return;

    final type = item.notificationType.toUpperCase();
    final auth = context.read<AuthProvider>();
    final isCustomer = auth.userType == 'CUSTOMER';

    if (isCustomer) {
      if (type == 'RESCUE_ORDER_ACCEPTED' || 
          type == 'RESCUE_ORDER_ARRIVED' || 
          type == 'RESCUE_ORDER_QUOTED' || 
          type == 'REPAIR_STARTED' || 
          type == 'REPAIR_COMPLETED') {
        final rescue = context.read<RescueProvider>();
        if (rescue.currentOrderId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FindMechanicFlowPage(),
            ),
          );
          return;
        }
      }
    }

    await _showDetailModal(context, item);
  }

  Future<void> _showDetailModal(BuildContext context, NotificationItem item) async {
    final style = _styleFor(item.notificationType);
    final createdAtText = _formatTime(item.createdAt);
    final payload = _decodePayload(item.payloadJson);
    final detailTitle = _friendlyTypeLabel(item.notificationType);
    final summary = _friendlySummary(item, payload);
    final detailCards = _buildDetailCards(item, payload);
    final safeTitle = _safeDisplayText(item.title);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.38,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: style.backgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(style.icon, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  safeTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  detailTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Chưa đọc',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoCard(
                        label: 'Tóm tắt',
                        value: summary,
                      ),
                      if (detailCards.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...detailCards,
                      ],
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Thời gian', value: createdAtText),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Đóng'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildDetailCards(NotificationItem item, Map<String, dynamic>? payload) {
    final type = item.notificationType.toUpperCase();
    final cards = <Widget>[];

    switch (type) {
      case 'CHAT_MESSAGE':
        final sender = _safeDisplayText(_stringFrom(payload, ['senderName', 'SenderName']));
        final preview = _safeDisplayText(_stringFrom(payload, ['preview', 'Preview']));
        if (sender.isNotEmpty) {
          cards.add(_InfoCard(label: 'Người gửi', value: sender));
        }
        if (preview.isNotEmpty) {
          cards.add(const SizedBox(height: 12));
          cards.add(_InfoCard(label: 'Tin nhắn', value: preview));
        }
        break;
      case 'RESCUE_ORDER_CREATED':
      case 'RESCUE_ORDER_ACCEPTED':
      case 'RESCUE_ORDER_ARRIVED':
      case 'RESCUE_ORDER_QUOTED':
      case 'REPAIR_STARTED':
      case 'REPAIR_COMPLETED':
      case 'RESCUE_ORDER_SETTLED':
        final amount = _numberFrom(payload, ['amount', 'Amount', 'totalAmount', 'TotalAmount', 'commissionAmount', 'CommissionAmount']);
        final status = _stringFrom(payload, ['status', 'Status']);
        final mechanicName = _safeDisplayText(_stringFrom(payload, ['mechanicName', 'MechanicName']));
        if (mechanicName.isNotEmpty) {
          cards.add(_InfoCard(label: 'Người liên quan', value: mechanicName));
        }
        if (status.isNotEmpty) {
          cards.add(const SizedBox(height: 12));
          cards.add(_InfoCard(label: 'Trạng thái', value: _friendlyStatus(status)));
        }
        if (amount != null) {
          cards.add(const SizedBox(height: 12));
          cards.add(_InfoCard(label: 'Giá trị', value: _formatMoney(amount)));
        }
        break;
      case 'PAYMENT_SUCCESS':
      case 'MEMBERSHIP_RENEWED':
      case 'MEMBERSHIP_EXPIRING':
      case 'MEMBERSHIP_AUTO_RENEW_DISABLED':
        final amount = _numberFrom(payload, ['amount', 'Amount']);
        final paymentCode = _stringFrom(payload, ['paymentCode', 'PaymentCode']);
        final planName = _safeDisplayText(_stringFrom(payload, ['planName', 'PlanName']));
        if (planName.isNotEmpty) {
          cards.add(_InfoCard(label: 'Gói áp dụng', value: planName));
        }
        if (amount != null) {
          cards.add(const SizedBox(height: 12));
          cards.add(_InfoCard(label: 'Số tiền', value: _formatMoney(amount)));
        }
        if (paymentCode.isNotEmpty) {
          cards.add(const SizedBox(height: 12));
          cards.add(_InfoCard(label: 'Mã giao dịch', value: _maskPaymentCode(paymentCode)));
        }
        break;
      case 'WITHDRAW_REQUEST_CREATED':
      case 'WITHDRAW_REQUEST_APPROVED':
      case 'WITHDRAW_REQUEST_REJECTED':
        final amount = _numberFrom(payload, ['amount', 'Amount']);
        final bankName = _safeDisplayText(_stringFrom(payload, ['bankName', 'BankName']));
        final accountNumber = _stringFrom(payload, ['accountNumber', 'AccountNumber']);
        final status = _stringFrom(payload, ['status', 'Status']);
        if (status.isNotEmpty) {
          cards.add(_InfoCard(label: 'Trạng thái', value: _friendlyStatus(status)));
        }
        if (amount != null) {
          cards.add(const SizedBox(height: 12));
          cards.add(_InfoCard(label: 'Số tiền', value: _formatMoney(amount)));
        }
        if (bankName.isNotEmpty) {
          cards.add(const SizedBox(height: 12));
          cards.add(_InfoCard(label: 'Ngân hàng', value: bankName));
        }
        if (accountNumber.isNotEmpty) {
          cards.add(const SizedBox(height: 12));
          cards.add(_InfoCard(label: 'Số tài khoản', value: _maskAccountNumber(accountNumber)));
        }
        break;
      default:
        final safeSummary = _buildGenericSummary(payload);
        if (safeSummary.isNotEmpty) {
          cards.add(_InfoCard(label: 'Chi tiết', value: safeSummary));
        }
        break;
    }

    return cards;
  }

  String _friendlySummary(NotificationItem item, Map<String, dynamic>? payload) {
    final type = item.notificationType.toUpperCase();
    switch (type) {
      case 'CHAT_MESSAGE':
        final sender = _safeDisplayText(_stringFrom(payload, ['senderName', 'SenderName']));
        final preview = _safeDisplayText(_stringFrom(payload, ['preview', 'Preview']));
        if (sender.isNotEmpty && preview.isNotEmpty) {
          return 'Tin nhắn mới từ $sender: $preview';
        }
        if (sender.isNotEmpty) {
          return 'Tin nhắn mới từ $sender.';
        }
        return 'Bạn vừa nhận được một tin nhắn mới.';
      case 'RESCUE_ORDER_CREATED':
        return 'Có đơn cứu hộ mới cần được xử lý.';
      case 'RESCUE_ORDER_ACCEPTED':
        final mechanicName = _safeDisplayText(_stringFrom(payload, ['mechanicName', 'MechanicName']));
        if (mechanicName.isNotEmpty) {
          return 'Thợ $mechanicName đã nhận đơn cứu hộ của bạn.';
        }
        return 'Đơn cứu hộ của bạn đã được nhận.';
      case 'RESCUE_ORDER_ARRIVED':
        return 'Thợ đã xác nhận đã đến nơi.';
      case 'RESCUE_ORDER_QUOTED':
        return 'Thợ đã gửi báo giá mới cho đơn của bạn.';
      case 'REPAIR_STARTED':
        return 'Thợ đã bắt đầu sửa chữa.';
      case 'REPAIR_COMPLETED':
        return 'Đơn sửa chữa đã hoàn tất.';
      case 'RESCUE_ORDER_SETTLED':
        return 'Đơn cứu hộ đã được quyết toán.';
      case 'PAYMENT_SUCCESS':
        final planName = _safeDisplayText(_stringFrom(payload, ['planName', 'PlanName']));
        if (planName.isNotEmpty) {
          return 'Thanh toán cho gói $planName đã hoàn tất.';
        }
        return 'Thanh toán đã hoàn tất thành công.';
      case 'WITHDRAW_REQUEST_CREATED':
        return 'Yêu cầu rút tiền của bạn đã được gửi.';
      case 'WITHDRAW_REQUEST_APPROVED':
        return 'Yêu cầu rút tiền đã được duyệt.';
      case 'WITHDRAW_REQUEST_REJECTED':
        return 'Yêu cầu rút tiền đã bị từ chối.';
      case 'MEMBERSHIP_RENEWED':
        final planName = _safeDisplayText(_stringFrom(payload, ['planName', 'PlanName']));
        if (planName.isNotEmpty) {
          return 'Gói thành viên $planName đã được kích hoạt.';
        }
        return 'Gói thành viên của bạn đã được kích hoạt.';
      case 'MEMBERSHIP_EXPIRING':
        return 'Gói thành viên sắp hết hạn.';
      case 'MEMBERSHIP_AUTO_RENEW_DISABLED':
        return 'Đã tắt tự động gia hạn gói thành viên.';
      case 'MECHANIC_PROFILE_SUBMITTED':
        return 'Hồ sơ thợ của bạn đã được gửi lên admin để xem xét.';
      case 'MECHANIC_PROFILE_APPROVED':
        return 'Hồ sơ thợ của bạn đã được admin xác nhận.';
      case 'MECHANIC_PROFILE_REJECTED':
        return 'Hồ sơ thợ của bạn chưa được duyệt và cần bổ sung.';
      default:
        return _safeDisplayText(item.content);
    }
  }

  Map<String, dynamic>? _decodePayload(String? payloadJson) {
    final raw = payloadJson?.trim();
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}

    return null;
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('HH:mm dd/MM', 'vi').format(time.toLocal());
  }

  String _friendlyTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'CHAT_MESSAGE':
        return 'Tin nhắn mới';
      case 'RESCUE_ORDER_CREATED':
        return 'Có đơn cứu hộ mới';
      case 'RESCUE_ORDER_ACCEPTED':
        return 'Đơn cứu hộ đã được nhận';
      case 'RESCUE_ORDER_ARRIVED':
        return 'Thợ đã đến nơi';
      case 'RESCUE_ORDER_QUOTED':
        return 'Đơn đã có báo giá';
      case 'REPAIR_STARTED':
        return 'Bắt đầu sửa chữa';
      case 'REPAIR_COMPLETED':
        return 'Sửa chữa hoàn tất';
      case 'RESCUE_ORDER_SETTLED':
        return 'Quyết toán đơn cứu hộ';
      case 'PAYMENT_SUCCESS':
        return 'Thanh toán thành công';
      case 'WITHDRAW_REQUEST_CREATED':
        return 'Yêu cầu rút tiền';
      case 'WITHDRAW_REQUEST_APPROVED':
        return 'Rút tiền đã duyệt';
      case 'WITHDRAW_REQUEST_REJECTED':
        return 'Rút tiền bị từ chối';
      case 'MEMBERSHIP_EXPIRING':
        return 'Gói thành viên sắp hết hạn';
      case 'MEMBERSHIP_RENEWED':
        return 'Gia hạn gói thành viên';
      case 'MEMBERSHIP_AUTO_RENEW_DISABLED':
        return 'Đã tắt tự động gia hạn';
      default:
        return 'Thông báo hệ thống';
    }
  }

  String _friendlyStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PENDING':
        return 'Đang chờ xử lý';
      case 'APPROVED':
        return 'Đã duyệt';
      case 'REJECTED':
        return 'Bị từ chối';
      case 'CANCELLED':
        return 'Đã huỷ';
      case 'COMPLETED':
        return 'Hoàn tất';
      case 'ACCEPTED':
        return 'Đã nhận';
      case 'ARRIVED':
        return 'Đã đến nơi';
      case 'QUOTING':
        return 'Đang báo giá';
      case 'REPAIRING':
        return 'Đang sửa chữa';
      case 'PAID':
        return 'Đã thanh toán';
      default:
        return _safeDisplayText(status);
    }
  }

  String _formatMoney(num? amount) {
    if (amount == null) return '';
    final value = NumberFormat('#,###', 'vi_VN').format(amount);
    return '$value đ';
  }

  String _maskPaymentCode(String code) {
    final clean = code.trim();
    if (clean.length <= 8) return 'Đã tạo';
    return '${clean.substring(0, 4)}****${clean.substring(clean.length - 4)}';
  }

  String _maskAccountNumber(String accountNumber) {
    final digits = accountNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '****';
    return '**** ${digits.substring(digits.length - 4)}';
  }

  String _buildGenericSummary(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) return '';
    final buffer = StringBuffer();
    final amount = _numberFrom(payload, const ['amount', 'Amount']);
    final status = _stringFrom(payload, const ['status', 'Status']);

    if (status.isNotEmpty) {
      buffer.write('Trạng thái: ${_friendlyStatus(status)}');
    }
    if (amount != null) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('Giá trị: ${_formatMoney(amount)}');
    }
    return buffer.toString();
  }

  String _stringFrom(Map<String, dynamic>? payload, List<String> keys) {
    if (payload == null) return '';
    for (final key in keys) {
      final value = payload[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  num? _numberFrom(Map<String, dynamic>? payload, List<String> keys) {
    if (payload == null) return null;
    for (final key in keys) {
      final value = payload[key];
      if (value is num) return value;
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(item.notificationType);
    final time = item.createdAt == null ? '' : DateFormat('HH:mm dd/MM', 'vi').format(item.createdAt!.toLocal());

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: style.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: Colors.white, size: 24),
                ),
                if (!item.isRead)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeDisplayText(item.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14.5,
                      fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _safeDisplayText(item.content),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.icon,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color backgroundColor;
}

_NotificationStyle _styleFor(String type) {
  switch (type.toUpperCase()) {
    case 'CHAT_MESSAGE':
      return const _NotificationStyle(icon: Icons.chat_bubble_outline_rounded, backgroundColor: Color(0xFF4B8BFF));
    case 'RESCUE_ORDER_CREATED':
    case 'RESCUE_ORDER_ACCEPTED':
    case 'RESCUE_ORDER_ARRIVED':
    case 'RESCUE_ORDER_QUOTED':
    case 'REPAIR_STARTED':
    case 'REPAIR_COMPLETED':
      return const _NotificationStyle(icon: Icons.construction_rounded, backgroundColor: Color(0xFFC02020));
    case 'PAYMENT_SUCCESS':
    case 'RESCUE_ORDER_SETTLED':
      return const _NotificationStyle(icon: Icons.account_balance_wallet_rounded, backgroundColor: Color(0xFF4CAF50));
    case 'WITHDRAW_REQUEST_CREATED':
    case 'WITHDRAW_REQUEST_APPROVED':
    case 'WITHDRAW_REQUEST_REJECTED':
      return const _NotificationStyle(icon: Icons.payments_rounded, backgroundColor: Color(0xFFFF9800));
    case 'MEMBERSHIP_EXPIRING':
    case 'MEMBERSHIP_RENEWED':
    case 'MEMBERSHIP_AUTO_RENEW_DISABLED':
      return const _NotificationStyle(icon: Icons.card_membership_rounded, backgroundColor: Color(0xFF7E57C2));
    case 'MECHANIC_PROFILE_SUBMITTED':
      return const _NotificationStyle(icon: Icons.pending_actions_rounded, backgroundColor: Color(0xFFFF9800));
    case 'MECHANIC_PROFILE_APPROVED':
      return const _NotificationStyle(icon: Icons.verified_rounded, backgroundColor: Color(0xFF4CAF50));
    case 'MECHANIC_PROFILE_REJECTED':
      return const _NotificationStyle(icon: Icons.error_outline_rounded, backgroundColor: Color(0xFFE53935));
    default:
      return const _NotificationStyle(icon: Icons.notifications_rounded, backgroundColor: Color(0xFFC02020));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 98,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF111827),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
