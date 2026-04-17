import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:student_fin_os/models/assistant_models.dart';

class AssistantService {
  AssistantService(this._functions);

  final FirebaseFunctions _functions;

  Future<AssistantReply> sendChatMessage({
    required String message,
    required List<Map<String, String>> history,
    required AssistantResponseMode responseMode,
    required Map<String, dynamic> clientContext,
  }) async {
    final HttpsCallableResult<dynamic> result = await _callWithRetry(
      functionName: 'assistantChatReply',
      payload: <String, dynamic>{
        'message': message,
        'history': history,
        'responseMode': responseMode.wireValue,
        'clientContext': clientContext,
      },
      attempts: 3,
    );

    final Map<String, dynamic> data = _asMap(result.data);
    final String reply = (data['reply'] as String? ?? '').trim();
    if (reply.isEmpty) {
      throw StateError('Assistant returned an empty reply.');
    }

    return AssistantReply(
      reply: reply,
      modelUsed: data['modelUsed'] as String? ?? '',
      fallbackUsed: data['fallbackUsed'] as bool? ?? false,
      generatedAt: _parseTimestamp(data['generatedAt']),
      suggestions: _asStringList(data['suggestions']),
    );
  }

  Future<VoiceAssistantReply> sendVoiceTurn({
    required String transcript,
    required List<Map<String, String>> history,
    required Map<String, dynamic> clientContext,
  }) async {
    final HttpsCallableResult<dynamic> result = await _callWithRetry(
      functionName: 'assistantVoiceReply',
      payload: <String, dynamic>{
        'transcript': transcript,
        'history': history,
        'clientContext': clientContext,
      },
      attempts: 3,
    );

    final Map<String, dynamic> data = _asMap(result.data);
    final String reply = (data['reply'] as String? ?? '').trim();
    if (reply.isEmpty) {
      throw StateError('Voice assistant returned an empty reply.');
    }

    return VoiceAssistantReply(
      reply: reply,
      modelUsed: data['modelUsed'] as String? ?? '',
      fallbackUsed: data['fallbackUsed'] as bool? ?? false,
      generatedAt: _parseTimestamp(data['generatedAt']),
      speechChunks: _asStringList(data['speechChunks']),
    );
  }

  Future<HttpsCallableResult<dynamic>> _callWithRetry({
    required String functionName,
    required Map<String, dynamic> payload,
    required int attempts,
  }) async {
    Object? lastError;

    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        final HttpsCallable callable = _functions.httpsCallable(functionName);
        return await callable.call(payload);
      } catch (error) {
        lastError = error;
        if (attempt < attempts) {
          await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
        }
      }
    }

    throw lastError ?? StateError('Unknown assistant invocation failure.');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic val) =>
            MapEntry<String, dynamic>(key.toString(), val),
      );
    }
    return <String, dynamic>{};
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List<dynamic>) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }
    return DateTime.now().toUtc();
  }
}
