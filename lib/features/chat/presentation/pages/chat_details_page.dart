import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/rent_status_banner.dart';

class ChatDetailsPage extends StatefulWidget {
  final String userName;
  final String initials;
  final String? threadId;
  final String? partnerId;
  final int? propertyId;

  const ChatDetailsPage({
    super.key,
    required this.userName,
    required this.initials,
    this.threadId,
    this.partnerId,
    this.propertyId,
  });

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  late final TextEditingController _messageController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  final List<ChatMessageEntity> _messages = [];
  String? _currentUserId;
  String? _chatId;
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthProfileLoaded) {
      _currentUserId = authState.user.id;
    }

    if (widget.threadId != null) {
      _chatId = widget.threadId;
      context.read<ChatBloc>().add(GetChatHistoryRequested(chatId: widget.threadId!));
      context.read<ChatBloc>().add(MarkAsReadRequested(chatId: widget.threadId!));
    }

    _socketSub = di.sl<SocketService>().onMessage.listen(_handleSocketMessage);
  }

  void _handleSocketMessage(Map<String, dynamic> data) {
    if (_chatId == null) return;
    final msgChatId = data['chat_id']?.toString();
    if (msgChatId != _chatId) return;
    if (!mounted) return;

    final messageId = data['message_id']?.toString() ?? '';
    if (messageId.isNotEmpty && _messages.any((m) => m.messageId == messageId)) return;

    final senderId = data['sender_id']?.toString()
        ?? data['sender']?.toString()
        ?? data['user_id']?.toString()
        ?? '';

    final message = ChatMessageEntity(
      messageId: messageId,
      senderId: senderId,
      content: data['content']?.toString() ?? '',
      isRead: false,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );

    if (senderId == _currentUserId) {
      final idx = _messages.indexWhere(
        (m) => m.messageId.isEmpty && m.content == message.content,
      );
      if (idx >= 0) {
        setState(() { _messages[idx] = message; });
      }
      _scrollToTop();
      return;
    }

    setState(() {
      _messages.insert(0, message);
    });
    _scrollToTop();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (widget.threadId != null || (widget.partnerId != null && widget.propertyId != null)) {
      context.read<ChatBloc>().add(SendMessageRequested(
        receiverId: widget.partnerId!,
        propertyId: widget.propertyId!,
        content: text,
      ));
    }

    final now = DateTime.now();
    _messages.insert(0, ChatMessageEntity(
      messageId: '',
      senderId: _currentUserId ?? '',
      content: text,
      isRead: false,
      createdAt: now,
    ));
    _messageController.clear();

    setState(() {});
    _scrollToTop();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
          color: AppColors.textPrimary,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              child: Text(
                widget.initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
            Builder(
              builder: (context) {
                final anyUnread = _messages.any((m) => !m.isRead);
                return IconButton(
                  icon: Icon(
                    anyUnread ? Icons.visibility : Icons.visibility_off,
                    color: anyUnread ? AppColors.primary : AppColors.textHint,
                    size: 22,
                  ),
                  tooltip: anyUnread ? 'Seen all' : 'Unread all',
                  onPressed: () {
                    if (anyUnread && _chatId != null) {
                      setState(() {
                        for (int i = 0; i < _messages.length; i++) {
                          _messages[i] = ChatMessageEntity(
                            messageId: _messages[i].messageId,
                            senderId: _messages[i].senderId,
                            content: _messages[i].content,
                            isRead: true,
                            createdAt: _messages[i].createdAt,
                          );
                        }
                      });
                      context.read<ChatBloc>().add(MarkAsReadRequested(chatId: _chatId!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked all as read')),
                      );
                    } else if (!anyUnread) {
                      setState(() {
                        for (int i = 0; i < _messages.length; i++) {
                          _messages[i] = ChatMessageEntity(
                            messageId: _messages[i].messageId,
                            senderId: _messages[i].senderId,
                            content: _messages[i].content,
                            isRead: false,
                            createdAt: _messages[i].createdAt,
                          );
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked all as unread')),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatHistoryLoaded && (widget.threadId == null || state.chatId == widget.threadId)) {
            _chatId = state.chatId;
            setState(() {
              _messages.clear();
              _messages.addAll(state.messages.reversed);
            });
          }
        },
        child: GestureDetector(
          onTap: () => _focusNode.unfocus(),
          child: Column(
            children: [
              if (widget.propertyId != null)
                RentStatusBanner(propertyId: widget.propertyId!),
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Start a conversation',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isSender = msg.senderId == _currentUserId;
                          return _buildMessageBubble(msg, isSender);
                        },
                      ),
              ),
              _buildInputBar(bottomInset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageEntity msg, bool isSender) {
    if (isSender) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 80, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                msg.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(msg.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 80, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.navyBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(double bottomInset) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.attach_file_outlined,
                    color: AppColors.textHint,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File picker coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintTextDirection: TextDirection.ltr,
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
