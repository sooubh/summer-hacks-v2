import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:student_fin_os/core/config/ai_runtime_config.dart';
import 'package:student_fin_os/models/assistant_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AssistantService {
  AssistantService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<VoiceLiveSession> openVoiceLiveSession({
    required Map<String, dynamic> clientContext,
    required List<Map<String, String>> history,
  }) async {
    final String apiKey = _requireApiKey();
    return VoiceLiveSession.connect(
      apiKey: apiKey,
      model: AiRuntimeConfig.voiceModel,
      responseModalities: const <String>['AUDIO'],
      systemInstruction: _buildLiveSessionSystemInstruction(
        clientContext: clientContext,
        history: history,
      ),
      voiceName: AiRuntimeConfig.liveVoiceName,
    );
  }

  Future<void> sendLiveTextPrompt({
    required VoiceLiveSession session,
    required String prompt,
  }) async {
    final String message = prompt.trim();
    if (message.isEmpty) {
      throw StateError('Prompt cannot be empty.');
    }

    await session.sendUserText(message);
  }

  Future<AssistantReply> sendChatMessage({
    required String message,
    required List<Map<String, String>> history,
    required AssistantResponseMode responseMode,
    required Map<String, dynamic> clientContext,
  }) async {
    final String prompt = message.trim();
    if (prompt.isEmpty) {
      throw StateError('Message cannot be empty.');
    }

    final String apiKey = _requireApiKey();
    final String primaryModel = responseMode == AssistantResponseMode.deep
        ? AiRuntimeConfig.chatDeepModel
        : AiRuntimeConfig.chatFastModel;

    final List<Map<String, String>> normalizedHistory = _historyWindow(history);
    final List<Map<String, String>> allMessages = <Map<String, String>>[
      ...normalizedHistory,
      <String, String>{'role': 'user', 'content': prompt},
    ];

    final String systemPrompt = _buildSystemPrompt(clientContext);

    bool fallbackUsed = false;
    String modelUsed = primaryModel;

    try {
      final String reply = await _generateWithRetry(
        apiKey: apiKey,
        model: primaryModel,
        systemPrompt: systemPrompt,
        history: allMessages,
        temperature: responseMode == AssistantResponseMode.deep ? 0.35 : 0.45,
        maxOutputTokens: responseMode == AssistantResponseMode.deep ? 900 : 650,
        thinkingLevel: responseMode == AssistantResponseMode.deep
            ? 'medium'
            : 'minimal',
        attempts: 3,
      );

      return AssistantReply(
        reply: reply,
        modelUsed: modelUsed,
        fallbackUsed: fallbackUsed,
        generatedAt: DateTime.now().toUtc(),
        suggestions: _buildSuggestedPrompts(prompt),
      );
    } catch (_) {
      if (responseMode != AssistantResponseMode.deep) {
        rethrow;
      }
    }

    fallbackUsed = true;
    modelUsed = AiRuntimeConfig.chatFastModel;

    final String fallbackReply = await _generateWithRetry(
      apiKey: apiKey,
      model: modelUsed,
      systemPrompt: systemPrompt,
      history: allMessages,
      temperature: 0.45,
      maxOutputTokens: 650,
      thinkingLevel: 'minimal',
      attempts: 3,
    );

    return AssistantReply(
      reply: fallbackReply,
      modelUsed: modelUsed,
      fallbackUsed: fallbackUsed,
      generatedAt: DateTime.now().toUtc(),
      suggestions: _buildSuggestedPrompts(prompt),
    );
  }

  Future<VoiceAssistantReply> sendVoiceTurn({
    required String transcript,
    required List<Map<String, String>> history,
    required Map<String, dynamic> clientContext,
  }) async {
    final String prompt = transcript.trim();
    if (prompt.isEmpty) {
      throw StateError('Transcript cannot be empty.');
    }

    final String apiKey = _requireApiKey();
    final List<Map<String, String>> normalizedHistory = _historyWindow(history);
    final List<Map<String, String>> allMessages = <Map<String, String>>[
      ...normalizedHistory,
      <String, String>{'role': 'user', 'content': prompt},
    ];
    final String systemPrompt = _buildSystemPrompt(clientContext);

    bool fallbackUsed = false;
    String modelUsed = AiRuntimeConfig.voiceModel;

    String reply;
    try {
      reply = await _generateWithRetry(
        apiKey: apiKey,
        model: modelUsed,
        systemPrompt: systemPrompt,
        history: allMessages,
        temperature: 0.3,
        maxOutputTokens: 420,
        thinkingLevel: 'minimal',
        attempts: 2,
      );
    } catch (_) {
      fallbackUsed = true;
      modelUsed = AiRuntimeConfig.chatFastModel;
      reply = await _generateWithRetry(
        apiKey: apiKey,
        model: modelUsed,
        systemPrompt: systemPrompt,
        history: allMessages,
        temperature: 0.35,
        maxOutputTokens: 420,
        thinkingLevel: 'minimal',
        attempts: 2,
      );
    }

    return VoiceAssistantReply(
      reply: reply,
      modelUsed: modelUsed,
      fallbackUsed: fallbackUsed,
      generatedAt: DateTime.now().toUtc(),
      speechChunks: _splitSpeechChunks(reply),
    );
  }

  String _buildLiveSessionSystemInstruction({
    required List<Map<String, String>> history,
    required Map<String, dynamic> clientContext,
  }) {
    final String contextJson = jsonEncode(clientContext);
    final String clippedContext = contextJson.length > 18000
        ? contextJson.substring(0, 18000)
        : contextJson;

    final List<Map<String, String>> recentHistory = _historyWindow(history);
    final String historyText = recentHistory.isEmpty
        ? 'No prior turns.'
        : recentHistory
              .map((Map<String, String> row) {
                final String role = row['role'] == 'assistant'
                    ? 'ASSISTANT'
                    : 'USER';
                final String content = (row['content'] ?? '')
                    .replaceAll('\n', ' ')
                    .trim();
                return '$role: $content';
              })
              .join('\n');

    return <String>[
      'You are FinMate, a voice-first personal finance assistant for Indian college students.',
      'Speak naturally and clearly, with short actionable responses for voice.',
      'Use only the supplied user context JSON as source of truth.',
      'If context is missing, say you do not have enough data and suggest what to track.',
      'Never claim to execute real banking operations.',
      'USER_CONTEXT_JSON:',
      clippedContext,
      'RECENT_CONVERSATION:',
      historyText,
      'Listen to user audio and respond with concise, practical voice guidance.',
    ].join('\n');
  }

  Future<String> _generateWithRetry({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required double temperature,
    required int maxOutputTokens,
    required String thinkingLevel,
    required int attempts,
  }) async {
    Object? lastError;

    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await _generate(
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          history: history,
          temperature: temperature,
          maxOutputTokens: maxOutputTokens,
          thinkingLevel: thinkingLevel,
        );
      } catch (error) {
        lastError = error;
        if (attempt < attempts) {
          await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
        }
      }
    }

    throw lastError ?? StateError('Gemini request failed.');
  }

  Future<String> _generate({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required double temperature,
    required int maxOutputTokens,
    required String thinkingLevel,
  }) async {
    final Uri uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/$model:generateContent',
      <String, String>{'key': apiKey},
    );

    final Map<String, dynamic> payload = <String, dynamic>{
      'systemInstruction': <String, dynamic>{
        'parts': <Map<String, String>>[
          <String, String>{'text': systemPrompt},
        ],
      },
      'contents': history.map((Map<String, String> message) {
        final String role = message['role'] == 'assistant' ? 'model' : 'user';
        return <String, dynamic>{
          'role': role,
          'parts': <Map<String, String>>[
            <String, String>{'text': message['content'] ?? ''},
          ],
        };
      }).toList(),
      'generationConfig': <String, dynamic>{
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
        'thinkingConfig': <String, String>{'thinkingLevel': thinkingLevel},
      },
    };

    final http.Response response = await _httpClient
        .post(
          uri,
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Gemini API error (${response.statusCode}): ${response.body.substring(0, response.body.length.clamp(0, 320))}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Gemini API returned an invalid response payload.');
    }

    final String text = _extractText(decoded);
    if (text.isEmpty) {
      throw StateError('Gemini response did not contain text output.');
    }
    return text;
  }

  String _extractText(Map<String, dynamic> payload) {
    final dynamic rawCandidates = payload['candidates'];
    if (rawCandidates is! List<dynamic> || rawCandidates.isEmpty) {
      return '';
    }

    final dynamic firstCandidate = rawCandidates.first;
    if (firstCandidate is! Map<String, dynamic>) {
      return '';
    }
    final dynamic content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) {
      return '';
    }
    final dynamic parts = content['parts'];
    if (parts is! List<dynamic>) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();
    for (final dynamic part in parts) {
      if (part is! Map<String, dynamic>) {
        continue;
      }
      final dynamic text = part['text'];
      if (text is String) {
        buffer.write(text);
      }
    }
    return buffer.toString().trim();
  }

  String _buildSystemPrompt(Map<String, dynamic> clientContext) {
    final String contextJson = jsonEncode(clientContext);
    return <String>[
      'You are FinMate, a personal finance assistant for Indian college students.',
      'Focus on spending summaries, budgets, savings goals, transaction explanations, and split expenses.',
      'Use only the supplied user context. Never infer data from outside this context.',
      'Keep responses practical, concise, and actionable. Mention assumptions clearly.',
      'Never claim to execute real banking operations.',
      'USER_CONTEXT_JSON:',
      contextJson.length > 12000
          ? contextJson.substring(0, 12000)
          : contextJson,
    ].join('\n');
  }

  List<Map<String, String>> _historyWindow(List<Map<String, String>> history) {
    final List<Map<String, String>> cleaned = history
        .map((Map<String, String> row) {
          final String role = row['role'] == 'assistant' ? 'assistant' : 'user';
          final String content = (row['content'] ?? '').trim();
          return <String, String>{'role': role, 'content': content};
        })
        .where((Map<String, String> row) => row['content']!.isNotEmpty)
        .toList();

    if (cleaned.length <= 14) {
      return cleaned;
    }

    return cleaned.sublist(cleaned.length - 14);
  }

  List<String> _buildSuggestedPrompts(String input) {
    final String lower = input.toLowerCase();
    if (lower.contains('budget')) {
      return const <String>[
        'Show categories where I can cut spend this month.',
        'What daily cap should I follow for the rest of this month?',
        'How far am I from my monthly budget threshold?',
      ];
    }
    if (lower.contains('split')) {
      return const <String>[
        'Who should settle first in my active split groups?',
        'Explain my pending split balances in simple terms.',
        'Draft a polite settlement reminder message.',
      ];
    }
    if (lower.contains('save') || lower.contains('goal')) {
      return const <String>[
        'Which savings goal should I prioritize now?',
        'How much should I set aside weekly for my goals?',
        'Give me a realistic savings plan from my current trends.',
      ];
    }
    return const <String>[
      'Summarize my spending in one minute.',
      'What should I do this week to stay financially healthy?',
      'Explain my recent transactions and red flags.',
    ];
  }

  List<String> _splitSpeechChunks(String reply) {
    final List<String> chunks = reply
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    if (chunks.isNotEmpty) {
      return chunks;
    }

    if (reply.trim().isEmpty) {
      return const <String>[];
    }

    return <String>[reply.trim()];
  }

  String _requireApiKey() {
    final String value = AiRuntimeConfig.apiKey.trim();
    if (value.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY is missing. Set it in root .env or pass --dart-define=GEMINI_API_KEY=<your_key>.',
      );
    }
    return value;
  }
}

