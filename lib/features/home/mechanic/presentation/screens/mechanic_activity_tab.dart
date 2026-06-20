import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_activity_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_services_tab.dart';

enum _ActivitySection { schedule, notifications, services }

/// Tab **Bảo Trì → Hoạt Động** — Đặt lịch + Thông báo (Figma).
class MechanicActivityTab extends StatefulWidget {
  const MechanicActivityTab({super.key, this.previewOnly = false});

  /// Xem preview dưới [ComingSoonOverlay] — không hiện dialog nhắc lịch.
  final bool previewOnly;

  @override
  State<MechanicActivityTab> createState() => _MechanicActivityTabState();
}

class _MechanicActivityTabState extends State<MechanicActivityTab> {
  _ActivitySection _section = _ActivitySection.schedule;
  DateTime _focusedMonth = DateTime(2026, 3);
  late DateTime _selectedDay;
  bool _reminderShown = false;

  final _appointments = MechanicAppointment.sample;
  final _notifications = MechanicActivityNotification.sample;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(2026, 3, 18);
    if (!widget.previewOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowReminder());
    }
  }

  void _maybeShowReminder() {
    if (!mounted || _reminderShown || _section != _ActivitySection.schedule) return;
    MechanicAppointment? todayAppt;
    for (final apt in _appointments) {
      if (apt.isSameDay(_selectedDay)) {
        todayAppt = apt;
        break;
      }
    }
    if (todayAppt == null) return;
    final appt = todayAppt;
    _reminderShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AppointmentReminderDialog(
        hourLabel: '${appt.scheduledAt.hour}h chiều nay!',
        onConfirm: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  MechanicAppointment? _appointmentForDay(DateTime day) {
    for (final apt in _appointments) {
      if (apt.isSameDay(day)) return apt;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 10),
          child: const Text(
            'Hoạt Động',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _SectionToggle(
            section: _section,
            onChanged: (value) {
              setState(() => _section = value);
              if (value == _ActivitySection.schedule) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowReminder());
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: switch (_section) {
              _ActivitySection.schedule => _ScheduleSection(
                  focusedMonth: _focusedMonth,
                  selectedDay: _selectedDay,
                  appointments: _appointments,
                  onMonthChanged: (month) => setState(() => _focusedMonth = month),
                  onDaySelected: (day) => setState(() => _selectedDay = day),
                  selectedAppointment: _appointmentForDay(_selectedDay),
                ),
              _ActivitySection.notifications => _NotificationsSection(items: _notifications),
              _ActivitySection.services => const MechanicServicesTab(isLightTheme: true),
            },
          ),
        ),
      ],
    );
  }
}

class _SectionToggle extends StatelessWidget {
  const _SectionToggle({required this.section, required this.onChanged});

  final _ActivitySection section;
  final ValueChanged<_ActivitySection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Đặt lịch',
            selected: section == _ActivitySection.schedule,
            onTap: () => onChanged(_ActivitySection.schedule),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleChip(
            label: 'Thông báo',
            selected: section == _ActivitySection.notifications,
            onTap: () => onChanged(_ActivitySection.notifications),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleChip(
            label: 'Dịch vụ',
            selected: section == _ActivitySection.services,
            onTap: () => onChanged(_ActivitySection.services),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xFFCCCCCC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.focusedMonth,
    required this.selectedDay,
    required this.appointments,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.selectedAppointment,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<MechanicAppointment> appointments;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;
  final MechanicAppointment? selectedAppointment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: _MonthCalendar(
              focusedMonth: focusedMonth,
              selectedDay: selectedDay,
              appointmentDays: appointments.map((a) => a.scheduledAt).toList(),
              onMonthChanged: onMonthChanged,
              onDaySelected: onDaySelected,
            ),
          ),
        ),
        if (selectedAppointment != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _AppointmentCard(appointment: selectedAppointment!),
          ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.focusedMonth,
    required this.selectedDay,
    required this.appointmentDays,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<DateTime> appointmentDays;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  static const _weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  bool _hasAppointment(DateTime day) {
    return appointmentDays.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = first.weekday % 7;
    final cells = <Widget>[];

    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final selected = _isSameDay(date, selectedDay);
      final hasAppt = _hasAppointment(date);
      cells.add(
        GestureDetector(
          onTap: () => onDaySelected(date),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF374151),
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: hasAppt ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month - 1)),
              icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF374151)),
            ),
            Expanded(
              child: Text(
                'Thg ${focusedMonth.month}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            IconButton(
              onPressed: () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + 1)),
              icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF374151)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: _weekdays
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 2,
          children: cells,
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final MechanicAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              appointment.dateBadgeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CustomerAvatar(name: appointment.customerName, avatarUrl: appointment.avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  appointment.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            appointment.vehicleLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _DetailLine(label: 'Khách hàng đã đặt lịch lúc:', value: appointment.bookedAtLabel),
          _DetailLine(label: appointment.packageName),
          _DetailLine(label: 'Chữa định kì lần: ${appointment.maintenanceRound}'),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          children: [
            TextSpan(text: label),
            if (value != null)
              TextSpan(
                text: ' $value',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE5E7EB),
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? CachedNetworkImageProvider(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF374151)))
          : null,
    );
  }
}

class _AppointmentReminderDialog extends StatelessWidget {
  const _AppointmentReminderDialog({required this.hourLabel, required this.onConfirm});

  final String hourLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              hourLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đã đến lịch hẹn',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 10),
            Text(
              'Hãy chuẩn bị sẵn sàng trước khi đón khách nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Đã nhớ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection({required this.items});

  final List<MechanicActivityNotification> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có thông báo.',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _NotificationTile(item: items[index]),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final MechanicActivityNotification item;

  @override
  Widget build(BuildContext context) {
    final isReview = item.kind == MechanicActivityNotificationKind.review;
    final iconBg = isReview ? const Color(0xFFFFD54F) : AppColors.primary;
    final icon = isReview ? Icons.star_rounded : Icons.mail_rounded;

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
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1.3,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                if (item.preview != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.preview!,
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
          Text(
            item.timeLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
