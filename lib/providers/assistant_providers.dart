import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/config/ai_runtime_config.dart';
import 'package:student_fin_os/models/assistant_models.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/models/savings_goal.dart';
import 'package:student_fin_os/models/split_expense.dart';
import 'package:student_fin_os/models/split_group.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';
import 'package:student_fin_os/providers/split_providers.dart';
import 'package:student_fin_os/services/assistant_service.dart';

final defaultAssistantPromptsProvider = Provider<List<String>>((ref) {
  return const <String>[
    'Give me a quick spending summary for this week.',
    'How should I adjust my budget this month?',
    'What is my savings goal progress?',
    'Explain my latest transactions in simple words.',
    'Help me settle my split expenses smarter.',
  ];
});

final assistantServiceProvider = Provider<AssistantService>((ref) {
  return AssistantService();
});

final assistantClientContextProvider = Provider<Map<String, dynamic>>((ref) {
  final snapshot = ref.watch(dashboardSnapshotProvider);
  final List<SavingsGoal> goals =
      ref.watch(savingsGoalsProvider).value ?? const <SavingsGoal>[];
  final List<FinanceTransaction> transactions =
      ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];
  final List<SplitGroup> splitGroups =
      ref.watch(splitGroupsProvider).value ?? const <SplitGroup>[];
  final List<SplitExpense> splitExpenses =
      ref.watch(splitExpensesProvider).value ?? const <SplitExpense>[];
  final splitBalances = ref.watch(splitNetBalancesProvider);

  final List<Map<String, dynamic>> transactionSummary = transactions
      .take(12)
      .map((FinanceTransaction tx) {
        return <String, dynamic>{
          'title': tx.title,
          'amount': tx.amount,
          'type': tx.type.name,
          'category': tx.category,
          'timestamp': tx.transactionAt.toIso8601String(),
        };
      })
      .toList();

  final List<Map<String, dynamic>> savingsSummary = goals
      .where((SavingsGoal goal) => goal.status == GoalStatus.active)
      .take(8)
      .map((SavingsGoal goal) {
        return <String, dynamic>{
          'title': goal.title,
          'targetAmount': goal.targetAmount,
          'savedAmount': goal.savedAmount,
          'deadline': goal.deadline.toIso8601String(),
          'progress': goal.progress,
          'priority': goal.priority,
        };
      })
      .toList();

  double pendingSplitAmount = 0;
  int pendingSplitCount = 0;
  for (final SplitExpense item in splitExpenses) {
    if (item.status != SplitStatus.settled) {
      pendingSplitAmount += item.totalAmount;
      pendingSplitCount += 1;
    }
  }

  return <String, dynamic>{
    'dashboard': <String, dynamic>{
      'totalBalance': snapshot.totalBalance,
      'weeklySpend': snapshot.weeklySpend,
      'monthlySpend': snapshot.monthlySpend,
      'safeToSpend': snapshot.safeToSpend,
      'burnRate': snapshot.burnRate,
      'topCategory': snapshot.topCategory,
      'monthlyTrendPercent': snapshot.monthlyTrendPercent,
      'isMonthlySpendUp': snapshot.isMonthlySpendUp,
    },
    'transactions': transactionSummary,
    'savingsGoals': savingsSummary,
    'splits': <String, dynamic>{
      'groupCount': splitGroups.length,
      'pendingExpenseCount': pendingSplitCount,
      'pendingAmount': pendingSplitAmount,
      'selectedGroupBalances': splitBalances,
    },
  };
});

class ChatAssistantController extends Notifier<ChatAssistantState> {
  @override
  ChatAssistantState build() {
    return ChatAssistantState.initial(
      defaultPrompts: ref.read(defaultAssistantPromptsProvider),
    );
  }

  void setMode(AssistantResponseMode mode) {
    state = state.copyWith(mode: mode, clearError: true);
  }

  void clearConversation() {
    state = ChatAssistantState.initial(
      defaultPrompts: ref.read(defaultAssistantPromptsProvider),
    );
  }

  Future<void> sendMessage(String rawMessage, {AssistantResponseMode? mode}) {
    return _requestReply(
      rawMessage,
      appendUserMessage: true,
      mode: mode ?? state.mode,
    );
  }

