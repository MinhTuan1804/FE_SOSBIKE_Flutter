import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/notifications/data/models/chat_models.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/providers/chat_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.orderId,
    required this.title,
    this.avatarUrl,
  });

  final String orderId;
  final String title;
  final String? avatarUrl;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastMessageId;
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.orderId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final messages = chat.messages;
    _maybeScroll(messages, chat.isLoadingMessages);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: chat.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        isMine: message.isMine,
                        content: message.content,
                        time: DateFormat('HH:mm').format(message.createdAt),
                        avatarUrl: message.isMine ? null : message.senderAvatarUrl,
                      );
                    },
                  ),
          ),
          _buildInputBar(context, chat),
        ],
      ),
    );
  }

  void _maybeScroll(List<ChatMessage> messages, bool isLoading) {
    if (isLoading || messages.isEmpty) return;

    final currentLastId = messages.last.messageId;
    if (!_didInitialScroll || currentLastId != _lastMessageId) {
      _didInitialScroll = true;
      _lastMessageId = currentLastId;
      _scrollToBottom();
    }
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.only(top: topPadding + 10, bottom: 12, left: 12, right: 16),
      color: AppColors.primary,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: ClipOval(
              child: widget.avatarUrl?.isNotEmpty == true
                  ? Image.network(
                      widget.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ChatProvider chat) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhắn tin...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: chat.isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              color: AppColors.primary,
              onPressed: chat.isSending
                  ? null
                  : () async {
                      final content = _controller.text;
                      final ok = await chat.sendMessage(widget.orderId, content);
                      if (ok) {
                        _controller.clear();
                        _scrollToBottom();
                      } else if (chat.errorMessage != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(chat.errorMessage!)),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isMine,
    required this.content,
    required this.time,
    this.avatarUrl,
  });

  final bool isMine;
  final String content;
  final String time;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? AppColors.primary : const Color(0xFFF2F2F2);
    final textColor = isMine ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                backgroundImage: avatarUrl?.isNotEmpty == true ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl?.isNotEmpty == true ? null : const Icon(Icons.person, size: 18),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMine ? 14 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 14),
                    ),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
