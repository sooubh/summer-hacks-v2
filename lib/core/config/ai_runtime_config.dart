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
  static const String _defineLiveVoiceName = String.fromEnvironment(
    'GEMINI_LIVE_VOICE_NAME',
    defaultValue: 'Puck',
  );
  static const String _defineLiveInputSampleRate = String.fromEnvironment(
    'GEMINI_LIVE_INPUT_SAMPLE_RATE',
    defaultValue: '16000',
  );
  static const String _defineLiveOutputSampleRate = String.fromEnvironment(
    'GEMINI_LIVE_OUTPUT_SAMPLE_RATE',
    defaultValue: '24000',
  );

  static String get apiKey => _read('GEMINI_API_KEY', _defineApiKey);

  static String get chatFastModel =>
      _read('GEMINI_CHAT_FAST_MODEL', _defineChatFastModel);

  static String get chatDeepModel =>
      _read('GEMINI_CHAT_DEEP_MODEL', _defineChatDeepModel);

  static String get voiceModel =>
      _read('GEMINI_VOICE_MODEL', _defineVoiceModel);

    static String get liveVoiceName =>
      _read('GEMINI_LIVE_VOICE_NAME', _defineLiveVoiceName);

    static int get liveInputSampleRate =>
      _readInt('GEMINI_LIVE_INPUT_SAMPLE_RATE', _defineLiveInputSampleRate);

    static int get liveOutputSampleRate =>
      _readInt('GEMINI_LIVE_OUTPUT_SAMPLE_RATE', _defineLiveOutputSampleRate);

  static String _read(String key, String fallback) {
    final String? raw = dotenv.env[key];
    if (raw != null && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return fallback;
  }

  static int _readInt(String key, String fallback) {
    final String value = _read(key, fallback);
    return int.tryParse(value) ?? int.tryParse(fallback) ?? 16000;
  }
}
