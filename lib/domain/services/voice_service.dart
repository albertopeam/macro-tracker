import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum ListeningState { idle, initializing, listening, processing, error, unavailable }

class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final _speech = SpeechToText();
  bool _initialized = false;
  void Function(String error)? _onError;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (error) {
        debugPrint('VoiceService error: ${error.errorMsg}');
        _onError?.call(error.errorMsg);
      },
      onStatus: (status) => debugPrint('VoiceService status: $status'),
    );
    return _initialized;
  }

  bool get isAvailable => _initialized && _speech.isAvailable;
  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(double level) onSoundLevel,
    void Function(String error)? onError,
    Duration listenFor = const Duration(seconds: 15),
    String localeId = '',
  }) async {
    _onError = onError;
    if (!_initialized) await initialize();
    if (!isAvailable) return;

    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      onSoundLevelChange: onSoundLevel,
      listenFor: listenFor,
      pauseFor: const Duration(seconds: 3),
      localeId: localeId.isNotEmpty ? localeId : null,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    _onError = null;
    await _speech.cancel();
  }

  Future<List<LocaleName>> getLocales() async {
    if (!_initialized) await initialize();
    return _speech.locales();
  }
}
