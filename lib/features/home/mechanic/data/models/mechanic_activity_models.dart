
class MechanicAppointment {
  const MechanicAppointment({
    required this.id,
    required this.scheduledAt,
    required this.customerName,
    this.avatarUrl,
    required this.vehicleLabel,
    required this.bookedAt,
    required this.packageName,
    required this.maintenanceRound,
  });

  final String id;
  final DateTime scheduledAt;
  final String customerName;
  final String? avatarUrl;
  final String vehicleLabel;
  final DateTime bookedAt;
  final String packageName;
  final int maintenanceRound;

  String get dateBadgeLabel {
    final h = scheduledAt.hour;
    return '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} (${h}h)';
  }

  String get bookedAtLabel {
    final t = bookedAt;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  bool isSameDay(DateTime day) =>
      scheduledAt.year == day.year && scheduledAt.month == day.month && scheduledAt.day == day.day;

  static List<MechanicAppointment> get sample => [
        MechanicAppointment(
          id: 'apt-1',
          scheduledAt: DateTime(2026, 3, 18, 17),
          customerName: 'Trần Khánh Linh',
          avatarUrl: null,
          vehicleLabel: 'Honda SH 150i - 59-P1 123.45',
          bookedAt: DateTime(2026, 3, 17, 0, 34),
          packageName: 'Gói cao cấp',
          maintenanceRound: 2,
        ),
        MechanicAppointment(
          id: 'apt-2',
          scheduledAt: DateTime(2026, 3, 22, 9),
          customerName: 'Nguyễn Minh An',
          vehicleLabel: 'Yamaha Exciter 155 - 59-F1 888.88',
          bookedAt: DateTime(2026, 3, 20, 14, 12),
          packageName: 'Gói phổ thông',
          maintenanceRound: 1,
        ),
      ];
}

enum MechanicActivityNotificationKind { review, message }

class MechanicActivityNotification {
  const MechanicActivityNotification({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.preview,
    required this.timeLabel,
  });

  final String id;
  final MechanicActivityNotificationKind kind;
  final String title;
  final String? subtitle;
  final String? preview;
  final String timeLabel;

  static List<MechanicActivityNotification> get sample => const [
        MechanicActivityNotification(
          id: 'n1',
          kind: MechanicActivityNotificationKind.review,
          title: 'Đánh giá trải nghiệm sửa xe lưu động',
          subtitle: 'Đoàn Danh Thư',
          timeLabel: '13:50 T7',
        ),
        MechanicActivityNotification(
          id: 'n2',
          kind: MechanicActivityNotificationKind.message,
          title: 'Tin nhắn từ - Trần Đăng Khoa',
          preview: 'Tôi muốn kiểm tra lại phần cổ xe...',
          timeLabel: '16:50 T2',
        ),
        MechanicActivityNotification(
          id: 'n3',
          kind: MechanicActivityNotificationKind.review,
          title: 'Đánh giá trải nghiệm sửa xe lưu động',
          subtitle: 'Trần Khánh Linh',
          timeLabel: '09:20 T4',
        ),
        MechanicActivityNotification(
          id: 'n4',
          kind: MechanicActivityNotificationKind.message,
          title: 'Tin nhắn từ - Lê Hoàng Nam',
          preview: 'Anh có thể đến sớm 30 phút được không?',
          timeLabel: '08:15 T3',
        ),
      ];
}
