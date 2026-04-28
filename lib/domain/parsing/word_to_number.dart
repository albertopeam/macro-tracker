/// Converts written-out number words to digits in a string.
///
/// Supports English and Spanish, including compound forms:
///   "cuarenta y cinco gramos de avena" → "45 gramos de avena"
///   "forty grams of oats"             → "40 grams of oats"
///   "ciento cincuenta gramos de arroz"→ "150 gramos de arroz"
class WordToNumber {
  static const Map<String, int> _words = {
    // Spanish ones & teens
    'cero': 0,
    'un': 1, 'uno': 1, 'una': 1,
    'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5,
    'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9,
    'diez': 10, 'once': 11, 'doce': 12, 'trece': 13,
    'catorce': 14, 'quince': 15,
    'dieciseis': 16, 'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19,
    // Spanish 20-29 (single compound words)
    'veinte': 20, 'veintiun': 21, 'veintiuno': 21, 'veintiuna': 21,
    'veintidos': 22, 'veintitres': 23, 'veinticuatro': 24, 'veinticinco': 25,
    'veintiseis': 26, 'veintisiete': 27, 'veintiocho': 28, 'veintinueve': 29,
    // Spanish tens
    'treinta': 30, 'cuarenta': 40, 'cincuenta': 50,
    'sesenta': 60, 'setenta': 70, 'ochenta': 80, 'noventa': 90,
    // Spanish hundreds (value already includes the multiplier)
    'cien': 100, 'ciento': 100,
    'doscientos': 200, 'doscientas': 200,
    'trescientos': 300, 'trescientas': 300,
    'cuatrocientos': 400, 'cuatrocientas': 400,
    'quinientos': 500, 'quinientas': 500,
    'seiscientos': 600, 'seiscientas': 600,
    'setecientos': 700, 'setecientas': 700,
    'ochocientos': 800, 'ochocientas': 800,
    'novecientos': 900, 'novecientas': 900,
    // Spanish thousands
    'mil': 1000,
    // English ones & teens
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
    'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
    // English tens & multipliers
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
    'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
    'hundred': 100, 'thousand': 1000,
  };

  static const Set<String> _connectors = {'y', 'and'};

  static String normalize(String text) {
    final tokens = text.split(RegExp(r'\s+'));
    final result = <String>[];
    int i = 0;

    while (i < tokens.length) {
      if (_words.containsKey(_key(tokens[i]))) {
        final (value, end) = _parseRun(tokens, i);
        result.add(value.toString());
        i = end;
      } else {
        result.add(tokens[i]);
        i++;
      }
    }

    return result.join(' ');
  }

  static (int, int) _parseRun(List<String> tokens, int start) {
    final parts = <(String, int)>[];
    int i = start;

    while (i < tokens.length) {
      final k = _key(tokens[i]);
      if (_words.containsKey(k)) {
        parts.add((k, _words[k]!));
        i++;
      } else if (_connectors.contains(k) &&
          i + 1 < tokens.length &&
          _words.containsKey(_key(tokens[i + 1]))) {
        i++; // skip connector only when the next token is also a number word
      } else {
        break;
      }
    }

    return (_compute(parts), i);
  }

  // Handles English multipliers (hundred, thousand) and Spanish pre-multiplied hundreds.
  static int _compute(List<(String, int)> parts) {
    int result = 0;
    int pending = 0;

    for (final (word, val) in parts) {
      if (word == 'hundred') {
        // English: "two hundred" → pending(2) × 100 = 200
        pending = (pending == 0 ? 1 : pending) * 100;
      } else if (word == 'thousand' || word == 'mil') {
        result += (pending == 0 ? 1 : pending) * 1000;
        pending = 0;
      } else {
        pending += val;
      }
    }

    return result + pending;
  }

  // Lowercase + strip accents + strip non-letter chars for map lookup.
  static String _key(String token) => token
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'[^a-z]'), '');
}