  Future<void> sendPrompt(String prompt) {
    return sendMessage(prompt);
  }

  Future<void> retryLast() async {
    final String? lastUserInput = state.lastUserInput;
    if (lastUserInput == null ||
        lastUserInput.trim().isEmpty ||
        state.isTyping) {
      return;
    }

    await _requestReply(
      lastUserInput,
      appendUserMessage: false,
      mode: state.mode,
    );
  }

  Future<void> _requestReply(
    String rawInput, {
    required bool appendUserMessage,
    required AssistantResponseMode mode,
  }) async {
    final String input = rawInput.trim();
    if (input.isEmpty || state.isTyping) {
      return;
    }

    final List<AssistantMessage> updatedMessages = List<AssistantMessage>.from(
      state.messages,
    );
    if (!appendUserMessage &&
        updatedMessages.isNotEmpty &&
        updatedMessages.last.role == AssistantRole.assistant &&
        updatedMessages.last.isError) {
      updatedMessages.removeLast();
    }

    if (appendUserMessage) {
      updatedMessages.add(
        _newAssistantMessage(ref, role: AssistantRole.user, content: input),
      );
    }

    state = state.copyWith(
      messages: updatedMessages,
      isTyping: true,
      mode: mode,
      lastUserInput: input,
      clearError: true,
    );

    try {
      final AssistantReply reply = await ref
          .read(assistantServiceProvider)
          .sendChatMessage(
            message: input,
            history: _historyPayload(updatedMessages),
            responseMode: mode,
            clientContext: ref.read(assistantClientContextProvider),
          );

      final AssistantMessage assistantMessage = _newAssistantMessage(
        ref,
        role: AssistantRole.assistant,
        content: reply.reply,
        timestamp: reply.generatedAt,
      );

      state = state.copyWith(
        messages: <AssistantMessage>[...updatedMessages, assistantMessage],
        isTyping: false,
        activeModel: reply.modelUsed,
        suggestedPrompts: reply.suggestions.isNotEmpty
            ? reply.suggestions
            : ref.read(defaultAssistantPromptsProvider),
        clearError: true,
      );
    } catch (error) {
      final AssistantMessage assistantMessage = _newAssistantMessage(
        ref,
        role: AssistantRole.assistant,
        content:
            'Assistant is currently unavailable. Error: ${error.toString()}',
        isError: true,
      );

      state = state.copyWith(
        messages: <AssistantMessage>[...updatedMessages, assistantMessage],
        isTyping: false,
        errorMessage: error.toString(),
      );
    }
  }
}

final chatAssistantControllerProvider =
    NotifierProvider<ChatAssistantController, ChatAssistantState>(
      ChatAssistantController.new,
    );

class VoiceAssistantController extends Notifier<VoiceAssistantState> {
  @override
  VoiceAssistantState build() {
    return VoiceAssistantState.initial();
  }

  void setStatus(VoiceAssistantStatus status) {
    state = state.copyWith(status: status, clearError: true);
  }

  void updateTranscript(String transcript) {
    state = state.copyWith(transcript: transcript, clearError: true);
  }

  void setLiveSessionReady(bool ready) {
    state = state.copyWith(
      liveSessionReady: ready,
      activeModel: ready ? AiRuntimeConfig.voiceModel : state.activeModel,
      clearError: true,
    );
  }

  void startLiveUserTurn(String rawTranscript) {
    final String transcript = rawTranscript.trim();
    if (transcript.isEmpty || state.status == VoiceAssistantStatus.processing) {
      return;
    }

    final List<AssistantMessage> messages = <AssistantMessage>[
      ...state.messages,
      _newAssistantMessage(ref, role: AssistantRole.user, content: transcript),
    ];

    state = state.copyWith(
      status: VoiceAssistantStatus.processing,
      transcript: transcript,
      messages: messages,
      streamingReply: '',
      clearError: true,
    );
  }

  void startLiveAudioTurn({String displayText = '[Voice input]'}) {
    if (state.status == VoiceAssistantStatus.processing) {
      return;
    }

    final List<AssistantMessage> messages = <AssistantMessage>[
      ...state.messages,
      _newAssistantMessage(
        ref,
        role: AssistantRole.user,
        content: displayText,
      ),
    ];

    state = state.copyWith(
      status: VoiceAssistantStatus.processing,
      transcript: '',
      messages: messages,
      streamingReply: '',
      clearError: true,
    );
  }