class VoiceLiveSession {
  VoiceLiveSession._({
    required WebSocketChannel channel,
    required this.model,
    required this.responseModalities,
    this.systemInstruction,
    this.voiceName,
  })
    : _channel = channel {
    _streamSubscription = _channel.stream.listen(
      _handleRawMessage,
      onError: _handleStreamError,
      onDone: _handleStreamDone,
      cancelOnError: false,
    );
  }

  static Future<VoiceLiveSession> connect({
    required String apiKey,
    required String model,
    required List<String> responseModalities,
    String? systemInstruction,
    String? voiceName,
  }) async {
    final Uri uri = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    final VoiceLiveSession session = VoiceLiveSession._(
      channel: WebSocketChannel.connect(uri),
      model: model,
      responseModalities: responseModalities,
      systemInstruction: systemInstruction,
      voiceName: voiceName,
    );

    session._sendSetup();
    return session;
  }

  final WebSocketChannel _channel;
  final String model;
  final List<String> responseModalities;
  final String? systemInstruction;
  final String? voiceName;
  final StreamController<VoiceLiveEvent> _eventsController =
      StreamController<VoiceLiveEvent>.broadcast();
  final StringBuffer _turnTextBuffer = StringBuffer();

  late final StreamSubscription<dynamic> _streamSubscription;
  bool _closed = false;

