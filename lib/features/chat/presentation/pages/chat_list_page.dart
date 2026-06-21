import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aqar_button.dart';
import '../../../../core/widgets/refreshable_widget.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/chat_thread_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import 'chat_details_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  final Set<String> _pinnedIds = {};
  List<ChatThreadEntity> _inbox = [];

  late final AnimationController _skeletonController;
  late final AnimationController _staggerController;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  Timer? _inboxDebounce;

  List<ChatThreadEntity> get _sortedThreads {
    final result = List<ChatThreadEntity>.from(_inbox);
    result.sort((a, b) {
      final aPinned = _pinnedIds.contains(a.id);
      final bPinned = _pinnedIds.contains(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
      if (a.lastMessageTime == null) return 1;
      if (b.lastMessageTime == null) return -1;
      return b.lastMessageTime!.compareTo(a.lastMessageTime!);
    });
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return result.where((t) {
        final name = t.partnerName.toLowerCase();
        final msg = (t.lastMessage ?? '').toLowerCase();
        return name.contains(q) || msg.contains(q);
      }).toList();
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    context.read<ChatBloc>().add(const GetInboxRequested());

    _socketSub = di.sl<SocketService>().onMessage.listen((_) {
      _inboxDebounce?.cancel();
      _inboxDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.read<ChatBloc>().add(const GetInboxRequested());
        }
      });
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _inboxDebounce?.cancel();
    _searchController.dispose();
    _skeletonController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  void _deleteThread(ChatThreadEntity thread) {
    final index = _inbox.indexWhere((t) => t.id == thread.id);
    if (index == -1) return;
    final removed = _inbox.removeAt(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.partnerName} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _inbox.insert(index, removed));
          },
        ),
      ),
    );
    setState(() {});
  }

  void _showPinSheet(ChatThreadEntity thread) {
    final isPinned = _pinnedIds.contains(thread.id);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: AppColors.primary,
                ),
                title: Text(isPinned ? 'Unpin conversation' : 'Pin conversation'),
                onTap: () {
                  setState(() {
                    if (isPinned) {
                      _pinnedIds.remove(thread.id);
                    } else {
                      _pinnedIds.add(thread.id);
                    }
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_off_outlined),
                title: const Text('Mute notifications'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications muted')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteThread(thread);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is InboxLoaded) {
          setState(() {
            _inbox = state.threads;
            _isLoading = false;
          });
          _staggerController.forward();
        } else if (state is ChatError) {
          setState(() => _isLoading = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New message coming soon')),
                );
              },
            ),
          ],
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading ? _buildSkeletonLoader() : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _searchQuery.isNotEmpty || _searchController.text.isNotEmpty
          ? 56
          : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _searchQuery.isNotEmpty || _searchController.text.isNotEmpty
            ? 1.0
            : 0.0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'البحث في المحادثات...',
              hintTextDirection: TextDirection.rtl,
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, i) => AnimatedBuilder(
        animation: _skeletonController,
        builder: (_, __) {
          final opacity = _skeletonController.value * 0.4 + 0.2;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.withValues(alpha: opacity),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: i.isEven ? 120.0 : 90.0,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: opacity * 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    final threads = _sortedThreads;
    if (threads.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsState();
    }
    if (threads.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshableWidget(
      onRefresh: () async {
        context.read<ChatBloc>().add(const GetInboxRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: threads.length,
        itemBuilder: (ctx, i) {
          final thread = threads[i];
          final entry = (i < 12)
              ? CurvedAnimation(
                  parent: _staggerController,
                  curve: Interval(i * 0.065, 1.0, curve: Curves.easeOut),
                )
              : null;
          return entry != null
              ? FadeTransition(
                  opacity: entry,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.5, 0),
                      end: Offset.zero,
                    ).animate(entry),
                    child: _buildChatTile(thread),
                  ),
                )
              : _buildChatTile(thread);
        },
      ),
    );
  }

  Widget _buildChatTile(ChatThreadEntity thread) {
    final isPinned = _pinnedIds.contains(thread.id);
    final hasUnread = thread.unreadCount > 0;

    return Dismissible(
      key: ValueKey(thread.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Delete conversation?'),
                content: Text(
                  'Chat with ${thread.partnerName} will be removed.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _deleteThread(thread),
      child: GestureDetector(
        onLongPress: () => _showPinSheet(thread),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: hasUnread
                ? AppColors.primary.withValues(alpha: 0.03)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasUnread
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.borderLight.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailsPage(
                    userName: thread.partnerName,
                    initials: _getInitials(thread.partnerName),
                    threadId: thread.id,
                    partnerId: thread.partnerId,
                    propertyId: thread.propertyId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _getInitials(thread.partnerName),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isPinned)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.push_pin,
                                  size: 14,
                                  color: AppColors.textHint,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                thread.partnerName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      hasUnread ? FontWeight.w700 : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (thread.lastMessageTime != null)
                              Text(
                                _formatTime(thread.lastMessageTime),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                thread.lastMessage ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: hasUnread
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (hasUnread)
                              Container(
                                constraints: const BoxConstraints(minWidth: 22),
                                height: 22,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${thread.unreadCount}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'No conversations found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 44,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Start a conversation with a property owner\nby browsing available listings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: AqarButton(
                text: 'Browse Properties',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
