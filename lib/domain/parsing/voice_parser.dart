import 'word_to_number.dart';

/// A parsed candidate extracted from a speech transcription.
class ParseCandidate {
  final String rawName;
  final double grams;

  const ParseCandidate({required this.rawName, required this.grams});

  @override
  String toString() => 'ParseCandidate($rawName, ${grams}g)';
}

/// Extracts food-name / gram pairs from free-form speech.
///
/// Handles units: g, gr, grams/gramos, kg, kilograms/kilogramos, oz, lb, lbs
/// Handles decimals with period or comma: 37.5g / 37,5g
/// Handles English "of" and Spanish "de" connectors
/// Example: "40g oats, 1kg of milk and 100gr banana"
///   → [(oats, 40), (milk, 1000), (banana, 100)]
/// Example: "40 gramos de avena y 100 gramos de pollo"
///   → [(avena, 40), (pollo, 100)]
class VoiceParser {
  // Captures: (number)(unit)(optional "of"/"de")(food name)
  // Food name ends at: "and"/"y", comma, semicolon, another number, or end of string
  static final RegExp _pattern = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*'
    r'(kg|kilogramos?|kilo(?:gram)?s?|lbs?|oz|gramos?|grams?|gr?|g)\b'
    r'\s*(?:(?:of|de)\s+)?'
    r'([a-zA-ZáéíóúàèìòùäëïöüñÁÉÍÓÚÀÈÌÒÙÄËÏÖÜÑ][a-zA-ZáéíóúàèìòùäëïöüñÁÉÍÓÚÀÈÌÒÙÄËÏÖÜÑ\s\-]*?)'
    r'(?=\s*(?:and\b|y\b|[,;]|\d|$))',
    caseSensitive: false,
  );

  List<ParseCandidate> parse(String text) {
    if (text.trim().isEmpty) return [];
    final normalized = WordToNumber.normalize(text);
    final candidates = <ParseCandidate>[];

    for (final match in _pattern.allMatches(normalized)) {
      final quantityStr = match.group(1)!.replaceAll(',', '.');
      final unit = match.group(2)!.toLowerCase();
      final name = match.group(3)!.trim();

      if (name.isEmpty || name.length > 100) continue;
      // Reject bare connector/article words that leak through when the food
      // name is missing (e.g. "100gr de " → name captured as "de").
      const stopWords = {'de', 'of', 'y', 'and', 'el', 'la', 'los', 'las', 'un', 'una'};
      if (stopWords.contains(name.toLowerCase())) continue;

      double grams = double.parse(quantityStr);
      if (unit == 'kg' || unit.startsWith('kilo')) {
        grams *= 1000.0;
      } else if (unit == 'oz') {
        grams *= 28.35;
      } else if (unit == 'lb' || unit == 'lbs') {
        grams *= 453.6;
      }

      candidates.add(ParseCandidate(rawName: name, grams: grams));
    }

    return candidates;
  }
}
