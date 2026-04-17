import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_fin_os/core/config/ai_runtime_config.dart';
import 'package:student_fin_os/models/assistant_models.dart';
import 'package:student_fin_os/providers/assistant_providers.dart';

class ChatAssistantScreen extends ConsumerStatefulWidget {
  const ChatAssistantScreen({super.key});

  @override
  ConsumerState<ChatAssistantScreen> createState() =>
      _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends ConsumerState<ChatAssistantScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
        title: const Text('Chat Assistant'),
        actions: <Widget>[
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: <Widget>[
              _ModeHeader(
                mode: state.mode,
                activeModel: state.activeModel,
                onModeChanged: (AssistantResponseMode mode) {
                  ref
                      .read(chatAssistantControllerProvider.notifier)
                      .setMode(mode);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _MessageList(
                  scrollController: _scrollController,
                  messages: state.messages,
                  showTypingIndicator: state.isTyping,
                ),
              ),
              if (state.errorMessage != null) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Last request failed. Retry with the same prompt.',
                        style: Theme.of(context).textTheme.bodySmall,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.suggestedPrompts.map((String prompt) {
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
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              _Composer(
                controller: _composerController,
                enabled: !state.isTyping,
                onSubmitted: _sendCurrentMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeHeader extends StatelessWidget {
  const _ModeHeader({
    required this.mode,
    required this.activeModel,
    required this.onModeChanged,
  });

  final AssistantResponseMode mode;
  final String? activeModel;
  final ValueChanged<AssistantResponseMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final String currentModel =
        activeModel ??
        (mode == AssistantResponseMode.deep
            ? AiRuntimeConfig.chatDeepModel
            : AiRuntimeConfig.chatFastModel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'AI routing',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AssistantResponseMode>(
            segments: const <ButtonSegment<AssistantResponseMode>>[
              ButtonSegment<AssistantResponseMode>(
                value: AssistantResponseMode.fast,
                icon: Icon(Icons.flash_on),
                label: Text('Fast'),
              ),
              ButtonSegment<AssistantResponseMode>(
                value: AssistantResponseMode.deep,
                icon: Icon(Icons.psychology_alt),
                label: Text('Deep'),
              ),
            ],
            selected: <AssistantResponseMode>{mode},
            onSelectionChanged: (Set<AssistantResponseMode> selected) {
              onModeChanged(selected.first);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Model: $currentModel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
        child: Text(
          'Ask anything about your spending, goals, budgets, or splits.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
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

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2)
                    : message.isError
                    ? Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.18)
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(message.content),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('hh:mm a').format(message.timestamp.toLocal()),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
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
