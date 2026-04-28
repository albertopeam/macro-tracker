import '../../data/models/food.dart';

class FuzzyResult {
  final Food food;
  final double score; // 0.0 – 1.0
  const FuzzyResult({required this.food, required this.score});
}

/// Matches a text query against a list of [Food] objects using:
/// 1. Exact match
/// 2. Contains / starts-with
/// 3. Word-overlap scoring
/// 4. Levenshtein edit distance
class FuzzyMatcher {
  final List<Food> _foods;
  static const double _threshold = 0.30;
  static const double _autoSelectThreshold = 0.60;

  FuzzyMatcher(this._foods);

  /// Returns top [limit] matches for [query], sorted best-first.
  List<FuzzyResult> search(String query, {int limit = 5}) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final scored = <FuzzyResult>[];
    for (final food in _foods) {
      final score = _score(q, food);
      if (score >= _threshold) {
        scored.add(FuzzyResult(food: food, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).toList();
  }

  /// Returns the single best match only when the score is high enough to
  /// auto-select without user confirmation, or null otherwise.
  FuzzyResult? findBest(String query) {
    final results = search(query, limit: 1);
    if (results.isEmpty) return null;
    return results.first.score >= _autoSelectThreshold ? results.first : null;
  }

  double _score(String query, Food food) {
    final candidates = [
      food.name.toLowerCase(),
      ...food.aliases.map((a) => a.toLowerCase()),
    ];
    double best = 0.0;
    for (final c in candidates) {
      final s = _similarity(query, c);
      if (s > best) best = s;
    }
    return best;
  }

  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (b == a) return 1.0;

    // Exact containment
    if (b.contains(a)) return 0.92;
    if (a.contains(b)) return 0.88;

    // Starts-with
    if (b.startsWith(a)) return 0.85;
    if (a.startsWith(b)) return 0.82;

    // Word-level overlap
    final aWords = a.split(RegExp(r'\s+')).toSet();
    final bWords = b.split(RegExp(r'\s+')).toSet();
    final common = aWords.intersection(bWords).length;
    if (common > 0) {
      final union = aWords.union(bWords).length;
      final jaccardBoost = common / union;
      return 0.55 + jaccardBoost * 0.35;
    }

    // Any word from query contained in any candidate word (prefix match)
    for (final aw in aWords) {
      if (aw.length < 3) continue;
      for (final bw in bWords) {
        if (bw.startsWith(aw) || aw.startsWith(bw)) return 0.55;
        if (bw.contains(aw) || aw.contains(bw)) return 0.50;
      }
    }

    // Levenshtein similarity
    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    final levSim = 1.0 - dist / maxLen;
    return levSim * 0.7; // scale down so it doesn't beat word matches
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    // Limit to avoid O(n²) on long strings
    final al = a.length > 20 ? a.substring(0, 20) : a;
    final bl = b.length > 20 ? b.substring(0, 20) : b;

    final rows = al.length + 1;
    final cols = bl.length + 1;
    final d = List.generate(rows, (i) => List.filled(cols, 0));

    for (int i = 0; i < rows; i++) d[i][0] = i;
    for (int j = 0; j < cols; j++) d[0][j] = j;

    for (int i = 1; i < rows; i++) {
      for (int j = 1; j < cols; j++) {
        final cost = al[i - 1] == bl[j - 1] ? 0 : 1;
        d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
    }
    return d[rows - 1][cols - 1];
  }
}