  Stream<VoiceLiveEvent> get events => _eventsController.stream;

  Future<void> sendUserText(String text) async {
    if (_closed) {
      throw StateError('Live voice session is already closed.');
    }

    final String prompt = text.trim();
    if (prompt.isEmpty) {
      throw StateError('Prompt cannot be empty.');
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'client_content': <String, dynamic>{
        'turn_complete': true,
        'turns': <Map<String, dynamic>>[
          <String, dynamic>{
            'role': 'user',
            'parts': <Map<String, String>>[
              <String, String>{'text': prompt},
            ],
          },
        ],
      },
    };

    _channel.sink.add(jsonEncode(payload));
  }

  Future<void> sendRealtimeAudioChunk(
    Uint8List pcm16Chunk, {
    required int sampleRate,
  }) async {
    if (_closed) {
      throw StateError('Live voice session is already closed.');
    }

    if (pcm16Chunk.isEmpty) {
      return;
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'realtime_input': <String, dynamic>{
        'media_chunks': <Map<String, String>>[
          <String, String>{
            'mime_type': 'audio/pcm;rate=$sampleRate',
            'data': base64Encode(pcm16Chunk),
          },
        ],
      },
    };

    _channel.sink.add(jsonEncode(payload));
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    _turnTextBuffer.clear();

    await _streamSubscription.cancel();
    await _channel.sink.close();

    if (!_eventsController.isClosed) {
      await _eventsController.close();
    }
  }

