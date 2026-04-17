import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiRuntimeConfig {
  static const String _defineApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _defineChatFastModel = String.fromEnvironment(
    'GEMINI_CHAT_FAST_MODEL',
    defaultValue: 'models/gemini-2.5-flash',
  );
  static const String _defineChatDeepModel = String.fromEnvironment(
    'GEMINI_CHAT_DEEP_MODEL',
    defaultValue: 'models/gemini-2.5-pro',
  );
  static const String _defineVoiceModel = String.fromEnvironment(
    'GEMINI_VOICE_MODEL',
    defaultValue: 'models/gemini-3.1-flash-live-preview',
  );

  static String get apiKey => _read('GEMINI_API_KEY', _defineApiKey);

  static String get chatFastModel =>
      _read('GEMINI_CHAT_FAST_MODEL', _defineChatFastModel);

  static String get chatDeepModel =>
      _read('GEMINI_CHAT_DEEP_MODEL', _defineChatDeepModel);

  static String get voiceModel =>
      _read('GEMINI_VOICE_MODEL', _defineVoiceModel);

  static String _read(String key, String fallback) {
    final String? raw = dotenv.env[key];
    if (raw != null && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return fallback;
  }
}
