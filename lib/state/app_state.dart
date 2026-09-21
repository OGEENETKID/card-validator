import 'package:flutter/widgets.dart';

import '../core/card_validator.dart';
import '../data/banned_country_store.dart';
import '../data/card_store.dart';
import '../models/card_brand.dart';
import '../models/credit_card.dart';

/// Shared state for the screens.
class AppState extends ChangeNotifier {
  AppState({CardStore? cardStore, BannedCountryStore? bannedCountryStore})
      : _cards = cardStore ?? CardStore(),
        _banned = bannedCountryStore ?? BannedCountryStore();

  final CardStore _cards;
  final BannedCountryStore _banned;

  bool _ready = false;

  bool get isReady => _ready;

  List<CreditCard> get cards => _cards.cards;

  Set<String> get bannedCountryCodes => _banned.codes;

  bool get bannedListIsCustomised => _banned.isCustomised;

  /// Why a country is refused, or null if no reason was recorded.
  String? bannedCountryReason(String code) => _banned.reasonFor(code);

  String? get bannedListSource => _banned.source;

  String? get bannedListReviewed => _banned.reviewed;

  /// Rebuilt from current state so it sees the latest list and numbers.
  CardValidator get validator => CardValidator(
        bannedCountryCodes: _banned.codes,
        existingNumbers: _cards.numbers,
      );

  Future<void> load() async {
    await Future.wait([_cards.load(), _banned.load()]);
    _ready = true;
    notifyListeners();
  }

  /// Validates and stores a card. Returns the failures; empty means stored.
  Future<ValidationResult> submit({
    required String number,
    required CardBrand brand,
    required String expiry,
    required String cvv,
    required String countryCode,
  }) async {
    final result = validator.validate(
      number: number,
      brand: brand,
      expiry: expiry,
      cvv: cvv,
      countryCode: countryCode,
    );
    if (!result.isValid) return result;

    final card = CreditCard(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      number: number.replaceAll(RegExp(r'\D'), ''),
      brand: brand,
      countryCode: countryCode,
      capturedAt: DateTime.now(),
      expiry: expiry,
      cvv: cvv,
    );

    await _cards.add(card);
    notifyListeners();
    return const ValidationResult.valid();
  }

  Future<void> removeCard(String id) async {
    await _cards.remove(id);
    notifyListeners();
  }

  /// The reason the shipped list gives for a country, to pre-fill the field.
  String? defaultBannedReason(String code) => _banned.defaultReasonFor(code);

  Future<void> banCountry(String code, {String? reason}) async {
    await _banned.add(code, reason: reason);
    notifyListeners();
  }

  Future<void> setBannedCountryReason(String code, String reason) async {
    await _banned.setReason(code, reason);
    notifyListeners();
  }

  Future<void> unbanCountry(String code) async {
    await _banned.remove(code);
    notifyListeners();
  }

  Future<void> resetBannedCountries() async {
    await _banned.resetToDefaults();
    notifyListeners();
  }
}

/// Puts [AppState] in the tree. `of` rebuilds on change, `read` does not.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in the widget tree.');
    return scope!.notifier!;
  }

  /// For callbacks and event handlers.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in the widget tree.');
    return scope!.notifier!;
  }
}