  void updateStreamingReply(String partialReply) {
    state = state.copyWith(
      status: VoiceAssistantStatus.speaking,
      transcript: '',
      streamingReply: partialReply,
      activeModel: AiRuntimeConfig.voiceModel,
      clearError: true,
    );
  }

  void completeStreamingReply(String fullReply) {
    final String normalized = fullReply.trim();
    if (normalized.isEmpty) {
      state = state.copyWith(
        status: VoiceAssistantStatus.processing,
        transcript: '',
        streamingReply: '',
        activeModel: AiRuntimeConfig.voiceModel,
        clearError: true,
      );
      return;
    }

    final AssistantMessage assistantMessage = _newAssistantMessage(
      ref,
      role: AssistantRole.assistant,
      content: normalized,
    );

    state = state.copyWith(
      status: VoiceAssistantStatus.speaking,
      transcript: '',
      streamingReply: '',
      messages: <AssistantMessage>[...state.messages, assistantMessage],
      activeModel: AiRuntimeConfig.voiceModel,
      clearError: true,
    );
  }

  void clearStreamingReply() {
    state = state.copyWith(
      status: VoiceAssistantStatus.idle,
      streamingReply: '',
      clearError: true,
    );
  }

  void setError(String message, {String? code}) {
    state = state.copyWith(
      status: VoiceAssistantStatus.error,
      streamingReply: '',
      errorMessage: message,
      errorCode: code,
    );
  }

  void clearConversation() {
    state = VoiceAssistantState.initial().copyWith(
      liveSessionReady: state.liveSessionReady,
      activeModel: state.activeModel,
    );
  }

  Future<VoiceAssistantReply?> submitTranscript(String rawTranscript) async {
    final String transcript = rawTranscript.trim();
    if (transcript.isEmpty || state.status == VoiceAssistantStatus.processing) {
      return null;
    }

    final List<AssistantMessage> messages = <AssistantMessage>[
      ...state.messages,
      _newAssistantMessage(ref, role: AssistantRole.user, content: transcript),
    ];

    state = state.copyWith(
      status: VoiceAssistantStatus.processing,
      transcript: transcript,
      messages: messages,
      streamingReply: '',
      clearError: true,
    );

    try {
      final VoiceAssistantReply reply = await ref
          .read(assistantServiceProvider)
          .sendVoiceTurn(
            transcript: transcript,
            history: _historyPayload(messages),
            clientContext: ref.read(assistantClientContextProvider),
          );

      final AssistantMessage assistantMessage = _newAssistantMessage(
        ref,
        role: AssistantRole.assistant,
        content: reply.reply,
        timestamp: reply.generatedAt,
      );

      state = state.copyWith(
        status: VoiceAssistantStatus.idle,
        transcript: '',
        streamingReply: '',
        messages: <AssistantMessage>[...messages, assistantMessage],
        activeModel: reply.modelUsed,
        clearError: true,
      );

      return reply;
    } catch (error) {
      state = state.copyWith(
        status: VoiceAssistantStatus.error,
        errorMessage: error.toString(),
      );
      return null;
    }
  }
}

final voiceAssistantControllerProvider =
    NotifierProvider<VoiceAssistantController, VoiceAssistantState>(
      VoiceAssistantController.new,
    );

AssistantMessage _newAssistantMessage(
  Ref ref, {
  required AssistantRole role,
  required String content,
  bool isError = false,
  DateTime? timestamp,
}) {
  return AssistantMessage(
    id: ref.read(uuidProvider).v4(),
    role: role,
    content: content,
    timestamp: timestamp ?? DateTime.now().toUtc(),
    isError: isError,
  );
}

List<Map<String, String>> _historyPayload(List<AssistantMessage> messages) {
  final List<AssistantMessage> cleanMessages = messages
      .where((AssistantMessage message) => !message.isError)
      .toList(growable: false);

  final int start = cleanMessages.length > 14 ? cleanMessages.length - 14 : 0;
  final List<AssistantMessage> recent = cleanMessages.sublist(start);

  return recent
      .map((AssistantMessage message) => message.toHistoryPayload())
      .toList(growable: false);
}
