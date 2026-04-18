import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/config/ai_runtime_config.dart';
import 'package:student_fin_os/models/assistant_models.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/models/savings_goal.dart';
import 'package:student_fin_os/models/split_expense.dart';
import 'package:student_fin_os/models/split_group.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';
import 'package:student_fin_os/providers/savings_providers.dart';
import 'package:student_fin_os/providers/split_providers.dart';
import 'package:student_fin_os/providers/transaction_providers.dart';
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
      final _TaskExecutionResult? taskResult = await _executeInAppTaskIfRequested(
        input,
      );
      if (taskResult != null) {
        final AssistantMessage taskMessage = _newAssistantMessage(
          ref,
          role: AssistantRole.assistant,
          content: taskResult.message,
          isError: taskResult.isError,
        );

        state = state.copyWith(
          messages: <AssistantMessage>[...updatedMessages, taskMessage],
          isTyping: false,
          suggestedPrompts: taskResult.suggestions.isNotEmpty
              ? taskResult.suggestions
              : ref.read(defaultAssistantPromptsProvider),
          clearError: true,
        );
        return;
      }

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

  Future<_TaskExecutionResult?> _executeInAppTaskIfRequested(
    String input,
  ) async {
    final _AssistantTask? task = _parseAssistantTask(input);
    if (task == null) {
      return null;
    }

    try {
      switch (task.type) {
        case _AssistantTaskType.addTransaction:
          return _handleAddTransaction(task);
        case _AssistantTaskType.createSavingsGoal:
          return _handleCreateSavingsGoal(task);
        case _AssistantTaskType.addGoalContribution:
          return _handleGoalContribution(task);
      }
    } catch (error) {
      return _TaskExecutionResult(
        message:
            'I could not complete that task in-app: ${_cleanTaskError(error)}',
        isError: true,
        suggestions: const <String>[
          'Try: Add expense 250 for lunch',
          'Try: Create goal Laptop target 45000 by 2026-12-31',
          'Try: Add 1000 to goal Laptop',
        ],
      );
    }
  }

  Future<_TaskExecutionResult> _handleAddTransaction(_AssistantTask task) async {
    final List<Account> accounts =
        ref.read(accountsProvider).value ?? const <Account>[];
    if (accounts.isEmpty) {
      throw StateError('no account found; add an account first');
    }

    final Account selectedAccount = accounts.firstWhere(
      (Account account) => account.isActive,
      orElse: () => accounts.first,
    );

    final List<String> categories = ref.read(transactionCategoriesProvider);
    final String normalizedCategory = categories.contains(task.category)
        ? task.category!
        : 'auto';

    await ref.read(transactionControllerProvider.notifier).addManualTransaction(
      title: task.title ?? 'Chat entry',
      accountId: selectedAccount.id,
      amount: task.amount!,
      type: task.transactionType!,
      category: normalizedCategory,
      tags: const <String>['assistant'],
      source: 'assistant_chat',
    );

    final AsyncValue<void> txState = ref.read(transactionControllerProvider);
    if (txState.hasError) {
      throw txState.error ?? StateError('transaction could not be saved');
    }

    final String typeLabel = task.transactionType == TransactionType.income
        ? 'income'
        : 'expense';
    final String amountText = _formatAmount(task.amount!);

    return _TaskExecutionResult(
      message: 'Done. Added a $typeLabel entry of Rs $amountText.',
      suggestions: const <String>[
        'Show today\'s spending summary.',
        'What should my daily spend cap be now?',
      ],
    );
  }

  Future<_TaskExecutionResult> _handleCreateSavingsGoal(
    _AssistantTask task,
  ) async {
    final DateTime deadline = task.deadline ??
        DateTime.now().toUtc().add(const Duration(days: 90));

    await ref.read(savingsControllerProvider.notifier).createGoal(
      title: task.title ?? 'Savings Goal',
      targetAmount: task.amount!,
      deadline: deadline,
    );

    final AsyncValue<void> savingsState = ref.read(savingsControllerProvider);
    if (savingsState.hasError) {
      throw savingsState.error ?? StateError('goal could not be created');
    }

    final String amountText = _formatAmount(task.amount!);
    return _TaskExecutionResult(
      message:
          'Done. Created goal "${task.title ?? 'Savings Goal'}" with target Rs $amountText.',
      suggestions: const <String>[
        'Add 500 to this goal.',
        'Show my savings goal progress.',
      ],
    );
  }

  Future<_TaskExecutionResult> _handleGoalContribution(_AssistantTask task) async {
    final List<SavingsGoal> goals =
        ref.read(savingsGoalsProvider).value ?? const <SavingsGoal>[];
    if (goals.isEmpty) {
      throw StateError('no savings goals found');
    }

    final SavingsGoal? selectedGoal = _findGoalByHint(
      goals: goals,
      hint: task.goalHint,
    );

    if (selectedGoal == null) {
      throw StateError('could not match the goal name in your request');
    }

    await ref.read(savingsControllerProvider.notifier).addContribution(
      goalId: selectedGoal.id,
      amount: task.amount!,
    );

    final AsyncValue<void> savingsState = ref.read(savingsControllerProvider);
    if (savingsState.hasError) {
      throw savingsState.error ?? StateError('contribution could not be saved');
    }

    final String amountText = _formatAmount(task.amount!);
    return _TaskExecutionResult(
      message:
          'Done. Added Rs $amountText to goal "${selectedGoal.title}".',
      suggestions: const <String>[
        'What is my updated goal progress?',
        'How much should I save weekly now?',
      ],
    );
  }

  String _cleanTaskError(Object error) {
    final String text = error.toString().trim();
    if (text.toLowerCase().startsWith('bad state:')) {
      return text.substring('bad state:'.length).trim();
    }
    return text;
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

  Future<void> completeStreamingReply(String fullReply) async {
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

    final _TaskExecutionResult? taskResult = await _executeTaskFromAssistantReply(
      normalized,
    );
    final String visibleReply = (taskResult?.message ??
            _stripTaskDirectiveFromReply(normalized))
        .trim();

    final AssistantMessage assistantMessage = _newAssistantMessage(
      ref,
      role: AssistantRole.assistant,
      content: visibleReply.isEmpty ? 'Done.' : visibleReply,
      isError: taskResult?.isError ?? false,
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
      final _TaskExecutionResult? localTaskResult = await _executeInAppTaskIfRequested(
        transcript,
      );
      if (localTaskResult != null) {
        final AssistantMessage localTaskMessage = _newAssistantMessage(
          ref,
          role: AssistantRole.assistant,
          content: localTaskResult.message,
          isError: localTaskResult.isError,
        );

        state = state.copyWith(
          status: VoiceAssistantStatus.idle,
          transcript: '',
          streamingReply: '',
          messages: <AssistantMessage>[...messages, localTaskMessage],
          clearError: true,
        );

        return VoiceAssistantReply(
          reply: localTaskResult.message,
          modelUsed: 'in_app_task',
          fallbackUsed: false,
          generatedAt: DateTime.now().toUtc(),
          speechChunks: <String>[localTaskResult.message],
        );
      }

      final VoiceAssistantReply reply = await ref
          .read(assistantServiceProvider)
          .sendVoiceTurn(
            transcript: transcript,
            history: _historyPayload(messages),
            clientContext: ref.read(assistantClientContextProvider),
          );

      final _TaskExecutionResult? taskFromReply = await _executeTaskFromAssistantReply(
        reply.reply,
      );
      final String visibleReply = (taskFromReply?.message ??
              _stripTaskDirectiveFromReply(reply.reply))
          .trim();

      final AssistantMessage assistantMessage = _newAssistantMessage(
        ref,
        role: AssistantRole.assistant,
        content: visibleReply.isEmpty ? 'Done.' : visibleReply,
        timestamp: reply.generatedAt,
        isError: taskFromReply?.isError ?? false,
      );

      state = state.copyWith(
        status: VoiceAssistantStatus.idle,
        transcript: '',
        streamingReply: '',
        messages: <AssistantMessage>[...messages, assistantMessage],
        activeModel: reply.modelUsed,
        clearError: true,
      );

      return VoiceAssistantReply(
        reply: visibleReply.isEmpty ? 'Done.' : visibleReply,
        modelUsed: reply.modelUsed,
        fallbackUsed: reply.fallbackUsed,
        generatedAt: reply.generatedAt,
        speechChunks: <String>[visibleReply.isEmpty ? 'Done.' : visibleReply],
      );
    } catch (error) {
      state = state.copyWith(
        status: VoiceAssistantStatus.error,
        errorMessage: error.toString(),
      );
      return null;
    }
  }

  Future<_TaskExecutionResult?> _executeInAppTaskIfRequested(
    String input,
  ) async {
    final _AssistantTask? task = _parseAssistantTask(input);
    if (task == null) {
      return null;
    }

    return _executeTask(task);
  }

  Future<_TaskExecutionResult?> _executeTaskFromAssistantReply(
    String reply,
  ) async {
    final _AssistantTask? task = _parseAssistantTaskDirective(reply);
    if (task == null) {
      return null;
    }

    return _executeTask(task);
  }

  Future<_TaskExecutionResult> _executeTask(_AssistantTask task) async {
    try {
      switch (task.type) {
        case _AssistantTaskType.addTransaction:
          return _handleAddTransaction(task);
        case _AssistantTaskType.createSavingsGoal:
          return _handleCreateSavingsGoal(task);
        case _AssistantTaskType.addGoalContribution:
          return _handleGoalContribution(task);
      }
    } catch (error) {
      return _TaskExecutionResult(
        message: 'I could not complete that task in-app: ${_cleanTaskError(error)}',
        isError: true,
      );
    }
  }

  Future<_TaskExecutionResult> _handleAddTransaction(_AssistantTask task) async {
    final List<Account> accounts =
        ref.read(accountsProvider).value ?? const <Account>[];
    if (accounts.isEmpty) {
      throw StateError('no account found; add an account first');
    }

    final Account selectedAccount = accounts.firstWhere(
      (Account account) => account.isActive,
      orElse: () => accounts.first,
    );

    final List<String> categories = ref.read(transactionCategoriesProvider);
    final String normalizedCategory = categories.contains(task.category)
        ? task.category!
        : 'auto';

    await ref.read(transactionControllerProvider.notifier).addManualTransaction(
      title: task.title ?? 'Voice entry',
      accountId: selectedAccount.id,
      amount: task.amount!,
      type: task.transactionType!,
      category: normalizedCategory,
      tags: const <String>['assistant', 'voice'],
      source: 'assistant_voice',
    );

    final AsyncValue<void> txState = ref.read(transactionControllerProvider);
    if (txState.hasError) {
      throw txState.error ?? StateError('transaction could not be saved');
    }

    final String typeLabel = task.transactionType == TransactionType.income
        ? 'income'
        : 'expense';
    final String amountText = _formatAmount(task.amount!);

    return _TaskExecutionResult(
      message: 'Done. Added a $typeLabel entry of Rs $amountText.',
    );
  }

  Future<_TaskExecutionResult> _handleCreateSavingsGoal(
    _AssistantTask task,
  ) async {
    final DateTime deadline =
        task.deadline ?? DateTime.now().toUtc().add(const Duration(days: 90));

    await ref.read(savingsControllerProvider.notifier).createGoal(
      title: task.title ?? 'Savings Goal',
      targetAmount: task.amount!,
      deadline: deadline,
    );

    final AsyncValue<void> savingsState = ref.read(savingsControllerProvider);
    if (savingsState.hasError) {
      throw savingsState.error ?? StateError('goal could not be created');
    }

    final String amountText = _formatAmount(task.amount!);
    return _TaskExecutionResult(
      message:
          'Done. Created goal "${task.title ?? 'Savings Goal'}" with target Rs $amountText.',
    );
  }

  Future<_TaskExecutionResult> _handleGoalContribution(_AssistantTask task) async {
    final List<SavingsGoal> goals =
        ref.read(savingsGoalsProvider).value ?? const <SavingsGoal>[];
    if (goals.isEmpty) {
      throw StateError('no savings goals found');
    }

    final SavingsGoal? selectedGoal = _findGoalByHint(
      goals: goals,
      hint: task.goalHint,
    );

    if (selectedGoal == null) {
      throw StateError('could not match the goal name in your request');
    }

    await ref.read(savingsControllerProvider.notifier).addContribution(
      goalId: selectedGoal.id,
      amount: task.amount!,
    );

    final AsyncValue<void> savingsState = ref.read(savingsControllerProvider);
    if (savingsState.hasError) {
      throw savingsState.error ?? StateError('contribution could not be saved');
    }

    final String amountText = _formatAmount(task.amount!);
    return _TaskExecutionResult(
      message: 'Done. Added Rs $amountText to goal "${selectedGoal.title}".',
    );
  }

  String _cleanTaskError(Object error) {
    final String text = error.toString().trim();
    if (text.toLowerCase().startsWith('bad state:')) {
      return text.substring('bad state:'.length).trim();
    }
    return text;
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

enum _AssistantTaskType {
  addTransaction,
  createSavingsGoal,
  addGoalContribution,
}

class _AssistantTask {
  const _AssistantTask({
    required this.type,
    this.amount,
    this.transactionType,
    this.title,
    this.category,
    this.deadline,
    this.goalHint,
  });

  final _AssistantTaskType type;
  final double? amount;
  final TransactionType? transactionType;
  final String? title;
  final String? category;
  final DateTime? deadline;
  final String? goalHint;
}

class _TaskExecutionResult {
  const _TaskExecutionResult({
    required this.message,
    this.suggestions = const <String>[],
    this.isError = false,
  });

  final String message;
  final List<String> suggestions;
  final bool isError;
}

_AssistantTask? _parseAssistantTask(String input) {
  final String lower = input.toLowerCase();

  final bool wantsGoalContribution =
      (lower.contains('add to goal') ||
          lower.contains('contribute') ||
          lower.contains('deposit to goal')) &&
      lower.contains('goal');
  if (wantsGoalContribution) {
    final double? amount = _extractAmount(input);
    if (amount == null || amount <= 0) {
      return null;
    }

    return _AssistantTask(
      type: _AssistantTaskType.addGoalContribution,
      amount: amount,
      goalHint: _extractGoalHint(input),
    );
  }

  final bool wantsCreateGoal = lower.contains('create goal') ||
      lower.contains('new goal') ||
      lower.contains('set goal') ||
      lower.contains('add goal');
  if (wantsCreateGoal) {
    final double? amount = _extractAmount(input);
    if (amount == null || amount <= 0) {
      return null;
    }

    return _AssistantTask(
      type: _AssistantTaskType.createSavingsGoal,
      amount: amount,
      title: _extractGoalTitle(input),
      deadline: _extractDeadline(input),
    );
  }

  final bool mentionsTransactionVerb = RegExp(
    r'\b(add|log|record|track)\b',
  ).hasMatch(lower);
  final bool mentionsMoneyEvent = lower.contains('expense') ||
      lower.contains('income') ||
      lower.contains('transaction') ||
      lower.contains('bill') ||
      lower.contains('spent') ||
      lower.contains('received');
  if (mentionsTransactionVerb && mentionsMoneyEvent) {
    final double? amount = _extractAmount(input);
    if (amount == null || amount <= 0) {
      return null;
    }

    final TransactionType txType = _extractTransactionType(lower);

    return _AssistantTask(
      type: _AssistantTaskType.addTransaction,
      amount: amount,
      transactionType: txType,
      title: _extractTransactionTitle(input, txType),
      category: _extractCategory(lower),
    );
  }

  return null;
}

_AssistantTask? _parseAssistantTaskDirective(String reply) {
  final List<String> lines = reply.split('\n');
  String? directiveLine;
  for (final String line in lines) {
    final String trimmed = line.trim();
    if (trimmed.toUpperCase().startsWith('APP_TASK:')) {
      directiveLine = trimmed;
      break;
    }
  }

  if (directiveLine == null || directiveLine.isEmpty) {
    return null;
  }

  final String payload = directiveLine.substring('APP_TASK:'.length).trim();
  if (payload.isEmpty) {
    return null;
  }

  final List<String> parts = payload
      .split(';')
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return null;
  }

  final String command = parts.first.toLowerCase();
  final Map<String, String> args = <String, String>{};
  for (final String part in parts.skip(1)) {
    final int index = part.indexOf('=');
    if (index <= 0 || index >= part.length - 1) {
      continue;
    }
    final String key = part.substring(0, index).trim().toLowerCase();
    final String value = part.substring(index + 1).trim();
    if (key.isEmpty || value.isEmpty) {
      continue;
    }
    args[key] = value;
  }

  switch (command) {
    case 'add_transaction':
      final double? amount = double.tryParse(args['amount'] ?? '');
      if (amount == null || amount <= 0) {
        return null;
      }
      final String typeToken = (args['type'] ?? 'expense').toLowerCase();
      final TransactionType type =
          typeToken == 'income' ? TransactionType.income : TransactionType.expense;
      return _AssistantTask(
        type: _AssistantTaskType.addTransaction,
        amount: amount,
        transactionType: type,
        title: args['title'],
        category: args['category'] ?? 'auto',
      );
    case 'create_goal':
      final double? target = double.tryParse(args['amount'] ?? '');
      if (target == null || target <= 0) {
        return null;
      }
      DateTime? deadline;
      final String deadlineToken = (args['deadline'] ?? '').trim();
      if (deadlineToken.isNotEmpty) {
        deadline = DateTime.tryParse(deadlineToken)?.toUtc();
      }
      return _AssistantTask(
        type: _AssistantTaskType.createSavingsGoal,
        amount: target,
        title: args['title'],
        deadline: deadline,
      );
    case 'add_goal_contribution':
      final double? amount = double.tryParse(args['amount'] ?? '');
      if (amount == null || amount <= 0) {
        return null;
      }
      return _AssistantTask(
        type: _AssistantTaskType.addGoalContribution,
        amount: amount,
        goalHint: args['goal'],
      );
    default:
      return null;
  }
}

String _stripTaskDirectiveFromReply(String reply) {
  return reply
      .split('\n')
      .where(
        (String line) => !line.trim().toUpperCase().startsWith('APP_TASK:'),
      )
      .join('\n')
      .trim();
}

double? _extractAmount(String input) {
  final RegExp currencyPattern = RegExp(
    r'(?:rs\.?|inr|₹)\s*(\d+(?:\.\d+)?)',
    caseSensitive: false,
  );
  final RegExpMatch? currencyMatch = currencyPattern.firstMatch(input);
  if (currencyMatch != null) {
    return double.tryParse(currencyMatch.group(1)!);
  }

  final Iterable<RegExpMatch> matches =
      RegExp(r'\d+(?:\.\d+)?').allMatches(input);
  for (final RegExpMatch match in matches) {
    final String token = match.group(0)!;
    final double? value = double.tryParse(token);
    if (value == null || value <= 0) {
      continue;
    }

    if (value >= 1900 && value <= 2100) {
      continue;
    }

    return value;
  }

  return null;
}

TransactionType _extractTransactionType(String lower) {
  if (lower.contains('income') ||
      lower.contains('received') ||
      lower.contains('earned') ||
      lower.contains('salary') ||
      lower.contains('stipend')) {
    return TransactionType.income;
  }
  return TransactionType.expense;
}

String _extractCategory(String lower) {
  const List<String> knownCategories = <String>[
    'food',
    'rent',
    'travel',
    'education',
    'shopping',
    'utilities',
    'entertainment',
    'health',
    'freelance',
    'stipend',
    'misc',
  ];

  for (final String category in knownCategories) {
    if (lower.contains(category)) {
      return category;
    }
  }

  if (lower.contains('bill') || lower.contains('electricity')) {
    return 'utilities';
  }
  if (lower.contains('lunch') || lower.contains('dinner') || lower.contains('cafe')) {
    return 'food';
  }
  if (lower.contains('bus') || lower.contains('metro') || lower.contains('uber')) {
    return 'travel';
  }

  return 'auto';
}

String _extractTransactionTitle(String input, TransactionType type) {
  final RegExpMatch? forMatch = RegExp(
    r'\bfor\b\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(input);
  if (forMatch != null) {
    final String candidate = forMatch.group(1)!.trim();
    if (candidate.isNotEmpty) {
      return _sanitizeTitle(candidate);
    }
  }

  return type == TransactionType.income
      ? 'Income via assistant'
      : 'Expense via assistant';
}

String _extractGoalTitle(String input) {
  final RegExpMatch? namedMatch = RegExp(
    r'(?:goal\s+for|goal\s+named|goal)\s+([a-zA-Z][a-zA-Z0-9\s]{1,50})',
    caseSensitive: false,
  ).firstMatch(input);
  if (namedMatch != null) {
    final String raw = namedMatch.group(1)!.trim();
    final String cleaned = raw
        .replaceAll(RegExp(r'\b(target|amount|by|in|rs|inr)\b.*$', caseSensitive: false), '')
        .trim();
    if (cleaned.isNotEmpty) {
      return _sanitizeTitle(cleaned);
    }
  }

  return 'Savings Goal';
}

String? _extractGoalHint(String input) {
  final RegExpMatch? toGoalMatch = RegExp(
    r'goal\s+([a-zA-Z][a-zA-Z0-9\s]{1,50})',
    caseSensitive: false,
  ).firstMatch(input);
  if (toGoalMatch == null) {
    return null;
  }

  final String cleaned = toGoalMatch.group(1)!.trim();
  if (cleaned.isEmpty) {
    return null;
  }

  return _sanitizeTitle(
    cleaned.replaceAll(RegExp(r'\b(with|by|for|of)\b.*$', caseSensitive: false), '').trim(),
  );
}

DateTime? _extractDeadline(String input) {
  final RegExpMatch? exactDate = RegExp(
    r'\b(\d{4}-\d{2}-\d{2})\b',
  ).firstMatch(input);
  if (exactDate != null) {
    final DateTime? parsed = DateTime.tryParse(exactDate.group(1)!);
    if (parsed != null) {
      return parsed.toUtc();
    }
  }

  final RegExpMatch? relative = RegExp(
    r'\bin\s+(\d+)\s+(day|days|week|weeks|month|months)\b',
    caseSensitive: false,
  ).firstMatch(input);
  if (relative == null) {
    return null;
  }

  final int? value = int.tryParse(relative.group(1)!);
  if (value == null || value <= 0) {
    return null;
  }

  final String unit = relative.group(2)!.toLowerCase();
  if (unit.startsWith('day')) {
    return DateTime.now().toUtc().add(Duration(days: value));
  }
  if (unit.startsWith('week')) {
    return DateTime.now().toUtc().add(Duration(days: value * 7));
  }
  return DateTime.now().toUtc().add(Duration(days: value * 30));
}

SavingsGoal? _findGoalByHint({
  required List<SavingsGoal> goals,
  required String? hint,
}) {
  final List<SavingsGoal> activeGoals = goals
      .where((SavingsGoal goal) => goal.status == GoalStatus.active)
      .toList(growable: false);
  final List<SavingsGoal> source = activeGoals.isNotEmpty ? activeGoals : goals;
  if (source.isEmpty) {
    return null;
  }

  final String normalizedHint = (hint ?? '').trim().toLowerCase();
  if (normalizedHint.isEmpty) {
    return source.length == 1 ? source.first : null;
  }

  for (final SavingsGoal goal in source) {
    if (goal.title.toLowerCase() == normalizedHint) {
      return goal;
    }
  }

  for (final SavingsGoal goal in source) {
    if (goal.title.toLowerCase().contains(normalizedHint)) {
      return goal;
    }
  }

  return null;
}

String _sanitizeTitle(String input) {
  return input.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _formatAmount(double amount) {
  final String fixed = amount.toStringAsFixed(2);
  return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
}
