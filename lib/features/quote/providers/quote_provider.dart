import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quotes_data.dart';

// ── Shared Preferences Provider ───────────────────────────────

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

// ── Quote for Today ───────────────────────────────────────────

/// Returns the [QuoteData] for today.
/// The same quote is shown all day (seeded by day-of-year index).
/// FR-QUOTE-01: One unique quote per day.
final todayQuoteProvider = Provider<QuoteData>((ref) {
  final dayOfYear = _dayOfYear(DateTime.now());
  final index     = dayOfYear % AppQuotes.quotes.length;
  return AppQuotes.quotes[index];
});

// ── Should Show Quote Today ───────────────────────────────────

/// Returns true if the quote splash has NOT been shown today yet.
/// FR-QUOTE-01: Show only on first launch of each calendar day.
final shouldShowQuoteProvider = FutureProvider<bool>((ref) async {
  final prefs    = await ref.watch(sharedPreferencesProvider.future);
  final lastDate = prefs.getString(_kLastQuoteDate);
  return lastDate != _todayKey();
});

// ── Mark Quote As Shown ───────────────────────────────────────

Future<void> markQuoteShownToday() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLastQuoteDate, _todayKey());
}

// ── Helpers ───────────────────────────────────────────────────

const _kLastQuoteDate = 'lastQuoteDate';

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

int _dayOfYear(DateTime date) {
  return date.difference(DateTime(date.year, 1, 1)).inDays;
}
