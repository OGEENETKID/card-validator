import 'package:card_validator/data/banned_country_store.dart';
import 'package:card_validator/data/card_store.dart';
import 'package:card_validator/models/card_brand.dart';
import 'package:card_validator/models/credit_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CreditCard card(String number, {String id = '1', String country = 'ZA'}) => CreditCard(
      id: id,
      number: number,
      brand: CardBrand.visa,
      countryCode: country,
      capturedAt: DateTime(2026, 1, 1, 9, 30),
      expiry: '08/29',
      cvv: '123',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CardStore', () {
    test('stores a card and reads it back after a restart', () async {
      final store = CardStore();
      await store.load();
      expect(await store.add(card('4574487405351567')), isTrue);

      final reopened = CardStore();
      await reopened.load();

      expect(reopened.cards, hasLength(1));
      expect(reopened.cards.single.number, '4574487405351567');
      expect(reopened.cards.single.brand, CardBrand.visa);
      expect(reopened.cards.single.countryCode, 'ZA');
    });

    test('refuses to capture the same card twice', () async {
      final store = CardStore();
      await store.load();

      expect(await store.add(card('4574487405351567', id: 'a')), isTrue);
      expect(await store.add(card('4574487405351567', id: 'b')), isFalse);
      expect(store.cards, hasLength(1));
    });

    test('keeps the expiry date and security code', () async {
      final store = CardStore();
      await store.load();
      await store.add(card('4574487405351567'));

      final reopened = CardStore();
      await reopened.load();

      expect(reopened.cards.single.expiry, '08/29');
      expect(reopened.cards.single.cvv, '123');
    });

    test('keeps the newest card at the top', () async {
      final store = CardStore();
      await store.load();
      await store.add(card('4574487405351567', id: 'a'));
      await store.add(card('4242424242424242', id: 'b'));

      expect(store.cards.first.number, '4242424242424242');
    });

    test('survives corrupt storage', () async {
      SharedPreferences.setMockInitialValues({'captured_cards': 'not json at all'});
      final store = CardStore();
      await store.load();
      expect(store.cards, isEmpty);
    });
  });

  group('BannedCountryStore', () {
    test('starts from the shipped defaults', () async {
      final store = BannedCountryStore();
      await store.load();

      expect(store.codes, contains('IR'));
      expect(store.isCustomised, isFalse);
      expect(store.isBanned('ir'), isTrue);
      expect(store.isBanned('ZA'), isFalse);
    });

    test('remembers changes across a restart', () async {
      final store = BannedCountryStore();
      await store.load();
      await store.add('ZA');
      await store.remove('IR');

      final reopened = BannedCountryStore();
      await reopened.load();

      expect(reopened.isBanned('ZA'), isTrue);
      expect(reopened.isBanned('IR'), isFalse);
      expect(reopened.isCustomised, isTrue);
    });

    test('records why each country on the shipped list is refused', () async {
      final store = BannedCountryStore();
      await store.load();

      expect(store.reasonFor('IR'), isNotNull);
      expect(store.source, isNotNull);

      // No reason given on add.
      await store.add('ZA');
      expect(store.reasonFor('ZA'), isNull);
    });

    test('keeps a reason given when a country is banned', () async {
      final store = BannedCountryStore();
      await store.load();
      await store.add('ZA', reason: 'Elevated chargeback rate');

      final reopened = BannedCountryStore();
      await reopened.load();

      expect(reopened.reasonFor('ZA'), 'Elevated chargeback rate');
    });

    test('edits the reason on a country already listed', () async {
      final store = BannedCountryStore();
      await store.load();
      await store.setReason('IR', 'Sanctions review 2026');

      expect(store.reasonFor('IR'), 'Sanctions review 2026');
      expect(store.isBanned('IR'), isTrue);
      expect(store.isCustomised, isTrue);

      final reopened = BannedCountryStore();
      await reopened.load();
      expect(reopened.reasonFor('IR'), 'Sanctions review 2026');
    });

    test('ignores a reason set on a country that is not listed', () async {
      final store = BannedCountryStore();
      await store.load();
      await store.setReason('ZA', 'Not on the list');

      expect(store.isBanned('ZA'), isFalse);
      expect(store.reasonFor('ZA'), isNull);
    });

    test('offers the shipped reason when re-banning a default country', () async {
      final store = BannedCountryStore();
      await store.load();

      expect(store.defaultReasonFor('IR'), isNotNull);
      expect(store.defaultReasonFor('ZA'), isNull);
    });

    test('restores the defaults on reset', () async {
      final store = BannedCountryStore();
      await store.load();
      await store.add('ZA');
      await store.resetToDefaults();

      expect(store.isBanned('ZA'), isFalse);
      expect(store.codes, store.defaults);
      expect(store.isCustomised, isFalse);
    });
  });
}
