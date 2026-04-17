import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_fin_os/features/assistant/ui/voice_assistant_sheet.dart';
import 'package:student_fin_os/models/assistant_models.dart';
import 'package:student_fin_os/providers/assistant_providers.dart';

class ChatAssistantScreen extends ConsumerStatefulWidget {
  const ChatAssistantScreen({super.key, this.initialMessage});

  final String? initialMessage;

  @override
  ConsumerState<ChatAssistantScreen> createState() =>
      _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends ConsumerState<ChatAssistantScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatAssistantControllerProvider.notifier).sendMessage(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendCurrentMessage() async {
    final String text = _composerController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _composerController.clear();
    await ref.read(chatAssistantControllerProvider.notifier).sendMessage(text);
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openVoiceAssistant() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const FractionallySizedBox(
          heightFactor: 0.92,
          child: VoiceAssistantSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChatAssistantState state = ref.watch(chatAssistantControllerProvider);

    ref.listen<ChatAssistantState>(chatAssistantControllerProvider, (
      ChatAssistantState? previous,
      ChatAssistantState next,
    ) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Assistant request failed. You can retry the last question.',
            ),
          ),
        );
      }

      final int previousCount = previous?.messages.length ?? 0;
      if (next.messages.length != previousCount ||
          next.isTyping != previous?.isTyping) {
        _scheduleScrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'FinMate Chat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Personalized finance guidance from your data',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: state.mode == AssistantResponseMode.fast ? 'Fast Mode' : 'Deep Mode',
            onPressed: () {
              final newMode = state.mode == AssistantResponseMode.fast 
                  ? AssistantResponseMode.deep 
                  : AssistantResponseMode.fast;
              ref.read(chatAssistantControllerProvider.notifier).setMode(newMode);
            },
            icon: Icon(
              state.mode == AssistantResponseMode.fast ? Icons.flash_on : Icons.psychology_alt,
            ),
          ),
          IconButton(
            tooltip: 'Open voice assistant',
            onPressed: _openVoiceAssistant,
            icon: const Icon(Icons.graphic_eq),
          ),
          IconButton(
            tooltip: 'Clear chat',
            onPressed: () {
              ref
                  .read(chatAssistantControllerProvider.notifier)
                  .clearConversation();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            children: <Widget>[
              Expanded(
                child: _MessageList(
                  scrollController: _scrollController,
                  messages: state.messages,
                  showTypingIndicator: state.isTyping,
                ),
              ),
              if (state.errorMessage != null) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Last request failed. Retry with the same prompt.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: state.isTyping
                            ? null
                            : () {
                                ref
                                    .read(
                                      chatAssistantControllerProvider.notifier,
                                    )
                                    .retryLast();
                              },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
              if (state.suggestedPrompts.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suggested prompts',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.suggestedPrompts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final String prompt = state.suggestedPrompts[index];
                      return ActionChip(
                        onPressed: state.isTyping
                            ? null
                            : () {
                                ref
                                    .read(
                                      chatAssistantControllerProvider.notifier,
                                    )
                                    .sendPrompt(prompt);
                              },
                        label: Text(prompt),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                  child: _Composer(
                    controller: _composerController,
                    enabled: !state.isTyping,
                    onSubmitted: _sendCurrentMessage,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.showTypingIndicator,
  });

  final ScrollController scrollController;
  final List<AssistantMessage> messages;
  final bool showTypingIndicator;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !showTypingIndicator) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Ask about budgets, spending trends, savings goals, or split settlements.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length + (showTypingIndicator ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index >= messages.length) {
          return const _TypingBubble();
        }

        final AssistantMessage message = messages[index];
        final bool isUser = message.role == AssistantRole.user;
        final Color bubbleColor = isUser
            ? Theme.of(context).colorScheme.primaryContainer
            : message.isError
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.52);
        final Color onBubbleColor = isUser
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : message.isError
            ? Theme.of(context).colorScheme.onErrorContainer
            : Theme.of(context).colorScheme.onSurface;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (!isUser)
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      message.isError ? Icons.error_outline : Icons.smart_toy_outlined,
                      size: 15,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                if (!isUser) const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: onBubbleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('hh:mm a').format(message.timestamp.toLocal()),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: onBubbleColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUser) const SizedBox(width: 8),
                if (isUser)
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI is typing...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            enabled: enabled,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSubmitted(),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              labelText: 'Ask your finance question',
              hintText: 'Example: How can I stay under budget this week?',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Send',
          onPressed: enabled ? onSubmitted : null,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}
