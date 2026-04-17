import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:student_fin_os/core/config/ai_runtime_config.dart';
import 'package:student_fin_os/models/assistant_models.dart';
import 'package:student_fin_os/providers/assistant_providers.dart';

class VoiceAssistantSheet extends ConsumerStatefulWidget {
  const VoiceAssistantSheet({super.key});

  @override
  ConsumerState<VoiceAssistantSheet> createState() =>
      _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends ConsumerState<VoiceAssistantSheet> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _manualController = TextEditingController();

  bool _voiceReady = false;
  bool _initializing = true;
  bool _speechSubmissionInFlight = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeVoiceRuntime());
  }

  @override
  void dispose() {
    unawaited(_speech.stop());
    unawaited(_speech.cancel());
    unawaited(_tts.stop());
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _initializeVoiceRuntime() async {
    try {
      final bool available = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          ref
              .read(voiceAssistantControllerProvider.notifier)
              .setError('Microphone error: ${error.errorMsg}');
        },
        onStatus: (String status) {
          if (!mounted) {
            return;
          }
          final VoiceAssistantState current = ref.read(
            voiceAssistantControllerProvider,
          );
          if (status == 'done' &&
              current.status == VoiceAssistantStatus.listening &&
              !_speechSubmissionInFlight) {
            unawaited(_stopListeningAndProcess());
          }
        },
      );

      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.47);
      await _tts.setPitch(1.0);
      await _tts.setLanguage('en-IN');
      _tts.setErrorHandler((dynamic message) {
        if (!mounted) {
          return;
        }
        ref
            .read(voiceAssistantControllerProvider.notifier)
            .setError('Unable to play assistant speech right now.');
      });

      if (mounted) {
        setState(() {
          _voiceReady = available;
          _initializing = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ref
            .read(voiceAssistantControllerProvider.notifier)
            .setError(
              'Voice runtime initialization failed. You can still use text input.',
            );
        setState(() {
          _voiceReady = false;
          _initializing = false;
        });
      }
    }
  }

  Future<void> _toggleMicrophone(VoiceAssistantState state) async {
    if (_initializing || state.status == VoiceAssistantStatus.processing) {
      return;
    }

    if (state.status == VoiceAssistantStatus.listening) {
      await _stopListeningAndProcess();
      return;
    }

    if (state.status == VoiceAssistantStatus.speaking) {
      await _tts.stop();
      ref
          .read(voiceAssistantControllerProvider.notifier)
          .setStatus(VoiceAssistantStatus.idle);
    }

    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_voiceReady) {
      ref
          .read(voiceAssistantControllerProvider.notifier)
          .setError(
            'Microphone access is not available on this device/session.',
          );
      return;
    }

    await _tts.stop();

    final VoiceAssistantController controller = ref.read(
      voiceAssistantControllerProvider.notifier,
    );
    controller.updateTranscript('');
    controller.setStatus(VoiceAssistantStatus.listening);

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) {
          return;
        }

        controller.updateTranscript(result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          unawaited(_stopListeningAndProcess());
        }
      },
      pauseFor: const Duration(seconds: 2),
      listenFor: const Duration(seconds: 25),
      localeId: 'en_IN',
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _stopListeningAndProcess() async {
    if (_speechSubmissionInFlight) {
      return;
    }

    _speechSubmissionInFlight = true;
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }

      final VoiceAssistantController controller = ref.read(
        voiceAssistantControllerProvider.notifier,
      );
      final VoiceAssistantState state = ref.read(
        voiceAssistantControllerProvider,
      );
      final String transcript = state.transcript.trim();

      if (transcript.isEmpty) {
        controller.setStatus(VoiceAssistantStatus.idle);
        return;
      }

      final VoiceAssistantReply? reply = await controller.submitTranscript(
        transcript,
      );
      if (reply == null) {
        return;
      }

      await _speakReply(reply);
    } finally {
      _speechSubmissionInFlight = false;
    }
  }

  Future<void> _submitManualPrompt() async {
    final String prompt = _manualController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    _manualController.clear();
    await _tts.stop();
    if (_speech.isListening) {
      await _speech.stop();
    }

    final VoiceAssistantReply? reply = await ref
        .read(voiceAssistantControllerProvider.notifier)
        .submitTranscript(prompt);

    if (reply == null) {
      return;
    }

    await _speakReply(reply);
  }

  Future<void> _speakReply(VoiceAssistantReply reply) async {
    final VoiceAssistantController controller = ref.read(
      voiceAssistantControllerProvider.notifier,
    );
    controller.setStatus(VoiceAssistantStatus.speaking);

    final List<String> chunks = reply.speechChunks.isEmpty
        ? <String>[reply.reply]
        : reply.speechChunks;

    for (final String chunk in chunks) {
      if (!mounted) {
        return;
      }

      final VoiceAssistantStatus status = ref
          .read(voiceAssistantControllerProvider)
          .status;
      if (status != VoiceAssistantStatus.speaking) {
        break;
      }

      await _tts.speak(chunk);
    }

    if (!mounted) {
      return;
    }

    if (ref.read(voiceAssistantControllerProvider).status ==
        VoiceAssistantStatus.speaking) {
      controller.setStatus(VoiceAssistantStatus.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final VoiceAssistantState state = ref.watch(
      voiceAssistantControllerProvider,
    );

    final List<AssistantMessage> recentMessages = state.messages.length <= 8
        ? state.messages
        : state.messages.sublist(state.messages.length - 8);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Voice Assistant',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor(
                  context,
                  state.status,
                ).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  Icon(_statusIcon(state.status), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusLabel(state.status),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                state.transcript.isEmpty
                    ? 'Tap the mic and ask about spending, budgets, savings goals, transactions, or split expenses.'
                    : state.transcript,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (state.activeModel != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Model: ${state.activeModel} (voice target: ${AiRuntimeConfig.voiceModel})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: recentMessages.isEmpty
                  ? Center(
                      child: Text(
                        'Your recent voice conversation appears here.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: recentMessages.length,
                      itemBuilder: (BuildContext context, int index) {
                        final AssistantMessage message = recentMessages[index];
                        final bool isUser = message.role == AssistantRole.user;

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
                            constraints: const BoxConstraints(maxWidth: 440),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.2)
                                  : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(message.content),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'hh:mm a',
                                  ).format(message.timestamp.toLocal()),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _manualController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitManualPrompt(),
                    decoration: const InputDecoration(
                      labelText: 'Manual fallback',
                      hintText: 'Type if microphone is unavailable',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: state.status == VoiceAssistantStatus.processing
                      ? null
                      : _submitManualPrompt,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: 'Voice assistant microphone control',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _initializing
                      ? null
                      : () => _toggleMicrophone(state),
                  icon: Icon(_micIcon(state.status)),
                  label: Text(_micLabel(state.status)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(VoiceAssistantStatus status) {
    switch (status) {
      case VoiceAssistantStatus.idle:
        return 'Idle';
      case VoiceAssistantStatus.listening:
        return 'Listening... speak now';
      case VoiceAssistantStatus.processing:
        return 'Processing your request';
      case VoiceAssistantStatus.speaking:
        return 'Speaking response (tap mic to interrupt)';
      case VoiceAssistantStatus.error:
        return 'Error';
    }
  }

  IconData _statusIcon(VoiceAssistantStatus status) {
    switch (status) {
      case VoiceAssistantStatus.idle:
        return Icons.pause_circle_outline;
      case VoiceAssistantStatus.listening:
        return Icons.mic;
      case VoiceAssistantStatus.processing:
        return Icons.hourglass_top;
      case VoiceAssistantStatus.speaking:
        return Icons.volume_up;
      case VoiceAssistantStatus.error:
        return Icons.error_outline;
    }
  }

  IconData _micIcon(VoiceAssistantStatus status) {
    switch (status) {
      case VoiceAssistantStatus.listening:
        return Icons.stop_circle_outlined;
      case VoiceAssistantStatus.speaking:
        return Icons.mic;
      case VoiceAssistantStatus.processing:
        return Icons.hourglass_bottom;
      case VoiceAssistantStatus.error:
      case VoiceAssistantStatus.idle:
        return Icons.mic_none;
    }
  }

  String _micLabel(VoiceAssistantStatus status) {
    switch (status) {
      case VoiceAssistantStatus.listening:
        return 'Stop and send';
      case VoiceAssistantStatus.speaking:
        return 'Interrupt and listen';
      case VoiceAssistantStatus.processing:
        return 'Processing...';
      case VoiceAssistantStatus.error:
      case VoiceAssistantStatus.idle:
        return 'Start listening';
    }
  }

  Color _statusColor(BuildContext context, VoiceAssistantStatus status) {
    switch (status) {
      case VoiceAssistantStatus.listening:
        return Theme.of(context).colorScheme.primary;
      case VoiceAssistantStatus.processing:
        return Colors.amber;
      case VoiceAssistantStatus.speaking:
        return Theme.of(context).colorScheme.secondary;
      case VoiceAssistantStatus.error:
        return Theme.of(context).colorScheme.error;
      case VoiceAssistantStatus.idle:
        return Theme.of(context).colorScheme.outline;
    }
  }
}
