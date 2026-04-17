import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:student_fin_os/core/config/ai_runtime_config.dart';
import 'package:student_fin_os/models/assistant_models.dart';

class AssistantService {
  AssistantService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

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
        'GEMINI_API_KEY is missing. Start Flutter with --dart-define=GEMINI_API_KEY=<your_key>.',
      );
    }
    return value;
  }
}
