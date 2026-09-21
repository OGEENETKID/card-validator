import 'package:card_validator/core/luhn.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Luhn', () {
    test('accepts the sample cards that carry a real checksum', () {
      expect(Luhn.isValid('4574487405351567'), isTrue);
      expect(Luhn.isValid('4242424242424242'), isTrue);
    });

    test('rejects the sample cards that are only decorative', () {
      // Sample numbers that look like cards but fail the checksum.
      expect(Luhn.isValid('1234567898765432'), isFalse);
      expect(Luhn.isValid('5412751234123456'), isFalse);
    });

    test('catches a single mistyped digit', () {
      expect(Luhn.isValid('4574487405351566'), isFalse);
    });

    test('catches the commonest transposition', () {
      // 74 -> 47 in the middle of a valid number.
      expect(Luhn.isValid('4574487450351567'), isFalse);
    });

    test('rejects non-digits and stubs', () {
      expect(Luhn.isValid('4574 4874'), isFalse);
      expect(Luhn.isValid('4'), isFalse);
      expect(Luhn.isValid(''), isFalse);
    });

    test('computes the digit that completes a number', () {
      expect(Luhn.checkDigitFor('457448740535156'), 7);
      expect(Luhn.isValid('424242424242424${Luhn.checkDigitFor('424242424242424')}'), isTrue);
    });
  });
}
