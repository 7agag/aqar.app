import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/localization/app_strings.dart';
import 'package:aqar/core/services/ai_unread_service.dart';
import 'package:aqar/core/theme/app_colors.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../bloc/ai_bloc.dart';
import '../bloc/ai_event.dart';
import '../bloc/ai_state.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/ai_typing_indicator.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {

  late final TextEditingController _messageController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late final VoidCallback _focusListener;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    AiUnreadService().clear();
    _messageController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _focusListener = () {
      if (_focusNode.hasFocus) _scrollToBottom();
    };
    _focusNode.addListener(_focusListener);
    context.read<AiBloc>().add(const LoadAiChatHistory());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.removeListener(_focusListener);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final state = context.read<AiBloc>().state;
    if (state is AiLoaded && state.isLoading) return;
    context.read<AiBloc>().add(SendAiMessage(message: text));
    _messageController.clear();
    _scrollToBottom();
  }

  void _sendStarterPrompt() {
    if (_isSending) return;
    final state = context.read<AiBloc>().state;
    if (state is AiLoaded && state.isLoading) return;
    _isSending = true;
    context
        .read<AiBloc>()
        .add(SendAiMessage(message: AppStrings.aiStarterPrompt));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Aqar Assistant',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppStrings.aiPoweredByAi,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<AiBloc>().add(ResetAiChat()),
            child: Text(
              AppStrings.aiClearChat,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: BlocListener<AiBloc, AiState>(
          listenWhen: (previous, current) {
            if (current is! AiLoaded) return false;
            if (current.errorMessage != null) return true;
            final prevLen = previous is AiLoaded ? previous.messages.length : 0;
            return current.messages.length != prevLen;
          },
          listener: (context, state) {
            if (state is AiLoaded && !state.isLoading) {
              _isSending = false;
            }
            _scrollToBottom();
            if (state is AiLoaded && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? AppStrings.aiError),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: BlocBuilder<AiBloc, AiState>(
            builder: (context, state) {
              if (state is AiError) {
                return _buildError(state.message);
              }
              final messages = state is AiLoaded
                  ? state.messages
                  : const <AiMessageEntity>[];
              final isLoading = state is AiLoaded && state.isLoading;

              return Column(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: messages.isEmpty
                          ? _buildEmptyState()
                          : _buildChatList(messages, isLoading),
                    ),
                  ),
                  _buildInputBar(isLoading),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.error.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AiBloc>().add(ResetAiChat()),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.support_agent,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.aiEmptyPrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.aiWelcomeDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: _sendStarterPrompt,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.aiStarterPrompt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<AiMessageEntity> messages, bool isLoading) {
    return ListView.builder(
      key: const ValueKey('chat'),
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == 0 && isLoading) return const AiTypingIndicator();
        final msgIndex = messages.length - 1 - i + (isLoading ? 1 : 0);
        final msg = messages[msgIndex];
        return AiMessageBubble(msg: msg);
      },
    );
  }

  Widget _buildInputBar(bool isSending) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                enabled: !isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: AppStrings.aiTypeMessage,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
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
            const SizedBox(width: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty && !isSending;
                return GestureDetector(
                  onTap: canSend ? _handleSend : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: canSend
                          ? AppColors.primary
                          : AppColors.textHint.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

