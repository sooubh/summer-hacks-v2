import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart' show Level;
import 'package:permission_handler/permission_handler.dart';
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
  bool _resumeMicAfterReconnect = false;
  bool _shouldMaintainLiveConnection = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  final DateTime _sessionStartedAt = DateTime.now();
  final List<String> _debugEvents = <String>[];
  String? _lastLiveEventType;
  DateTime? _lastLiveEventAt;
  String? _lastReconnectReason;
  DateTime? _lastReconnectAt;
  bool _showDebugPanel = false;
  bool _microphonePermissionGranted = false;
  String _microphonePermissionState = 'unknown';
  final int _liveInputSampleRate = AiRuntimeConfig.liveInputSampleRate;
  int _liveOutputSampleRate = AiRuntimeConfig.liveOutputSampleRate;

  @override
  void initState() {
    super.initState();
    _appendDebugEvent('Voice assistant sheet initialized.');
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
    _cancelReconnectTimer();
    _shouldMaintainLiveConnection = false;
    await _stopMicStream(markProcessing: false, suppressUi: true);
    await _clearPlayback(immediate: true);
    await _disconnectLiveSession(updateState: false);
    await _closeAudioRuntime();
  }

  Future<void> _initializeVoiceRuntime() async {
    try {
      if (AiRuntimeConfig.apiKey.trim().isEmpty) {
        _appendDebugEvent(
          'AI_API_KEY is missing from .env and dart-define.',
          code: 'missing_api_key',
        );
      }

      final bool hasMicrophonePermission = await _ensureMicrophonePermission();
      if (!hasMicrophonePermission) {
        if (mounted) {
          setState(() {
            _voiceReady = false;
            _initializing = false;
          });
        }
        return;
      }

      await _pcmRecorder.openRecorder();
      _pcmRecorderReady = true;

      await _pcmPlayer.openPlayer();
      _pcmPlayerReady = true;
      await _restartPcmPlayer(sampleRate: _liveOutputSampleRate);
      _appendDebugEvent('Audio runtime initialized successfully.');

      if (mounted) {
        setState(() {
          _voiceReady = true;
          _initializing = false;
        });
      }
    } catch (error) {
      _appendDebugEvent(
        'Audio runtime initialization failed: $error',
        code: 'runtime_init',
      );
      if (mounted) {
        ref
            .read(voiceAssistantControllerProvider.notifier)
            .setError(
              'Voice runtime initialization failed. You can still use text input.',
              code: 'runtime_init',
            );
        setState(() {
          _voiceReady = false;
          _initializing = false;
        });
      }
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    final PermissionStatus currentStatus = await Permission.microphone.status;
    _microphonePermissionState = currentStatus.name;

    if (currentStatus.isGranted) {
      _microphonePermissionGranted = true;
      _appendDebugEvent('Microphone permission granted.');
      return true;
    }

    _appendDebugEvent('Requesting microphone permission.');
    final PermissionStatus requestedStatus = await Permission.microphone.request();
    _microphonePermissionState = requestedStatus.name;
    _microphonePermissionGranted = requestedStatus.isGranted;

    if (requestedStatus.isGranted) {
      _appendDebugEvent('Microphone permission granted after request.');
      return true;
    }

    final String message = requestedStatus.isPermanentlyDenied
        ? 'Microphone permission is permanently denied. Enable it in Android app settings.'
        : 'Microphone permission denied. Please allow microphone access and try again.';
    _appendDebugEvent(message, code: 'mic_permission_denied');
    if (mounted) {
      ref
          .read(voiceAssistantControllerProvider.notifier)
          .setError(message, code: 'mic_permission_denied');
    }
    return false;
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

    _appendDebugEvent(
      'Connecting live session (attempt ${_reconnectAttempt + 1}).',
    );
    _liveSessionConnecting = true;
    final VoiceAssistantController controller = ref.read(
      voiceAssistantControllerProvider.notifier,
    );
    final VoiceAssistantState currentState = ref.read(
      voiceAssistantControllerProvider,
    );
    if (currentState.liveSessionReady) {
      controller.setLiveSessionReady(false);
    }

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
          _appendDebugEvent(
            'Live event stream error: $error',
            code: 'connection_error',
          );
          if (!mounted) {
            return;
          }
          ref
              .read(voiceAssistantControllerProvider.notifier)
              .setError(
                'Live voice connection failed. Falling back to turn mode.',
                code: 'connection_error',
              );
          ref
              .read(voiceAssistantControllerProvider.notifier)
              .setLiveSessionReady(false);
        },
        cancelOnError: false,
      );

      controller.setLiveSessionReady(true);
      _reconnectAttempt = 0;
      _cancelReconnectTimer();
      _appendDebugEvent('Live session connected and ready.');

      if (_resumeMicAfterReconnect) {
        _resumeMicAfterReconnect = false;
        _appendDebugEvent('Resuming microphone after reconnect.');
        unawaited(_startMicStream());
      }
    } catch (error) {
      _appendDebugEvent(
        'Live session connect failed: $error',
        code: 'connect_retry',
      );
      if (!mounted || _isDisposing) {
        return;
      }
      controller.setLiveSessionReady(false);
      controller.setError(
        'Live session setup failed: $error',
        code: 'connect_retry',
      );
      _scheduleReconnect(reason: error.toString());
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
      _appendDebugEvent('Live session disconnected.');
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

    _recordLiveEvent(event);

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
        if (_micStreamActive && _playbackQueue.isEmpty) {
          controller.setStatus(VoiceAssistantStatus.listening);
          controller.updateTranscript('Continuous voice mode is active.');
        } else if (_playbackQueue.isEmpty && !_micStreamActive) {
          controller.setStatus(VoiceAssistantStatus.idle);
        }
        break;
      case VoiceLiveEventType.interrupted:
        _discardCurrentModelTurn = false;
        _liveReplyBuffer.clear();
        await _clearPlayback(immediate: true);
        controller.clearStreamingReply();
        if (_micStreamActive) {
          controller.setStatus(VoiceAssistantStatus.listening);
          controller.updateTranscript('Continuous voice mode is active.');
        } else {
          controller.setStatus(VoiceAssistantStatus.idle);
        }
        break;
      case VoiceLiveEventType.disconnected:
        _resumeMicAfterReconnect = _micStreamActive;
        if (_micStreamActive) {
          await _stopMicStream(markProcessing: false, suppressUi: true);
        }
        await _clearPlayback(immediate: true);
        controller.setLiveSessionReady(false);
        await _disconnectLiveSession(updateState: false);
        _scheduleReconnect(reason: 'Live connection disconnected.');
        break;
      case VoiceLiveEventType.error:
        _resumeMicAfterReconnect = _micStreamActive;
        if (_micStreamActive) {
          await _stopMicStream(markProcessing: false, suppressUi: true);
        }
        await _clearPlayback(immediate: true);
        controller.setLiveSessionReady(false);
        controller.setError(
          event.errorMessage ?? 'Live voice session failed. Using fallback mode.',
          code: event.errorCode ?? event.errorStatus,
        );
        await _disconnectLiveSession(updateState: false);
        _scheduleReconnect(reason: event.errorMessage);
        break;
    }
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _scheduleReconnect({String? reason}) {
    if (!mounted || _isDisposing || !_shouldMaintainLiveConnection) {
      return;
    }

    if (_liveSession != null || _liveSessionConnecting || _reconnectTimer != null) {
      return;
    }

    const int maxAttempts = 6;
    if (_reconnectAttempt >= maxAttempts) {
      _shouldMaintainLiveConnection = false;
      _resumeMicAfterReconnect = false;
      _cancelReconnectTimer();
      _appendDebugEvent(
        'Reconnect exhausted after $maxAttempts attempts.',
        code: 'reconnect_exhausted',
      );
      if (mounted) {
        ref
            .read(voiceAssistantControllerProvider.notifier)
            .setError(
              'Unable to maintain live connection. Tap Start continuous voice to retry.',
              code: 'reconnect_exhausted',
            );
      }
      return;
    }

    _reconnectAttempt += 1;
    final int delaySeconds = switch (_reconnectAttempt) {
      1 => 1,
      2 => 2,
      3 => 4,
      4 => 8,
      _ => 12,
    };

    _lastReconnectReason = (reason ?? '').trim().isEmpty
        ? 'Unspecified reconnect reason.'
        : reason!.trim();
    _lastReconnectAt = DateTime.now();
    _appendDebugEvent(
      'Scheduled reconnect attempt $_reconnectAttempt in ${delaySeconds}s. Reason: $_lastReconnectReason',
      code: 'reconnect_wait',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectTimer = null;
      if (!mounted || _isDisposing || !_shouldMaintainLiveConnection) {
        return;
      }
      unawaited(_connectLiveSession());
    });
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
      if (mounted && _playbackQueue.isEmpty) {
        final VoiceAssistantController controller = ref.read(
          voiceAssistantControllerProvider.notifier,
        );
        final VoiceAssistantStatus status = ref
            .read(voiceAssistantControllerProvider)
            .status;

        if (_micStreamActive) {
          if (status == VoiceAssistantStatus.speaking ||
              status == VoiceAssistantStatus.processing) {
            controller.setStatus(VoiceAssistantStatus.listening);
            controller.updateTranscript('Continuous voice mode is active.');
          }
        } else if (status == VoiceAssistantStatus.speaking) {
          controller.setStatus(VoiceAssistantStatus.idle);
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

    if (!_microphonePermissionGranted) {
      final bool hasMicrophonePermission = await _ensureMicrophonePermission();
      if (!hasMicrophonePermission) {
        return;
      }
    }

    _shouldMaintainLiveConnection = true;
    _cancelReconnectTimer();

    if (!_voiceReady || !_pcmRecorderReady) {
      _appendDebugEvent(
        'Cannot start microphone. Recorder is not ready on this device/session.',
        code: 'runtime_unavailable',
      );
      ref
          .read(voiceAssistantControllerProvider.notifier)
          .setError(
            'Microphone stream is unavailable on this device/session.',
            code: 'runtime_unavailable',
          );
      return;
    }

    if (_liveSession == null) {
      if (!_liveSessionConnecting && _reconnectTimer == null) {
        await _connectLiveSession();
      }
    }

    final VoiceLiveSession? session = _liveSession;
    if (session == null) {
      _scheduleReconnect(reason: 'Live session not available for microphone start.');
      _appendDebugEvent(
        'Live session not ready during microphone start.',
        code: 'not_ready',
      );
      if (_reconnectAttempt == 0) {
        ref
            .read(voiceAssistantControllerProvider.notifier)
            .setError('Live session is not ready yet. Reconnecting...', code: 'not_ready');
      }
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
            .setError('Microphone stream failed: $error', code: 'mic_stream');
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
        enableNoiseSuppression: true,
        enableEchoCancellation: true,
        audioSource: AudioSource.defaultSource,
      );

      _micStreamActive = true;
      _appendDebugEvent('Microphone stream started.');

      final VoiceAssistantController controller = ref.read(
        voiceAssistantControllerProvider.notifier,
      );
      controller.startLiveAudioTurn();
      controller.updateTranscript('Continuous voice mode is active.');
      controller.setStatus(VoiceAssistantStatus.listening);
    } catch (error) {
      _appendDebugEvent(
        'Unable to start microphone stream: $error',
        code: 'mic_start',
      );
      await _stopMicStream(markProcessing: false);
      if (mounted) {
        ref
            .read(voiceAssistantControllerProvider.notifier)
            .setError('Unable to start microphone stream: $error', code: 'mic_start');
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
    _appendDebugEvent('Microphone stream stopped.');

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

    if (_micStreamActive) {
      _appendDebugEvent('User stopped continuous voice mode.');
      _shouldMaintainLiveConnection = false;
      _resumeMicAfterReconnect = false;
      _reconnectAttempt = 0;
      _cancelReconnectTimer();
      await _stopMicStream(markProcessing: false);
      return;
    }

    _appendDebugEvent('User started continuous voice mode.');

    if (state.status == VoiceAssistantStatus.speaking ||
        state.status == VoiceAssistantStatus.processing) {
      _discardCurrentModelTurn = true;
      _liveReplyBuffer.clear();
      await _clearPlayback(immediate: true);
      ref
          .read(voiceAssistantControllerProvider.notifier)
          .clearStreamingReply();
    }

    await _startMicStream();
  }

  Future<void> _submitManualPrompt() async {
    final String prompt = _manualController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    _appendDebugEvent('Submitting manual fallback prompt.');

    _manualController.clear();

    _shouldMaintainLiveConnection = true;
    _cancelReconnectTimer();

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
        _appendDebugEvent(
          'Unable to send live text prompt: $error',
          code: 'send_prompt',
        );
        controller.setError(
          'Unable to send prompt to live session: $error',
          code: 'send_prompt',
        );
        _scheduleReconnect(reason: error.toString());
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
                    ? 'Tap the mic once to start continuous live conversation. Tap again to stop.'
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
              if (state.errorCode != null && state.errorCode!.trim().isNotEmpty)
                Text(
                  'Error code: ${state.errorCode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
            const SizedBox(height: 8),
            _buildDebugPanel(context, state),
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
        return 'Continuous listening is active';
      case VoiceAssistantStatus.processing:
        return 'Listening and waiting for model response';
      case VoiceAssistantStatus.speaking:
        return 'Speaking while continuous listening stays active';
      case VoiceAssistantStatus.error:
        return 'Error';
    }
  }

  void _recordLiveEvent(VoiceLiveEvent event) {
    _lastLiveEventType = event.type.name;
    _lastLiveEventAt = DateTime.now();

    switch (event.type) {
      case VoiceLiveEventType.setupComplete:
        _appendDebugEvent('Live setup complete.');
        break;
      case VoiceLiveEventType.turnComplete:
        _appendDebugEvent('Live turn complete.');
        break;
      case VoiceLiveEventType.interrupted:
        _appendDebugEvent('Live response interrupted.');
        break;
      case VoiceLiveEventType.disconnected:
        _appendDebugEvent('Live socket disconnected.', code: 'disconnected');
        break;
      case VoiceLiveEventType.error:
        _appendDebugEvent(
          event.errorMessage ?? 'Live event error.',
          code: event.errorCode ?? event.errorStatus ?? 'live_error',
        );
        break;
      case VoiceLiveEventType.textDelta:
      case VoiceLiveEventType.audioChunk:
        break;
    }
  }

  void _appendDebugEvent(String message, {String? code}) {
    final String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    final String normalizedCode = (code ?? '').trim();
    final String line = normalizedCode.isEmpty
        ? '[$timestamp] $message'
        : '[$timestamp][$normalizedCode] $message';
    _debugEvents.insert(0, line);
    if (_debugEvents.length > 80) {
      _debugEvents.removeRange(80, _debugEvents.length);
    }

    if (mounted && !_isDisposing) {
      setState(() {});
    }
  }

  String _buildDebugSnapshot(VoiceAssistantState state) {
    final DateTime now = DateTime.now();
    final String uptime = _formatDuration(now.difference(_sessionStartedAt));
    final String lastEvent = _lastLiveEventType == null
        ? 'none'
        : '$_lastLiveEventType @ ${_formatTimestamp(_lastLiveEventAt)}';
    final String reconnectInfo = _lastReconnectAt == null
        ? 'none'
        : '${_formatTimestamp(_lastReconnectAt)} | ${_lastReconnectReason ?? 'unknown'}';

    final List<String> lines = <String>[
      'platform: ${defaultTargetPlatform.name}',
      'uptime: $uptime',
      'state.status: ${state.status.name}',
      'state.liveSessionReady: ${state.liveSessionReady}',
      'state.errorCode: ${state.errorCode ?? '-'}',
      'state.errorMessage: ${state.errorMessage ?? '-'}',
      'runtime.voiceReady: $_voiceReady',
      'runtime.recorderReady: $_pcmRecorderReady',
      'runtime.playerReady: $_pcmPlayerReady',
      'runtime.micStreamActive: $_micStreamActive',
      'runtime.liveSessionConnecting: $_liveSessionConnecting',
      'runtime.liveSessionObject: ${_liveSession != null}',
      'runtime.maintainConnection: $_shouldMaintainLiveConnection',
      'runtime.resumeMicAfterReconnect: $_resumeMicAfterReconnect',
      'runtime.reconnectAttempt: $_reconnectAttempt',
      'runtime.reconnectTimerActive: ${_reconnectTimer != null}',
      'runtime.lastReconnect: $reconnectInfo',
      'runtime.lastLiveEvent: $lastEvent',
      'runtime.micPermissionGranted: $_microphonePermissionGranted',
      'runtime.micPermissionState: $_microphonePermissionState',
      'config.apiKeyLoaded: ${AiRuntimeConfig.apiKey.trim().isNotEmpty}',
      'config.voiceModel: ${AiRuntimeConfig.voiceModel}',
      'config.voiceName: ${AiRuntimeConfig.liveVoiceName}',
      'config.inputSampleRate: $_liveInputSampleRate',
      'config.outputSampleRate: $_liveOutputSampleRate',
      'recentEvents:',
      ..._debugEvents.take(20).map((String line) => '  $line'),
    ];

    return lines.join('\n');
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return '-';
    }
    return DateFormat('HH:mm:ss').format(value);
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _copyDebugSnapshot(VoiceAssistantState state) async {
    final String snapshot = _buildDebugSnapshot(state);
    await Clipboard.setData(ClipboardData(text: snapshot));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug report copied to clipboard.')),
    );
  }

  Widget _buildDebugPanel(BuildContext context, VoiceAssistantState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.24,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        initiallyExpanded: _showDebugPanel,
        onExpansionChanged: (bool expanded) {
          setState(() {
            _showDebugPanel = expanded;
          });
        },
        title: Text(
          'Debug details (device test)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          'Live: ${state.liveSessionReady} | reconnect: $_reconnectAttempt | mic: $_micStreamActive | permission: $_microphonePermissionState',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _copyDebugSnapshot(state),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy report'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _liveSessionConnecting
                      ? null
                      : () async {
                          _appendDebugEvent('Manual reconnect requested.');
                          await _disconnectLiveSession(updateState: false);
                          if (!mounted || _isDisposing) {
                            return;
                          }
                          await _connectLiveSession();
                        },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reconnect'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            ),
            child: SelectableText(
              _buildDebugSnapshot(state),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
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
        return 'Stop continuous voice';
      case VoiceAssistantStatus.speaking:
        return 'Stop continuous voice';
      case VoiceAssistantStatus.processing:
        return 'Stop continuous voice';
      case VoiceAssistantStatus.error:
      case VoiceAssistantStatus.idle:
        return 'Start continuous voice';
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
