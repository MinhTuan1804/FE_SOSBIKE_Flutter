import 'package:flutter/material.dart';

class MessageListView extends StatelessWidget {
  const MessageListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Message Item 1
        _buildMessageItem(
          context,
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=60',
          title: 'Tiệm sửa xe Thanh Hải',
          subtitle: 'Em đến nơi rồi ạ.',
          time: '16:50 T4',
          unreadCount: 2,
          isUnread: true,
        ),
        const Divider(height: 1, color: Colors.black12, indent: 80),

        // Message Item 2
        _buildMessageItem(
          context,
          avatarUrl: '', // Will use default silhouette
          title: 'Nguyen Van B • Tiệm sửa xe 68',
          subtitle: 'Cảm ơn quý khách đã sử dụng dịch vụ của cửa hàng chúng em.',
          time: '18:56 T6',
          unreadCount: 0,
          isUnread: false,
        ),
      ],
    );
  }

  Widget _buildMessageItem(
    BuildContext context, {
    required String avatarUrl,
    required String title,
    required String subtitle,
    required String time,
    required int unreadCount,
    required bool isUnread,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Stack with Unread Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.orangeAccent, width: 1.5),
                  ),
                  child: ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: Colors.grey,
                              size: 32,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: Colors.grey,
                            size: 32,
                          ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Content: Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? Colors.black54 : Colors.grey[500],
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Timestamp
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
