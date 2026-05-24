import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/widgets/message_list_view.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/widgets/notification_list_view.dart';

class NotificationsTabScreen extends StatefulWidget {
  const NotificationsTabScreen({super.key});

  @override
  State<NotificationsTabScreen> createState() => _NotificationsTabScreenState();
}

class _NotificationsTabScreenState extends State<NotificationsTabScreen> {
  int _activeTabIndex = 0; // 0: Tin nhắn, 1: Thông báo

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Red Header
          Container(
            padding: EdgeInsets.only(top: topPadding + 8, bottom: 16, left: 16, right: 16),
            color: AppColors.primary,
            child: Row(
              children: [
                const SizedBox(width: 40), // Balance spacing
                const Expanded(
                  child: Center(
                    child: Text(
                      'Thông báo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Show trash icon on the right only when Notification tab is active
                _activeTabIndex == 1
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Xóa tất cả thông báo!')),
                          );
                        },
                      )
                    : const SizedBox(width: 40),
              ],
            ),
          ),

          // Custom Segmented Toggle Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                // Tab 1: Tin nhắn
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeTabIndex = 0;
                      });
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _activeTabIndex == 0
                            ? const Color(0xFFC02020)
                            : const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (_activeTabIndex == 0)
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Tin nhắn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: _activeTabIndex == 0 ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tab 2: Thông báo
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeTabIndex = 1;
                      });
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _activeTabIndex == 1
                            ? const Color(0xFFC02020)
                            : const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (_activeTabIndex == 1)
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Thông báo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: _activeTabIndex == 1 ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable list content
          Expanded(
            child: _activeTabIndex == 0
                ? const MessageListView()
                : const NotificationListView(),
          ),
        ],
      ),
    );
  }
}
