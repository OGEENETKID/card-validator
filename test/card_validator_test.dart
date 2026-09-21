import 'package:card_validator/core/card_validator.dart';
import 'package:card_validator/models/card_brand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CardValidator validator({
    Set<String> banned = const {'IR', 'KP'},
    Set<String> existing = const {},
  }) =>
      CardValidator(
        bannedCountryCodes: banned,
        existingNumbers: existing,
        now: DateTime(2026, 6, 15),
      );

  ValidationResult check(
    CardValidator v, {
    String number = '4574 4874 0535 1567',
    CardBrand brand = CardBrand.visa,
    String expiry = '08/29',
    String cvv = '123',
    String country = 'ZA',
  }) =>
      v.validate(
        number: number,
        brand: brand,
        expiry: expiry,
        cvv: cvv,
        countryCode: country,
      );

  group('CardValidator', () {
    test('accepts a well-formed card from an allowed country', () {
      expect(check(validator()).isValid, isTrue);
    });

    test('rejects a number that fails the checksum', () {
      final result = check(validator(), number: '4574 4874 0535 1566');
      expect(result.isValid, isFalse);
      expect(result.messageFor(CardField.number), contains('checksum'));
    });

    test('rejects a number of the wrong length for its brand', () {
      final result = check(validator(), number: '4574 4874 0535 156');
      expect(result.messageFor(CardField.number), contains('13, 16 or 19'));
    });

    test('flags a card type that contradicts the number', () {
      final result = check(validator(), brand: CardBrand.mastercard);
      expect(result.messageFor(CardField.brand), contains('Visa'));
    });

    test('accepts an expiry in the current month', () {
      expect(check(validator(), expiry: '06/26').isValid, isTrue);
    });

    test('rejects an expiry that has passed', () {
      final result = check(validator(), expiry: '05/26');
      expect(result.messageFor(CardField.expiry), 'This card has expired.');
    });

    test('rejects an expiry that is not a real month', () {
      expect(check(validator(), expiry: '13/28').messageFor(CardField.expiry), isNotNull);
      expect(check(validator(), expiry: '0828').messageFor(CardField.expiry), isNull);
      expect(check(validator(), expiry: 'soon').messageFor(CardField.expiry), isNotNull);
    });

    test('enforces the brand\'s security code length', () {
      expect(check(validator(), cvv: '12').messageFor(CardField.cvv), isNotNull);
      expect(check(validator(), cvv: '1234').messageFor(CardField.cvv), isNotNull);

      final amex = check(
        validator(),
        number: '3782 822463 10005',
        brand: CardBrand.amex,
        cvv: '1234',
      );
      expect(amex.isValid, isTrue);
    });

    test('rejects a banned issuing country', () {
      final result = check(validator(banned: {'IR', 'ZA'}));
      expect(result.isValid, isFalse);
      expect(result.messageFor(CardField.country), isNotNull);
    });

    test('follows the banned list as it is reconfigured', () {
      expect(check(validator(banned: {})).isValid, isTrue);
      expect(check(validator(banned: {'ZA'})).isValid, isFalse);
    });

    test('rejects a card that has already been captured', () {
      final result = check(validator(existing: {'4574487405351567'}));
      expect(result.messageFor(CardField.number), contains('already been captured'));
    });

    test('treats a differently formatted duplicate as the same card', () {
      final result = check(
        validator(existing: {'4574487405351567'}),
        number: '4574-4874-0535-1567',
      );
      expect(result.isValid, isFalse);
    });

    test('does not demand a checksum from UnionPay', () {
      // UnionPay numbers are not required to satisfy Luhn.
      final result = check(
        validator(),
        number: '6212345678901232',
        brand: CardBrand.unionPay,
      );
      expect(result.messageFor(CardField.number), isNull);
    });

    test('reports every problem at once, on the right field', () {
      final result = check(
        validator(banned: {'ZA'}),
        number: '4574 4874 0535 1566',
        cvv: '',
      );
      expect(result.failures.length, 3);
      expect(result.messageFor(CardField.number), isNotNull);
      expect(result.messageFor(CardField.cvv), isNotNull);
      expect(result.messageFor(CardField.country), isNotNull);
    });

    test('asks for the missing pieces rather than failing silently', () {
      final result =
          check(validator(), number: '', expiry: '', cvv: '', country: '');
      expect(result.messageFor(CardField.number), 'Enter the card number.');
      expect(result.messageFor(CardField.expiry), 'Enter the expiry date.');
      expect(result.messageFor(CardField.cvv), contains('Enter the'));
      expect(result.messageFor(CardField.country), 'Select the issuing country.');
    });
  });
}
