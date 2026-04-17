class AiRuntimeConfig {
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String chatFastModel = String.fromEnvironment(
    'GEMINI_CHAT_FAST_MODEL',
    defaultValue: 'models/gemini-2.5-flash',
  );

  static const String chatDeepModel = String.fromEnvironment(
    'GEMINI_CHAT_DEEP_MODEL',
    defaultValue: 'models/gemini-2.5-pro',
  );

  static const String voiceModel = String.fromEnvironment(
    'GEMINI_VOICE_MODEL',
    defaultValue: 'models/gemini-3.1-flash-live-preview',
  );
}
