import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiRuntimeConfig {
  static const String _defineApiKey = String.fromEnvironment('AI_API_KEY');
  static const String _defineChatFastModel = String.fromEnvironment(
    'AI_CHAT_FAST_MODEL',
    defaultValue: 'gemini-2.0-flash',
  );
  static const String _defineChatDeepModel = String.fromEnvironment(
    'AI_CHAT_DEEP_MODEL',
    defaultValue: 'gemini-1.5-pro',
  );
  static const String _defineVoiceModel = String.fromEnvironment(
    'AI_VOICE_MODEL',
    defaultValue: 'models/gemini-2.0-flash-live-001',
  );
  static const String _defineLiveVoiceName = String.fromEnvironment(
    'AI_LIVE_VOICE_NAME',
    defaultValue: 'Puck',
  );
  static const String _defineLiveInputSampleRate = String.fromEnvironment(
    'AI_LIVE_INPUT_SAMPLE_RATE',
    defaultValue: '16000',
  );
  static const String _defineLiveOutputSampleRate = String.fromEnvironment(
    'AI_LIVE_OUTPUT_SAMPLE_RATE',
    defaultValue: '24000',
  );

  static String get apiKey => _readAny(<String>['AI_API_KEY', 'GEMINI_API_KEY'], _defineApiKey);

  static String get chatFastModel =>
      _readAny(<String>['AI_CHAT_FAST_MODEL', 'GEMINI_CHAT_FAST_MODEL'], _defineChatFastModel);

  static String get chatDeepModel =>
      _readAny(<String>['AI_CHAT_DEEP_MODEL', 'GEMINI_CHAT_DEEP_MODEL'], _defineChatDeepModel);

  static String get voiceModel =>
      _readAny(<String>['AI_VOICE_MODEL', 'GEMINI_VOICE_MODEL'], _defineVoiceModel);

    static String get liveVoiceName =>
      _readAny(<String>['AI_LIVE_VOICE_NAME', 'GEMINI_LIVE_VOICE_NAME'], _defineLiveVoiceName);

    static int get liveInputSampleRate =>
      _readIntAny(
        <String>['AI_LIVE_INPUT_SAMPLE_RATE', 'GEMINI_LIVE_INPUT_SAMPLE_RATE'],
        _defineLiveInputSampleRate,
      );

    static int get liveOutputSampleRate =>
      _readIntAny(
        <String>['AI_LIVE_OUTPUT_SAMPLE_RATE', 'GEMINI_LIVE_OUTPUT_SAMPLE_RATE'],
        _defineLiveOutputSampleRate,
      );

  static String _read(String key, String fallback) {
    final String? raw = dotenv.env[key];
    if (raw != null && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return fallback;
  }

  static String _readAny(List<String> keys, String fallback) {
    for (final String key in keys) {
      final String value = _read(key, '');
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static int _readIntAny(List<String> keys, String fallback) {
    final String value = _readAny(keys, fallback);
    return int.tryParse(value) ?? int.tryParse(fallback) ?? 16000;
  }
}
