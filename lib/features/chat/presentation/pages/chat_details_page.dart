import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/num_formatting.dart';
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
import '../widgets/agreement_card.dart';
import '../../data/utils/agreement_utils.dart';

class ChatDetailsPage extends StatefulWidget {
  final String userName;
  final String initials;
  final String? threadId;
  final String? partnerId;
  final int? propertyId;
  final String? propertyName;
  final double? propertyPrice;
  final bool isSaleProperty;

  const ChatDetailsPage({
    super.key,
    required this.userName,
    required this.initials,
    this.threadId,
    this.partnerId,
    this.propertyId,
    this.propertyName,
    this.propertyPrice,
    this.isSaleProperty = false,
  });

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  late final TextEditingController _messageController;
  late final TextEditingController _agreementPriceController;
  late final TextEditingController _agreementTermsController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  final List<ChatMessageEntity> _messages = [];
  String _currentUserId = '';
  String? _chatId;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  bool _isOwner = false;
  final Set<String> _acceptedAgreements = {};
  final Set<String> _declinedAgreements = {};

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) _scrollToTop();
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthProfileLoaded) {
      _currentUserId = authState.user.id;
    }
    _isOwner = _currentUserId == widget.partnerId;
    _agreementPriceController = TextEditingController(
      text: widget.propertyPrice?.formatWithCommas() ?? '',
    );
    _agreementTermsController = TextEditingController();

    if (widget.threadId != null) {
      _chatId = widget.threadId;
      context.read<ChatBloc>().add(GetChatHistoryRequested(chatId: widget.threadId!));
      context.read<ChatBloc>().add(MarkAsReadRequested(chatId: widget.threadId!));
    }

    _socketSub = di.sl<SocketService>().onMessage.listen(_handleSocketMessage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUserId.isEmpty) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthProfileLoaded) {
        _currentUserId = authState.user.id;
      }
    }
  }

  @override
  void didUpdateWidget(covariant ChatDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.threadId != null && oldWidget.threadId != widget.threadId) {
      _chatId = widget.threadId;
      setState(() {
        _messages.clear();
      });
      context.read<ChatBloc>().add(GetChatHistoryRequested(chatId: widget.threadId!));
      context.read<ChatBloc>().add(MarkAsReadRequested(chatId: widget.threadId!));
    }
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
    final content = data['content']?.toString() ?? '';

    final message = ChatMessageEntity(
      messageId: messageId,
      senderId: senderId,
      content: content,
      isRead: false,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );

    if (content.startsWith('[AGREEMENT_ACCEPT]')) {
      setState(() => _acceptedAgreements.add(content));
    } else if (content.startsWith('[AGREEMENT_DECLINE]')) {
      setState(() => _declinedAgreements.add(content));
    }

    if (senderId == _currentUserId) {
      final idx = _messages.indexWhere(
        (m) => m.messageId.isEmpty && m.content == content,
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

  void _sendAgreement(String price, String terms) {
    if (!_canSendAgreement) return;
    final content = AgreementUtils.encodeRequest(AgreementData(
      propertyId: widget.propertyId ?? 0,
      propertyName: widget.propertyName ?? 'Property',
      price: double.tryParse(price) ?? 0,
      terms: terms,
    ));
    _sendMessage(content);
  }

  void _respondAgreement(bool accept) {
    final pid = widget.propertyId ?? 0;
    final content = accept
        ? AgreementUtils.encodeAccept(pid)
        : AgreementUtils.encodeDecline(pid);
    _sendMessage(content);
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;

    if (widget.threadId != null || (widget.partnerId != null && widget.propertyId != null)) {
      context.read<ChatBloc>().add(SendMessageRequested(
        receiverId: widget.partnerId!,
        propertyId: widget.propertyId!,
        content: text,
      ));
    }

    _messages.insert(0, ChatMessageEntity(
      messageId: '',
      senderId: _currentUserId,
      content: text,
      isRead: false,
      createdAt: DateTime.now(),
    ));

    if (!AgreementUtils.isAgreementMessage(text)) {
      _messageController.clear();
    }

    setState(() {});
    _scrollToTop();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _messageController.dispose();
    _agreementPriceController.dispose();
    _agreementTermsController.dispose();
    _focusNode.removeListener(() {});
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    _sendMessage(_messageController.text.trim());
    _messageController.clear();
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
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
      body:       BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileLoaded && _currentUserId != state.user.id) {
            _currentUserId = state.user.id;
            setState(() {});
          }
        },
        child: BlocListener<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatHistoryLoaded && (widget.threadId == null || state.chatId == widget.threadId)) {
              _chatId = state.chatId;
              setState(() {
                _messages.clear();
                _messages.addAll(state.messages.reversed.map((m) => ChatMessageEntity(
                  messageId: m.messageId,
                  senderId: m.senderId,
                  content: m.content,
                  isRead: true,
                  createdAt: m.createdAt,
                )));
              });
            }
            if (state is MessageSent) {
              final msgId = state.data['message_id']?.toString() ?? '';
              final senderId = state.data['sender_id']?.toString() ?? '';
              if (msgId.isNotEmpty && senderId.isNotEmpty) {
                final idx = _messages.indexWhere(
                  (m) => m.messageId.isEmpty && m.senderId == _currentUserId,
                );
                if (idx >= 0) {
                  setState(() {
                    _messages[idx] = ChatMessageEntity(
                      messageId: msgId,
                      senderId: senderId,
                      content: _messages[idx].content,
                      isRead: false,
                      createdAt: _messages[idx].createdAt,
                    );
                  });
                }
              }
            }
          },
          child: GestureDetector(
            onTap: () => _focusNode.unfocus(),
            child: Column(
              children: [
                if (widget.propertyId != null)
                  RentStatusBanner(propertyId: widget.propertyId!),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      if (widget.threadId != null) {
                        context.read<ChatBloc>().add(
                          GetChatHistoryRequested(chatId: widget.threadId!),
                        );
                      }
                    },
                    child: _messages.isEmpty
                        ? ListView(
                            physics: AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 200,
                                child: Center(
                                  child: Text(
                                    'Start a conversation',
                                    style: TextStyle(color: AppColors.textHint),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                            final msg = _messages[i];
                            final isSender = msg.senderId == _currentUserId;
                            return _buildMessageBubble(msg, isSender);
                          },
                        ),
                  ),
              ),
              _buildInputBar(bottomInset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageEntity msg, bool isSender) {
    final content = msg.content;
    final (agreementType, agreementData) = AgreementUtils.parse(content);

    if (agreementType != AgreementMessageType.none && agreementData != null) {
      final isAccepted = agreementType == AgreementMessageType.accepted ||
          _acceptedAgreements.any((a) => a.contains('${agreementData.propertyId}'));
      final isDeclined = agreementType == AgreementMessageType.declined ||
          _declinedAgreements.any((a) => a.contains('${agreementData.propertyId}'));

      final status = isAccepted ? 'accepted' : isDeclined ? 'declined' : 'pending';

      return Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: AgreementCard(
          data: agreementData,
          status: status,
          isOwner: _isOwner,
          onAccept: () => _respondAgreement(true),
          onDecline: () => _respondAgreement(false),
        ),
      );
    }

    if (agreementType == AgreementMessageType.accepted || agreementType == AgreementMessageType.declined) {
      final label = agreementType == AgreementMessageType.accepted ? 'Agreement Accepted' : 'Agreement Declined';
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: agreementType == AgreementMessageType.accepted
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: agreementType == AgreementMessageType.accepted
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ),
      );
    }

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

  bool get _canSendAgreement =>
      _isOwner &&
      widget.isSaleProperty &&
      widget.propertyName != null;

  void _showAgreementSheet(BuildContext context) {
    _agreementPriceController.text =
        widget.propertyPrice?.formatWithCommas() ?? '';
    _agreementTermsController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Send Agreement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Propose a price and terms to the buyer.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 20),
            Text('Price (EGP)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint)),
            SizedBox(height: 8),
            TextField(
              controller: _agreementPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            SizedBox(height: 16),
            Text('Terms (optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint)),
            const SizedBox(height: 8),
            TextField(
              controller: _agreementTermsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter payment terms, conditions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final price = _agreementPriceController.text.trim();
                  if (price.isEmpty) return;
                  Navigator.pop(ctx);
                  _sendAgreement(price, _agreementTermsController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Send Agreement',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(double bottomInset) {
    return Container(
      color: Colors.white,
      child: AnimatedPadding(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_canSendAgreement)
                  IconButton(
                    icon: Icon(
                      Icons.description_outlined,
                      color: AppColors.navyBlue,
                    ),
                    tooltip: 'Send Agreement',
                    onPressed: () => _showAgreementSheet(context),
                  ),
                IconButton(
                  icon: Icon(
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
                SizedBox(width: 4),
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
