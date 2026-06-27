import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/notifications/data/models/notification_models.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/providers/notification_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';

class MechanicActivityNotificationsSection extends StatelessWidget {
  const MechanicActivityNotificationsSection({
    super.key,
    required this.items,
    required this.onRefresh,
  });

  final List<NotificationItem> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 100),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.notifications_none_rounded, size: 72, color: Color(0xFFD1D5DB)),
            SizedBox(height: 16),
            Text(
              'Chưa có thông báo phù hợp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => _handleTap(context, item),
            borderRadius: BorderRadius.circular(14),
            child: _NotificationTile(item: item),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, NotificationItem item) async {
    context.read<NotificationProvider>().markRead(item.notificationId);

    Map<String, dynamic>? payload;
    if (item.payloadJson != null && item.payloadJson!.trim().isNotEmpty) {
      try {
        final decoded = json.decode(item.payloadJson!);
        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    final type = item.notificationType.toUpperCase();
    if (type == 'RESCUE_ORDER_CREATED' && payload != null) {
      context.read<RescueProvider>().simulateIncomingRequest(payload);
    } else {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            item.title.trim().isEmpty ? 'Thông báo' : item.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            item.content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final style = _styleForNotification(item.notificationType);
    final title = _mechanicNotificationTitle(item);
    final subtitle = _mechanicNotificationSubtitle(item);
    final preview = _mechanicNotificationPreview(item);
    final timeLabel = _formatNotificationTime(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: style.backgroundColor, shape: BoxShape.circle),
            child: Icon(style.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                if (preview != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
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

_NotificationStyle _styleForNotification(String type) {
  switch (type.toUpperCase()) {
    case 'MECHANIC_PROFILE_SUBMITTED':
      return const _NotificationStyle(icon: Icons.pending_actions_rounded, backgroundColor: Color(0xFFFF9800));
    case 'MECHANIC_PROFILE_APPROVED':
      return const _NotificationStyle(icon: Icons.verified_rounded, backgroundColor: Color(0xFF4CAF50));
    case 'MECHANIC_PROFILE_REJECTED':
      return const _NotificationStyle(icon: Icons.error_outline_rounded, backgroundColor: Color(0xFFE53935));
    case 'MECHANIC_SERVICE_SUBMITTED':
      return const _NotificationStyle(icon: Icons.construction_rounded, backgroundColor: Color(0xFFFF9800));
    case 'MECHANIC_SERVICE_APPROVED':
      return const _NotificationStyle(icon: Icons.verified_rounded, backgroundColor: Color(0xFF4CAF50));
    case 'MECHANIC_SERVICE_REJECTED':
      return const _NotificationStyle(icon: Icons.cancel_outlined, backgroundColor: Color(0xFFE53935));
    case 'MAINTENANCE_REMINDER':
      return const _NotificationStyle(icon: Icons.event_note_rounded, backgroundColor: Color(0xFF2563EB));
    case 'ADMIN_ANNOUNCEMENT':
      return const _NotificationStyle(icon: Icons.campaign_rounded, backgroundColor: Color(0xFF7E57C2));
    case 'SYSTEM_MAINTENANCE':
      return const _NotificationStyle(icon: Icons.build_circle_rounded, backgroundColor: Color(0xFF6B7280));
    case 'WITHDRAW_REQUEST_CREATED':
    case 'WITHDRAW_REQUEST_APPROVED':
    case 'WITHDRAW_REQUEST_REJECTED':
      return const _NotificationStyle(icon: Icons.payments_rounded, backgroundColor: Color(0xFFFF9800));
    default:
      return const _NotificationStyle(icon: Icons.notifications_rounded, backgroundColor: Color(0xFFC02020));
  }
}

String _mechanicNotificationTitle(NotificationItem item) {
  switch (item.notificationType.toUpperCase()) {
    case 'MECHANIC_PROFILE_SUBMITTED':
      return 'Hồ sơ thợ đã được gửi';
    case 'MECHANIC_PROFILE_APPROVED':
      return 'Hồ sơ thợ đã được duyệt';
    case 'MECHANIC_PROFILE_REJECTED':
      return 'Hồ sơ thợ cần bổ sung';
    case 'MECHANIC_SERVICE_SUBMITTED':
      return 'Dịch vụ thợ đã gửi duyệt';
    case 'MECHANIC_SERVICE_APPROVED':
      return 'Dịch vụ thợ đã được duyệt';
    case 'MECHANIC_SERVICE_REJECTED':
      return 'Dịch vụ thợ bị từ chối';
    case 'MAINTENANCE_REMINDER':
      return 'Nhắc bảo dưỡng xe';
    case 'ADMIN_ANNOUNCEMENT':
      return 'Thông báo từ admin';
    case 'SYSTEM_MAINTENANCE':
      return 'Thông báo hệ thống';
    case 'WITHDRAW_REQUEST_CREATED':
      return 'Yêu cầu rút tiền mới';
    case 'WITHDRAW_REQUEST_APPROVED':
      return 'Rút tiền đã được duyệt';
    case 'WITHDRAW_REQUEST_REJECTED':
      return 'Rút tiền bị từ chối';
    default:
      return item.title.trim().isEmpty ? 'Thông báo mới' : item.title;
  }
}

String? _mechanicNotificationSubtitle(NotificationItem item) {
  switch (item.notificationType.toUpperCase()) {
    case 'MECHANIC_PROFILE_SUBMITTED':
      return 'Đang chờ admin xem xét';
    case 'MECHANIC_PROFILE_APPROVED':
      return 'Bạn có thể bắt đầu nhận đơn';
    case 'MECHANIC_PROFILE_REJECTED':
      return 'Vui lòng bổ sung thông tin còn thiếu';
    case 'MECHANIC_SERVICE_SUBMITTED':
      return 'Dịch vụ đang chờ duyệt';
    case 'MECHANIC_SERVICE_APPROVED':
      return 'Dịch vụ đã hiển thị trên app';
    case 'MECHANIC_SERVICE_REJECTED':
      return 'Cần chỉnh sửa lại nội dung dịch vụ';
    case 'WITHDRAW_REQUEST_CREATED':
      return 'Đã gửi yêu cầu rút tiền';
    case 'WITHDRAW_REQUEST_APPROVED':
      return 'Tiền sẽ được chuyển về ngân hàng';
    case 'WITHDRAW_REQUEST_REJECTED':
      return 'Vui lòng kiểm tra lại thông tin';
    default:
      return null;
  }
}

String? _mechanicNotificationPreview(NotificationItem item) {
  final content = item.content.trim();
  if (content.isEmpty) return null;
  return content;
}

String _formatNotificationTime(DateTime? createdAt) {
  if (createdAt == null) return '';
  return DateFormat('HH:mm dd/MM', 'vi').format(createdAt.toLocal());
}
