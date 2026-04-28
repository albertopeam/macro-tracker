import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../../../data/models/food.dart';
import '../../../../data/models/meal_entry.dart';
import '../../../../domain/parsing/fuzzy_matcher.dart';
import '../../../../domain/services/macro_calculator.dart';
import '../../../../domain/services/speech_error.dart';
import '../../../../domain/services/voice_service.dart';
import '../../../../presentation/providers/providers.dart';
import '../../food_search/food_search_screen.dart';
import 'waveform_widget.dart';

// ---------------------------------------------------------------------------
// Session item — canonical state for one food entry across rebuilds
// ---------------------------------------------------------------------------

class _SessionItem {
  Food? selectedFood;
  double grams;
  final List<FuzzyResult> alternatives;
  final TextEditingController gramsCtrl;

  _SessionItem({
    required this.selectedFood,
    required this.alternatives,
    required this.grams,
  }) : gramsCtrl = TextEditingController(text: _fmt(grams));

  void dispose() => gramsCtrl.dispose();

  static String _fmt(double g) =>
      g == g.roundToDouble() ? g.round().toString() : g.toStringAsFixed(1);
}

// ---------------------------------------------------------------------------
// Voice session sheet
// ---------------------------------------------------------------------------

class VoiceSessionSheet extends ConsumerStatefulWidget {
  final MealType mealType;
  final String date;

  const VoiceSessionSheet({
    super.key,
    required this.mealType,
    required this.date,
  });

  @override
  ConsumerState<VoiceSessionSheet> createState() => _VoiceSessionSheetState();
}

class _VoiceSessionSheetState extends ConsumerState<VoiceSessionSheet> {
  final List<_SessionItem> _items = [];
  bool _isRecording = false;
  bool _didFinalize = false;
  bool _saving = false;
  String? _error;
  bool _unavailable = false;