  void _sendSetup() {
    final String normalizedVoiceName = (voiceName ?? '').trim();
    final String normalizedInstruction = (systemInstruction ?? '').trim();

    final Map<String, dynamic> setup = <String, dynamic>{
      'model': model,
      'response_modalities': responseModalities,
    };

    if (normalizedInstruction.isNotEmpty) {
      setup['system_instruction'] = <String, dynamic>{
        'parts': <Map<String, String>>[
          <String, String>{'text': normalizedInstruction},
        ],
      };
    }

    if (normalizedVoiceName.isNotEmpty) {
      setup['speech_config'] = <String, dynamic>{
        'voice_config': <String, dynamic>{
          'prebuilt_voice_config': <String, String>{
            'voice_name': normalizedVoiceName,
          },
        },
      };
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'setup': setup,
    };
    _channel.sink.add(jsonEncode(payload));
  }

  void _handleRawMessage(dynamic rawMessage) {
    final Map<String, dynamic>? payload = _decodePayload(rawMessage);
    if (payload == null) {
      return;
    }

    if (payload.containsKey('setupComplete') ||
        payload.containsKey('setup_complete')) {
      _emit(VoiceLiveEvent.setupComplete());
    }

    final Map<String, dynamic>? rootError = _asMap(payload['error']);
    if (rootError != null) {
      final String message =
          (rootError['message'] ?? rootError.toString()).toString();
      _emit(VoiceLiveEvent.error('Live API error: $message'));
      return;
    }

    final Map<String, dynamic>? serverContent =
        _asMap(payload['serverContent']) ?? _asMap(payload['server_content']);

    if (serverContent == null) {
      return;
    }

    if (_isTrue(serverContent['interrupted'])) {
      _turnTextBuffer.clear();
      _emit(VoiceLiveEvent.interrupted());
    }

    final Map<String, dynamic>? modelTurn =
        _asMap(serverContent['modelTurn']) ??
        _asMap(serverContent['model_turn']);

    if (modelTurn != null) {
      _emitAudioChunks(modelTurn);

      final String delta = _extractModelText(modelTurn);
      if (delta.isNotEmpty) {
        _turnTextBuffer.write(delta);
        _emit(VoiceLiveEvent.textDelta(delta));
      }
    }

    final bool turnComplete =
        _isTrue(serverContent['turnComplete']) ||
        _isTrue(serverContent['turn_complete']) ||
        _isTrue(serverContent['generationComplete']) ||
        _isTrue(serverContent['generation_complete']);

    if (turnComplete) {
      final String fullText = _turnTextBuffer.toString().trim();
      _emit(VoiceLiveEvent.turnComplete(fullText));
      _turnTextBuffer.clear();
    }
  }

