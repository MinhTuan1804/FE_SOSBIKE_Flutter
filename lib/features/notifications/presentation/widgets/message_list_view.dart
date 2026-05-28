import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/providers/chat_provider.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/screens/chat_detail_screen.dart';

class MessageListView extends StatefulWidget {
  const MessageListView({super.key});

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final conversations = chat.conversations;

    if (chat.isLoadingConversations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chat.errorMessage != null) {
      return _buildEmptyState(context, chat.errorMessage!);
    }

    if (conversations.isEmpty) {
      return _buildEmptyState(context, 'Chưa có cuộc trò chuyện nào.');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12, indent: 80),
      itemBuilder: (context, index) {
        final item = conversations[index];
        return _buildMessageItem(
          context,
          avatarUrl: item.otherUserAvatarUrl ?? '',
          title: item.otherUserName,
          subtitle: item.lastMessage ?? 'Chưa có tin nhắn.',
          time: _formatTime(item.lastMessageAt),
          unreadCount: item.unreadCount,
          isUnread: item.unreadCount > 0,
          onTap: () async {
            final chatProvider = context.read<ChatProvider>();
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  orderId: item.orderId,
                  title: item.otherUserName,
                  avatarUrl: item.otherUserAvatarUrl,
                ),
              ),
            );
            if (!mounted) return;
            await chatProvider.loadConversations();
          },
        );
      },
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('HH:mm E', 'vi').format(time);
  }
}
