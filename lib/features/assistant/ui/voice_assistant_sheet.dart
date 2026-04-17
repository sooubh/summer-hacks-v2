import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart' show Level;
import 'package:student_fin_os/core/config/ai_runtime_config.dart';
import 'package:student_fin_os/models/assistant_models.dart';
import 'package:student_fin_os/providers/assistant_providers.dart';
import 'package:student_fin_os/services/assistant_service.dart';

class VoiceAssistantSheet extends ConsumerStatefulWidget {
  const VoiceAssistantSheet({super.key});

  @override
  ConsumerState<VoiceAssistantSheet> createState() =>
      _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends ConsumerState<VoiceAssistantSheet> {
  final FlutterSoundRecorder _pcmRecorder = FlutterSoundRecorder(
    logLevel: Level.warning,
  );
  final FlutterSoundPlayer _pcmPlayer = FlutterSoundPlayer(
    logLevel: Level.warning,
  );
  final TextEditingController _manualController = TextEditingController();
  final StringBuffer _liveReplyBuffer = StringBuffer();
  final List<Uint8List> _playbackQueue = <Uint8List>[];

  VoiceLiveSession? _liveSession;
  StreamSubscription<VoiceLiveEvent>? _liveEventsSubscription;
  StreamController<Uint8List>? _micPcmController;
  StreamSubscription<Uint8List>? _micPcmSubscription;

  bool _voiceReady = false;
  bool _initializing = true;
  bool _liveSessionConnecting = false;
  bool _micStreamActive = false;
  bool _playbackQueueActive = false;
  bool _pcmRecorderReady = false;
  bool _pcmPlayerReady = false;
  bool _discardCurrentModelTurn = false;
  bool _isDisposing = false;
  final int _liveInputSampleRate = AiRuntimeConfig.liveInputSampleRate;
  int _liveOutputSampleRate = AiRuntimeConfig.liveOutputSampleRate;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeVoiceRuntime());
  }

  @override
  void dispose() {
    _isDisposing = true;
    unawaited(_shutdownVoiceRuntime());
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _shutdownVoiceRuntime() async {
    await _stopMicStream(markProcessing: false, suppressUi: true);
    await _clearPlayback(immediate: true);
    await _disconnectLiveSession(updateState: false);
    await _closeAudioRuntime();
  }

  Future<void> _initializeVoiceRuntime() async {
    try {
      await _pcmRecorder.openRecorder();
      _pcmRecorderReady = true;

      await _pcmPlayer.openPlayer();
      _pcmPlayerReady = true;
      await _restartPcmPlayer(sampleRate: _liveOutputSampleRate);

      if (mounted) {
        setState(() {
          _voiceReady = true;
          _initializing = false;
        });
      }

      unawaited(_connectLiveSession());
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

  Future<void> _closeAudioRuntime() async {
    if (_pcmRecorderReady) {
      try {
        if (!_pcmRecorder.isStopped) {
          await _pcmRecorder.stopRecorder();
        }
      } catch (_) {}
      try {
        await _pcmRecorder.closeRecorder();
      } catch (_) {}
      _pcmRecorderReady = false;
    }

    if (_pcmPlayerReady) {
      try {
        if (!_pcmPlayer.isStopped) {
          await _pcmPlayer.stopPlayer();
        }
      } catch (_) {}
      try {
        await _pcmPlayer.closePlayer();
      } catch (_) {}
      _pcmPlayerReady = false;
    }
  }

  Future<void> _connectLiveSession() async {
    if (!mounted || _isDisposing || _liveSessionConnecting || _liveSession != null) {
      return;
    }

    _liveSessionConnecting = true;
    final VoiceAssistantController controller = ref.read(
      voiceAssistantControllerProvider.notifier,
    );
    controller.setLiveSessionReady(false);

    try {
      final VoiceAssistantState state = ref.read(voiceAssistantControllerProvider);
      final VoiceLiveSession session = await ref
          .read(assistantServiceProvider)
          .openVoiceLiveSession(
            clientContext: ref.read(assistantClientContextProvider),
            history: _historyPayloadForLive(messages: state.messages),
          );

      _liveSession = session;
      _liveEventsSubscription = session.events.listen(
        (VoiceLiveEvent event) {
          unawaited(_handleLiveEvent(event));
        },
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          ref
              .read(voiceAssistantControllerProvider.notifier)
              .setError('Live voice connection failed. Falling back to turn mode.');
          ref
              .read(voiceAssistantControllerProvider.notifier)
              .setLiveSessionReady(false);
        },
        cancelOnError: false,
      );

      controller.setLiveSessionReady(true);
    } catch (_) {
      if (!mounted || _isDisposing) {
        return;
      }
      controller.setLiveSessionReady(false);
      controller.setError('Live voice is unavailable right now. Using fallback mode.');
    } finally {
      _liveSessionConnecting = false;
    }
  }

  Future<void> _disconnectLiveSession({bool updateState = true}) async {
    final StreamSubscription<VoiceLiveEvent>? subscription =
        _liveEventsSubscription;
    _liveEventsSubscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }

    final VoiceLiveSession? session = _liveSession;
    _liveSession = null;
    if (session != null) {
      await session.close();
    }

    if (mounted && updateState && !_isDisposing) {
      ref
          .read(voiceAssistantControllerProvider.notifier)
          .setLiveSessionReady(false);
    }
  }

  Future<void> _handleLiveEvent(VoiceLiveEvent event) async {
    if (!mounted || _isDisposing) {
      return;
    }

    final VoiceAssistantController controller = ref.read(
      voiceAssistantControllerProvider.notifier,
    );

    switch (event.type) {
      case VoiceLiveEventType.setupComplete:
        controller.setLiveSessionReady(true);
        break;
      case VoiceLiveEventType.textDelta:
        if (_discardCurrentModelTurn || event.textDelta.isEmpty) {
          return;
        }

        _liveReplyBuffer.write(event.textDelta);
        final String partialReply = _liveReplyBuffer.toString();
        controller.updateStreamingReply(partialReply);
        if (ref.read(voiceAssistantControllerProvider).status !=
            VoiceAssistantStatus.listening) {
          controller.setStatus(VoiceAssistantStatus.speaking);
        }
        break;
      case VoiceLiveEventType.audioChunk:
        if (_discardCurrentModelTurn || event.audioChunk == null) {
          return;
        }

        if (_micStreamActive) {
          await _stopMicStream(markProcessing: false);
        }

        final int sampleRate = event.audioSampleRate ?? _liveOutputSampleRate;
        if (sampleRate != _liveOutputSampleRate) {
          await _restartPcmPlayer(sampleRate: sampleRate);
        }

        _enqueuePlayback(event.audioChunk!);
        controller.setStatus(VoiceAssistantStatus.speaking);
        break;
      case VoiceLiveEventType.turnComplete:
        if (_discardCurrentModelTurn) {
          _discardCurrentModelTurn = false;
          _liveReplyBuffer.clear();
          await _clearPlayback(immediate: true);
          controller.clearStreamingReply();
          return;
        }

        final String fullReply = event.fullText.trim().isNotEmpty
            ? event.fullText.trim()
            : _liveReplyBuffer.toString().trim();

        if (fullReply.isNotEmpty) {
          controller.completeStreamingReply(fullReply);
        } else {
          controller.clearStreamingReply();
        }

        _liveReplyBuffer.clear();
        if (_playbackQueue.isEmpty && !_micStreamActive) {
          controller.setStatus(VoiceAssistantStatus.idle);
        }
        break;
      case VoiceLiveEventType.interrupted:
        _discardCurrentModelTurn = false;
        _liveReplyBuffer.clear();
        await _clearPlayback(immediate: true);
        controller.clearStreamingReply();
        if (!_micStreamActive) {
          controller.setStatus(VoiceAssistantStatus.idle);
        }
        break;
      case VoiceLiveEventType.disconnected:
        if (_micStreamActive) {
          await _stopMicStream(markProcessing: false, suppressUi: true);
        }
        await _clearPlayback(immediate: true);
        controller.setLiveSessionReady(false);
        await _disconnectLiveSession(updateState: false);
        if (mounted && !_isDisposing) {
          unawaited(_connectLiveSession());
        }
        break;
      case VoiceLiveEventType.error:
        if (_micStreamActive) {
          await _stopMicStream(markProcessing: false, suppressUi: true);
        }
        await _clearPlayback(immediate: true);
        controller.setLiveSessionReady(false);
        controller.setError(
          event.errorMessage ?? 'Live voice session failed. Using fallback mode.',
        );
        await _disconnectLiveSession(updateState: false);
        if (mounted && !_isDisposing) {
          unawaited(_connectLiveSession());
        }
        break;
    }
  }

  Future<void> _restartPcmPlayer({required int sampleRate}) async {
    if (!_pcmPlayerReady || _isDisposing) {
      return;
    }

    if (!_pcmPlayer.isStopped && sampleRate == _liveOutputSampleRate) {
      return;
    }

    if (!_pcmPlayer.isStopped) {
      await _pcmPlayer.stopPlayer();
    }

    await _pcmPlayer.startPlayerFromStream(
      codec: Codec.pcm16,
      sampleRate: sampleRate,
      numChannels: 1,
      interleaved: true,
      bufferSize: 2048,
    );

    _liveOutputSampleRate = sampleRate;
  }

  void _enqueuePlayback(Uint8List audioChunk) {
    if (audioChunk.isEmpty) {
      return;
    }
    _playbackQueue.add(audioChunk);
    unawaited(_drainPlaybackQueue());
  }

  Future<void> _drainPlaybackQueue() async {
    if (_playbackQueueActive) {
      return;
    }

    _playbackQueueActive = true;
    try {
      while (mounted && _playbackQueue.isNotEmpty) {
        if (_discardCurrentModelTurn) {
          _playbackQueue.clear();
          break;
        }

        if (!_pcmPlayerReady) {
          break;
        }

        final Uint8List chunk = _playbackQueue.removeAt(0);
        try {
          if (_pcmPlayer.isStopped) {
            await _restartPcmPlayer(sampleRate: _liveOutputSampleRate);
          }
          await _pcmPlayer.feedUint8FromStream(chunk);
        } catch (_) {
          await _restartPcmPlayer(sampleRate: _liveOutputSampleRate);
          await _pcmPlayer.feedUint8FromStream(chunk);
        }
      }
    } finally {
      _playbackQueueActive = false;
      if (mounted && !_micStreamActive && _playbackQueue.isEmpty) {
        final VoiceAssistantStatus status = ref
            .read(voiceAssistantControllerProvider)
            .status;
        if (status == VoiceAssistantStatus.speaking) {
          ref
              .read(voiceAssistantControllerProvider.notifier)
              .setStatus(VoiceAssistantStatus.idle);
        }
      }
    }
  }

  Future<void> _clearPlayback({bool immediate = false}) async {
    _playbackQueue.clear();
    if (immediate && _pcmPlayerReady) {
      try {
        if (!_pcmPlayer.isStopped) {
          await _pcmPlayer.stopPlayer();
        }
      } catch (_) {}
    }
  }

  Future<void> _startMicStream() async {
    if (_isDisposing) {
      return;
    }

    if (!_voiceReady || !_pcmRecorderReady) {
      ref
          .read(voiceAssistantControllerProvider.notifier)
          .setError('Microphone stream is unavailable on this device/session.');
      return;
    }

    final VoiceLiveSession? session = _liveSession;
    if (session == null) {
      ref
          .read(voiceAssistantControllerProvider.notifier)
          .setError('Live session is not ready yet. Please try again.');
      return;
    }

    if (_micStreamActive) {
      return;
    }

    _discardCurrentModelTurn = false;
    _liveReplyBuffer.clear();
    await _clearPlayback(immediate: true);

    final StreamController<Uint8List> micController =
        StreamController<Uint8List>();
    _micPcmController = micController;
    _micPcmSubscription = micController.stream.listen(
      (Uint8List chunk) {
        unawaited(
          session
              .sendRealtimeAudioChunk(
                chunk,
                sampleRate: _liveInputSampleRate,
              )
              .catchError((Object _) {}),
        );
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        ref
            .read(voiceAssistantControllerProvider.notifier)
            .setError('Microphone stream failed: $error');
      },
      cancelOnError: false,
    );

    try {
      await _pcmRecorder.startRecorder(
        toStream: micController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: _liveInputSampleRate,
        bufferSize: 2048,
        audioSource: AudioSource.defaultSource,
      );

      _micStreamActive = true;

      final VoiceAssistantController controller = ref.read(
        voiceAssistantControllerProvider.notifier,
      );
      controller.startLiveAudioTurn();
      controller.updateTranscript('Listening in live mode... tap again to stop.');
      controller.setStatus(VoiceAssistantStatus.listening);
    } catch (error) {
      await _stopMicStream(markProcessing: false);
      if (mounted) {
        ref
            .read(voiceAssistantControllerProvider.notifier)
            .setError('Unable to start microphone stream: $error');
      }
    }
  }

  Future<void> _stopMicStream({
    required bool markProcessing,
    bool suppressUi = false,
  }) async {
    if (!_micStreamActive && _micPcmSubscription == null && _micPcmController == null) {
      return;
    }

    if (_pcmRecorderReady && !_pcmRecorder.isStopped) {
      try {
        await _pcmRecorder.stopRecorder();
      } catch (_) {}
    }

    _micStreamActive = false;

    final StreamSubscription<Uint8List>? micSubscription = _micPcmSubscription;
    _micPcmSubscription = null;
    if (micSubscription != null) {
      await micSubscription.cancel();
    }

    final StreamController<Uint8List>? micController = _micPcmController;
    _micPcmController = null;
    if (micController != null) {
      await micController.close();
    }

    if (!mounted || _isDisposing || suppressUi) {
      return;
    }

    final VoiceAssistantController controller = ref.read(
      voiceAssistantControllerProvider.notifier,
    );
    if (markProcessing) {
      controller.setStatus(VoiceAssistantStatus.processing);
      controller.updateTranscript('');
      return;
    }

    if (ref.read(voiceAssistantControllerProvider).status ==
        VoiceAssistantStatus.listening) {
      controller.setStatus(VoiceAssistantStatus.idle);
      controller.updateTranscript('');
    }
  }

  Future<void> _toggleMicrophone(VoiceAssistantState state) async {
    if (_initializing) {
      return;
    }

    if (state.status == VoiceAssistantStatus.listening) {
      await _stopMicStream(markProcessing: true);
      return;
    }

    if (state.status == VoiceAssistantStatus.speaking ||
        state.status == VoiceAssistantStatus.processing) {
      _discardCurrentModelTurn = true;
      _liveReplyBuffer.clear();
      await _clearPlayback(immediate: true);
      ref
          .read(voiceAssistantControllerProvider.notifier)
          .clearStreamingReply();
    }

    if (!state.liveSessionReady && !_liveSessionConnecting) {
      await _connectLiveSession();
    }

    await _startMicStream();
  }

  Future<void> _submitManualPrompt() async {
    final String prompt = _manualController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    _manualController.clear();

    if (_micStreamActive) {
      await _stopMicStream(markProcessing: true);
    }

    final VoiceAssistantController controller = ref.read(
      voiceAssistantControllerProvider.notifier,
    );
    final VoiceAssistantState state = ref.read(voiceAssistantControllerProvider);

    if (state.liveSessionReady && _liveSession != null) {
      controller.startLiveUserTurn(prompt);
      try {
        await ref.read(assistantServiceProvider).sendLiveTextPrompt(
          session: _liveSession!,
          prompt: prompt,
        );
      } catch (error) {
        controller.setError('Unable to send prompt to live session: $error');
      }
      return;
    }

    await controller.submitTranscript(prompt);
  }

  List<Map<String, String>> _historyPayloadForLive({
    required List<AssistantMessage> messages,
  }) {
    final List<Map<String, String>> history = messages
        .where((AssistantMessage message) => !message.isError)
        .map((AssistantMessage message) => message.toHistoryPayload())
        .toList(growable: false);

    if (history.length <= 14) {
      return history;
    }

    return history.sublist(history.length - 14);
  }

  @override
  Widget build(BuildContext context) {
    final VoiceAssistantState state = ref.watch(
      voiceAssistantControllerProvider,
    );

    final List<AssistantMessage> recentMessages = state.messages.length <= 8
        ? state.messages
        : state.messages.sublist(state.messages.length - 8);
    final bool showStreamingPreview = state.streamingReply.trim().isNotEmpty;

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: state.liveSessionReady
                    ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12)
                    : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    state.liveSessionReady
                        ? Icons.wifi_tethering
                        : Icons.wifi_tethering_error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.liveSessionReady
                          ? 'Live session connected'
                          : 'Live session unavailable, using fallback mode',
                      style: Theme.of(context).textTheme.bodySmall,
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
                    ? 'Tap the mic, speak naturally, then tap again to stop and send audio.'
                    : state.transcript,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (showStreamingPreview) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  state.streamingReply,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
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
                  onPressed: state.status == VoiceAssistantStatus.processing ||
                          state.status == VoiceAssistantStatus.listening
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
        return 'Streaming microphone audio';
      case VoiceAssistantStatus.processing:
        return 'Waiting for model response';
      case VoiceAssistantStatus.speaking:
        return 'Playing model audio (tap mic to interrupt)';
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
        return Icons.hearing;
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
        return 'Interrupt and listen';
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