  void _emitAudioChunks(Map<String, dynamic> modelTurn) {
    final dynamic rawParts = modelTurn['parts'];
    if (rawParts is! List<dynamic>) {
      return;
    }

    for (final dynamic rawPart in rawParts) {
      final Map<String, dynamic>? part = _asMap(rawPart);
      if (part == null) {
        continue;
      }

      final Map<String, dynamic>? inlineData =
          _asMap(part['inlineData']) ?? _asMap(part['inline_data']);
      if (inlineData == null) {
        continue;
      }

      final dynamic encoded = inlineData['data'];
      if (encoded is! String || encoded.isEmpty) {
        continue;
      }

      try {
        final Uint8List bytes = base64Decode(encoded);
        if (bytes.isEmpty) {
          continue;
        }

        final String mimeType = (inlineData['mimeType'] ?? inlineData['mime_type'] ?? '')
            .toString();
        final int? sampleRate = _extractRateFromMimeType(mimeType);
        _emit(VoiceLiveEvent.audioChunk(bytes, sampleRate: sampleRate));
      } catch (_) {
        continue;
      }
    }
  }

  void _handleStreamError(Object error) {
    if (_closed) {
      return;
    }
    _emit(VoiceLiveEvent.error('Live voice connection failed: $error'));
  }

  void _handleStreamDone() {
    if (_closed) {
      return;
    }
    _turnTextBuffer.clear();
    _emit(VoiceLiveEvent.disconnected());
  }

  void _emit(VoiceLiveEvent event) {
    if (_eventsController.isClosed) {
      return;
    }
    _eventsController.add(event);
  }

  static Map<String, dynamic>? _decodePayload(dynamic rawMessage) {
    dynamic decoded;
    try {
      if (rawMessage is String) {
        decoded = jsonDecode(rawMessage);
      } else if (rawMessage is List<int>) {
        decoded = jsonDecode(utf8.decode(rawMessage));
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }

    return _asMap(decoded);
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final Map<String, dynamic> normalized = <String, dynamic>{};
      value.forEach((dynamic key, dynamic entryValue) {
        normalized[key.toString()] = entryValue;
      });
      return normalized;
    }
    return null;
  }

  static bool _isTrue(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  static String _extractModelText(Map<String, dynamic> modelTurn) {
    final dynamic rawParts = modelTurn['parts'];
    if (rawParts is! List<dynamic>) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();
    for (final dynamic rawPart in rawParts) {
      final Map<String, dynamic>? part = _asMap(rawPart);
      if (part == null) {
        continue;
      }

      final dynamic text = part['text'];
      if (text is String && text.isNotEmpty) {
        buffer.write(text);
      }
    }

    return buffer.toString();
  }

  static int? _extractRateFromMimeType(String mimeType) {
    final RegExpMatch? match = RegExp(r'rate\s*=\s*(\d+)').firstMatch(
      mimeType,
    );
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }
}
