import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/credit_card.dart';

/// Local persistence for captured cards, as one JSON array in
/// SharedPreferences.
class CardStore {
  CardStore({SharedPreferences? preferences}) : _preferences = preferences;

  static const String _key = 'captured_cards';

  SharedPreferences? _preferences;
  final List<CreditCard> _cards = [];

  /// Newest first.
  List<CreditCard> get cards => List.unmodifiable(_cards);

  Set<String> get numbers => _cards.map((c) => c.number).toSet();

  bool contains(String number) => numbers.contains(number);

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _cards.clear();

    final raw = _preferences!.getString(_key);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cards.addAll(decoded.map((e) => CreditCard.fromJson(e as Map<String, dynamic>)));
      _cards.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    } catch (_) {
      // Treat unreadable storage as empty rather than crash on launch.
      await _preferences!.remove(_key);
    }
  }

  /// Returns false when the card is already stored.
  Future<bool> add(CreditCard card) async {
    if (contains(card.number)) return false;
    _cards.insert(0, card);
    await _persist();
    return true;
  }

  Future<void> remove(String id) async {
    _cards.removeWhere((c) => c.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_cards.map((c) => c.toJson()).toList());
    await _preferences?.setString(_key, encoded);
  }
}
