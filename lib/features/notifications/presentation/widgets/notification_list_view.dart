import 'package:flutter/material.dart';

class NotificationListView extends StatelessWidget {
  const NotificationListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Notification Item 1
        _buildNotificationItem(
          icon: Icons.mail_rounded,
          iconBg: const Color(0xFFD02121),
          title: '• Đánh giá trải nghiệm sửa xe lưu động',
          subtitle: 'Bạn thấy sao về dịch vụ của tiệm sửa xe 68? Hãy chia sẻ ý kiến nhé.',
          time: '16:50 T4',
          isUnread: true,
        ),
        const Divider(height: 1, color: Colors.black12, indent: 80),

        // Notification Item 2
        _buildNotificationItem(
          icon: Icons.mail_rounded,
          iconBg: const Color(0xFFD02121),
          title: '• Đánh giá trải nghiệm sửa xe lưu động',
          subtitle: 'Bạn thấy sao về dịch vụ của tiệm sửa xe 68? Hãy chia sẻ ý kiến nhé.',
          time: '16:50 T4',
          isUnread: true,
        ),
        const Divider(height: 1, color: Colors.black12, indent: 80),

        // Notification Item 3
        _buildNotificationItem(
          icon: Icons.mail_rounded,
          iconBg: const Color(0xFFD02121),
          title: '• Đánh giá trải nghiệm sửa xe lưu động',
          subtitle: 'Bạn thấy sao về dịch vụ của tiệm sửa xe 68? Hãy chia sẻ ý kiến nhé.',
          time: '16:50 T4',
          isUnread: true,
        ),
        const Divider(height: 1, color: Colors.black12, indent: 80),

        // Notification Item 4
        _buildNotificationItem(
          icon: Icons.percent_rounded,
          iconBg: const Color(0xFFFFB800),
          title: '• Giảm giá đến 20% cho lần sửa xe Tiê...',
          subtitle: 'Tham gia gói thành viên ưu tiên để nhận được các ưu đãi đặc quyền.',
          time: '16:50 T4',
          isUnread: true,
        ),
        const Divider(height: 1, color: Colors.black12, indent: 80),

        // Notification Item 5
        _buildNotificationItem(
          icon: Icons.account_balance_wallet_rounded,
          iconBg: const Color(0xFF4CAF50),
          title: '• Trải nghiệm tính năng thanh toán nh...',
          subtitle: 'Tham gia gói thành viên ưu tiên để nhận được các ưu đãi đặc quyền.',
          time: '15:07 T6',
          isUnread: true,
        ),
      ],
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Icon with top-right unread dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (isUnread)
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

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
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

            // Time
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
