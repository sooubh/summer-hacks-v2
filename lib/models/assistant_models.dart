enum AssistantRole { user, assistant }

extension AssistantRoleWire on AssistantRole {
  String get wireValue {
    switch (this) {
      case AssistantRole.user:
        return 'user';
      case AssistantRole.assistant:
        return 'assistant';
    }
  }
}

enum AssistantResponseMode { fast, deep }

extension AssistantResponseModeWire on AssistantResponseMode {
  String get wireValue {
    switch (this) {
      case AssistantResponseMode.fast:
        return 'fast';
      case AssistantResponseMode.deep:
        return 'deep';
    }
  }
}

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  final String id;
  final AssistantRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  Map<String, String> toHistoryPayload() {
    return <String, String>{'role': role.wireValue, 'content': content};
  }
}

class AssistantReply {
  const AssistantReply({
    required this.reply,
    required this.modelUsed,
    required this.fallbackUsed,
    required this.generatedAt,
    required this.suggestions,
  });

  final String reply;
  final String modelUsed;
  final bool fallbackUsed;
  final DateTime generatedAt;
  final List<String> suggestions;
}

class VoiceAssistantReply {
  const VoiceAssistantReply({
    required this.reply,
    required this.modelUsed,
    required this.fallbackUsed,
    required this.generatedAt,
    required this.speechChunks,
  });

  final String reply;
  final String modelUsed;
  final bool fallbackUsed;
  final DateTime generatedAt;
  final List<String> speechChunks;
}

enum VoiceAssistantStatus { idle, listening, processing, speaking, error }

class ChatAssistantState {
  const ChatAssistantState({
    required this.messages,
    required this.isTyping,
    required this.mode,
    required this.suggestedPrompts,
    this.activeModel,
    this.errorMessage,
    this.lastUserInput,
  });

  factory ChatAssistantState.initial({
    List<String> defaultPrompts = const <String>[],
  }) {
    return ChatAssistantState(
      messages: const <AssistantMessage>[],
      isTyping: false,
      mode: AssistantResponseMode.fast,
      suggestedPrompts: defaultPrompts,
    );
  }

  final List<AssistantMessage> messages;
  final bool isTyping;
  final AssistantResponseMode mode;
  final List<String> suggestedPrompts;
  final String? activeModel;
  final String? errorMessage;
  final String? lastUserInput;

  ChatAssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? isTyping,
    AssistantResponseMode? mode,
    List<String>? suggestedPrompts,
    String? activeModel,
    String? errorMessage,
    String? lastUserInput,
    bool clearError = false,
  }) {
    return ChatAssistantState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      mode: mode ?? this.mode,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
      activeModel: activeModel ?? this.activeModel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUserInput: lastUserInput ?? this.lastUserInput,
    );
  }
}

class VoiceAssistantState {
  const VoiceAssistantState({
    required this.status,
    required this.transcript,
    required this.messages,
    this.activeModel,
    this.errorMessage,
  });

  factory VoiceAssistantState.initial() {
    return const VoiceAssistantState(
      status: VoiceAssistantStatus.idle,
      transcript: '',
      messages: <AssistantMessage>[],
    );
  }

  final VoiceAssistantStatus status;
  final String transcript;
  final List<AssistantMessage> messages;
  final String? activeModel;
  final String? errorMessage;

  VoiceAssistantState copyWith({
    VoiceAssistantStatus? status,
    String? transcript,
    List<AssistantMessage>? messages,
    String? activeModel,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VoiceAssistantState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      messages: messages ?? this.messages,
      activeModel: activeModel ?? this.activeModel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
