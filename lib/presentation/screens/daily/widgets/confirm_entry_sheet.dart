import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/meal_entry.dart';
import '../../../../presentation/providers/providers.dart';
import 'parsed_result_card.dart';

class ConfirmEntrySheet extends ConsumerStatefulWidget {
  final MealType mealType;
  final String date;

  const ConfirmEntrySheet({
    super.key,
    required this.mealType,
    required this.date,
  });

  @override
  ConsumerState<ConfirmEntrySheet> createState() =>
      _ConfirmEntrySheetState();
}

class _ConfirmEntrySheetState extends ConsumerState<ConfirmEntrySheet> {
  // Indices of candidates already saved to the database.
  final Set<int> _savedIndices = {};

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);
    final matcher = ref.watch(fuzzyMatcherProvider);
    final candidates = voiceState.candidates;

    final pendingCards = candidates.asMap().entries
        .where((e) => !_savedIndices.contains(e.key))
        .map((e) {
          final idx = e.key;
          final c = e.value;
          final results = matcher.search(c.rawName, limit: 4);
          final top = matcher.findBest(c.rawName)?.food;

          return ParsedResultCard(
            key: ValueKey(idx),
            matchedFood: top,
            alternatives: results,
            initialGrams: c.grams,
            mealType: widget.mealType,
            date: widget.date,
            onConfirmed: (entry) => _saveEntry(idx, entry, candidates.length),
            onRemove: () {
              ref.read(voiceProvider.notifier).updateTranscript(
                  voiceState.transcript.replaceFirst(c.rawName, ''), true);
            },
          );
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm entries'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: candidates.isEmpty
          ? _emptyState(context)
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Adjust grams if needed, then tap "Add".',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontSize: 13),
                  ),
                ),
                ...pendingCards,
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Future<void> _saveEntry(int idx, MealEntry entry, int total) async {
    await ref
        .read(logProvider(widget.date).notifier)
        .addEntries([entry]);
    if (!mounted) return;
    setState(() => _savedIndices.add(idx));
    if (_savedIndices.length >= total) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Widget _emptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
                'Could not identify any food with quantities.\nTry speaking again.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
}
