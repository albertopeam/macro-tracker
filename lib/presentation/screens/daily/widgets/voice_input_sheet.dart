import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/meal_entry.dart';
import '../../../../domain/services/speech_error.dart';
import '../../../../domain/services/voice_service.dart';
import '../../../../presentation/providers/providers.dart';
import 'confirm_entry_sheet.dart';
import 'waveform_widget.dart';

class VoiceInputSheet extends ConsumerStatefulWidget {
  final MealType mealType;
  final String date;

  const VoiceInputSheet({
    super.key,
    required this.mealType,
    required this.date,
  });

  @override
  ConsumerState<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<VoiceInputSheet> {
  bool _unavailable = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  @override
  void dispose() {
    VoiceService.instance.cancel();
    super.dispose();
  }

  Future<void> _startListening() async {
    ref.read(voiceProvider.notifier).reset();
    final ok = await VoiceService.instance.initialize();
    if (!ok || !mounted) {
      if (mounted) setState(() => _unavailable = true);
      return;
    }

    ref.read(voiceProvider.notifier).setListening(true);

    await VoiceService.instance.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        ref.read(voiceProvider.notifier).updateTranscript(text, isFinal);
        if (isFinal) _onFinalResult();
      },
      onSoundLevel: (level) {
        if (!mounted) return;
        ref.read(voiceProvider.notifier).updateSoundLevel(level);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _errorMessage = error);
        ref.read(voiceProvider.notifier).setListening(false);
      },
    );
  }

  void _onFinalResult() {
    final candidates = ref.read(voiceProvider).candidates;
    if (candidates.isEmpty) return;
    _openConfirm();
  }

  void _stopAndConfirm() {
    VoiceService.instance.stopListening();
    ref.read(voiceProvider.notifier).finalize();
    _openConfirm();
  }

  void _openConfirm() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConfirmEntrySheet(
          mealType: widget.mealType,
          date: widget.date,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text('Add to ${widget.mealType.displayName}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (voice.transcript.isNotEmpty)
            TextButton(
              onPressed: _stopAndConfirm,
              child: const Text('Next'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_unavailable)
              const Text(
                'Speech recognition unavailable.\nPlease check microphone permissions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              )
            else if (_errorMessage != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.mic_off,
                      size: 48,
                      color: scheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!.friendlyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                    onPressed: () {
                      setState(() => _errorMessage = null);
                      _startListening();
                    },
                  ),
                ],
              )
            else ...[
              WaveformWidget(
                soundLevel: voice.soundLevel,
                isListening: voice.isListening,
                color: scheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                voice.isListening ? 'Listening…' : 'Processing…',
                style: TextStyle(
                    color: scheme.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: voice.transcript.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    voice.transcript.isEmpty
                        ? 'Try: "40g oats, 1kg milk" or "40 gramos de avena"'
                        : voice.transcript,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (voice.transcript.isEmpty)
                Text(
                  'Try: "40g oats, 1kg milk" or "40 gramos de avena"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 14),
                ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('Stop & Review'),
                onPressed:
                    voice.transcript.isNotEmpty ? _stopAndConfirm : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