  @override
  void dispose() {
    VoiceService.instance.cancel();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    _didFinalize = false;
    setState(() {
      _isRecording = true;
      _error = null;
    });
    ref.read(voiceProvider.notifier).reset();

    final ok = await VoiceService.instance.initialize();
    if (!ok || !mounted) {
      setState(() {
        _isRecording = false;
        _unavailable = !ok;
      });
      return;
    }

    ref.read(voiceProvider.notifier).setListening(true);

    await VoiceService.instance.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        ref.read(voiceProvider.notifier).updateTranscript(text, isFinal);
        if (isFinal) _onRecordingComplete();
      },
      onSoundLevel: (level) {
        if (mounted) ref.read(voiceProvider.notifier).updateSoundLevel(level);
      },
      onError: (error) {
        if (!mounted) return;
        ref.read(voiceProvider.notifier).setListening(false);
        setState(() {
          _isRecording = false;
          _error = error;
        });
      },
    );
  }

  Future<void> _stopRecording() async {
    VoiceService.instance.stopListening();
    ref.read(voiceProvider.notifier).finalize();
    _onRecordingComplete();
  }

  void _onRecordingComplete() {
    if (_didFinalize) return;
    _didFinalize = true;
    final candidates = ref.read(voiceProvider).candidates;
    final matcher = ref.read(fuzzyMatcherProvider);
    setState(() {
      _isRecording = false;
      for (final c in candidates) {
        _items.add(_SessionItem(
          selectedFood: matcher.findBest(c.rawName)?.food,
          alternatives: matcher.search(c.rawName, limit: 4),
          grams: c.grams,
        ));
      }
    });
  }

  Future<void> _saveAll() async {
    final entries = _items
        .where((i) => i.selectedFood != null)
        .map((i) => MacroCalculator.calculate(
              food: i.selectedFood!,
              grams: i.grams,
              mealType: widget.mealType,
              date: widget.date,
            ))
        .toList();
    if (entries.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(logProvider(widget.date).notifier).addEntries(entries);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    final scheme = Theme.of(context).colorScheme;
    final validCount = _items.where((i) => i.selectedFood != null).length;

    final micLabel = _isRecording
        ? 'Stop & add'
        : (_items.isEmpty ? 'Tap to speak' : 'Speak again');
    final micIcon = _isRecording ? Icons.stop : Icons.mic;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add to ${widget.mealType.displayName}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Items list
          Expanded(
            child: _items.isEmpty
                ? _EmptyHint(unavailable: _unavailable, scheme: scheme)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _ItemCard(
                      key: ObjectKey(_items[i]),
                      initialFood: _items[i].selectedFood,
                      alternatives: _items[i].alternatives,
                      gramsCtrl: _items[i].gramsCtrl,
                      initialGrams: _items[i].grams,
                      mealType: widget.mealType,
                      date: widget.date,
                      onDelete: () => setState(() {
                        _items[i].dispose();
                        _items.removeAt(i);
                      }),
                      onFoodChanged: (f) =>
                          setState(() => _items[i].selectedFood = f),
                      onGramsChanged: (g) =>
                          setState(() => _items[i].grams = g),
                    ),
                  ),
          ),

          // Recording feedback
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  WaveformWidget(
                    soundLevel: voice.soundLevel,
                    isListening: voice.isListening,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    voice.isListening ? 'Listening…' : 'Processing…',
                    style: TextStyle(
                        color: scheme.primary, fontWeight: FontWeight.w600),
                  ),
                  if (voice.transcript.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      voice.transcript,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.65)),
                    ),
                  ],
                ],
              ),
            ),

          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _error!.friendlyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Bottom bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: Icon(micIcon),
                      label: Text(micLabel),
                      onPressed: _saving
                          ? null
                          : (_isRecording ? _stopRecording : _startRecording),
                    ),
                  ),
                  if (_items.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: (_saving || validCount == 0) ? null : _saveAll,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Save ($validCount)'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state hint
// ---------------------------------------------------------------------------

class _EmptyHint extends StatelessWidget {
  final bool unavailable;
  final ColorScheme scheme;

  const _EmptyHint({required this.unavailable, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (unavailable) {
      return const Center(
        child: Text(
          'Speech recognition unavailable.\nPlease check microphone permissions.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none,
              size: 64, color: scheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Tap "Speak" and name foods with quantities.\nE.g. "40g oats, 100g chicken"',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item card — one food entry (no confirm button, only delete)
// ---------------------------------------------------------------------------

class _ItemCard extends StatefulWidget {
  final Food? initialFood;
  final List<FuzzyResult> alternatives;
  final TextEditingController gramsCtrl;
  final double initialGrams;
  final MealType mealType;
  final String date;
  final VoidCallback onDelete;
  final void Function(Food?) onFoodChanged;
  final void Function(double) onGramsChanged;

  const _ItemCard({
    super.key,
    required this.initialFood,
    required this.alternatives,
    required this.gramsCtrl,
    required this.initialGrams,
    required this.mealType,
    required this.date,
    required this.onDelete,
    required this.onFoodChanged,
    required this.onGramsChanged,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late Food? _food;
  late double _grams;

  @override
  void initState() {
    super.initState();
    _food = widget.initialFood;
    _grams = widget.initialGrams;
  }

  MealEntry? get _entry {
    if (_food == null) return null;
    return MacroCalculator.calculate(
      food: _food!,
      grams: _grams,
      mealType: widget.mealType,
      date: widget.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _FoodDropdown(
                    selected: _food,
                    alternatives: widget.alternatives,
                    onChanged: (f) {
                      setState(() => _food = f);
                      widget.onFoodChanged(f);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: widget.gramsCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                      labelText: 'Grams',
                    ),
                    onChanged: (v) {
                      final g = double.tryParse(v);
                      if (g != null && g > 0) {
                        setState(() => _grams = g);
                        widget.onGramsChanged(g);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (_food != null && entry != null) ...[
                  _MacroMini('P', entry.protein, AppColors.protein),
                  const SizedBox(width: 8),
                  _MacroMini('C', entry.carbs, AppColors.carbs),
                  const SizedBox(width: 8),
                  _MacroMini('F', entry.fat, AppColors.fat),
                  const SizedBox(width: 8),
                  _MacroMini('kcal', entry.calories, AppColors.calories,
                      isCalories: true),
                ] else
                  Text(
                    'Select a food to see macros',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Food dropdown (identical logic to ParsedResultCard._FoodDropdown)
// ---------------------------------------------------------------------------

class _FoodDropdown extends StatelessWidget {
  final Food? selected;
  final List<FuzzyResult> alternatives;
  final void Function(Food?) onChanged;

  const _FoodDropdown({
    required this.selected,
    required this.alternatives,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<Food?>>[
      if (selected != null &&
          !alternatives.any((a) => a.food.id == selected!.id))
        DropdownMenuItem(
            value: selected,
            child:
                Text(selected!.name, overflow: TextOverflow.ellipsis)),
      ...alternatives.map((r) => DropdownMenuItem(
          value: r.food,
          child: Text(r.food.name, overflow: TextOverflow.ellipsis))),
      const DropdownMenuItem(
          value: null,
          child: Text('Search…',
              style: TextStyle(fontStyle: FontStyle.italic))),
    ];

    return DropdownButtonFormField<Food?>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(),
        labelText: 'Food',
      ),
      items: items,
      onChanged: (food) async {
        if (food == null) {
          // ignore: use_build_context_synchronously
          final picked = await FoodSearchScreen.push(context);
          if (picked != null) onChanged(picked);
          return;
        }
        onChanged(food);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Macro mini display
// ---------------------------------------------------------------------------

class _MacroMini extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isCalories;

  const _MacroMini(this.label, this.value, this.color,
      {this.isCalories = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.bold)),
        Text(
            isCalories
                ? value.round().toString()
                : '${value.toStringAsFixed(1)}g',
            style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
