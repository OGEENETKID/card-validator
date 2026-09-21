import 'package:card_validator/core/card_number_parser.dart';
import 'package:card_validator/models/card_brand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardNumberParser', () {
    test('reads the number off a clean scan', () {
      final result = CardNumberParser.best([
        'VISA',
        '4574 4874 0535 1567',
        'valid thru',
        'PETER PAN',
        '08/20',
      ]);

      expect(result, isNotNull);
      expect(result!.digits, '4574487405351567');
      expect(result.brand, CardBrand.visa);
    });

    test('ignores the four-digit repeat printed under the number', () {
      // The repeat under the PAN must not be spliced onto it.
      final result = CardNumberParser.best([
        'Bank Name',
        '1234 5678 9876 5432',
        '1234',
        'VALID THRU 12/99',
        'CARDHOLDER',
      ]);

      expect(result!.digits, '1234567898765432');
    });

    test('recovers the number when OCR runs it together with the expiry', () {
      final result = CardNumberParser.best(['5412 7512 3412 3456 12 23']);
      expect(result!.digits, '5412751234123456');
      expect(result.brand, CardBrand.mastercard);
    });

    test('repairs characters OCR commonly mistakes for digits', () {
      final result = CardNumberParser.best(['4S74 4B74 OS3S 1S67']);
      expect(result!.digits, '4574487405351567');
      expect(result.checksumValid, isTrue);
    });

    test('prefers the number that checks out over other digit runs', () {
      final result = CardNumberParser.best([
        'MEMBER SINCE 2014 0000 0000',
        '4242 4242 4242 4242',
        'CVC 123',
      ]);

      expect(result!.digits, '4242424242424242');
    });

    test('still returns a candidate when the checksum fails', () {
      // Pre-fill and let the number be corrected.
      final result = CardNumberParser.best(['1234 5678 9876 5432']);
      expect(result, isNotNull);
      expect(result!.checksumValid, isFalse);
    });

    test('returns nothing when there is no number to find', () {
      expect(CardNumberParser.best(['CARDHOLDER', 'valid thru', 'VISA']), isNull);
    });

    test('accepts dashes and en dashes as separators', () {
      final result = CardNumberParser.best(['4242-4242-4242-4242']);
      expect(result!.digits, '4242424242424242');
    });

    test('reads a security code printed on the front', () {
      // One of the sample cards prints "CVC 123" beside the number.
      expect(CardNumberParser.securityCode(['CVC 123']), '123');
      expect(CardNumberParser.securityCode(['CVV: 456']), '456');
      expect(CardNumberParser.securityCode(['CID 1234']), '1234');
      expect(CardNumberParser.securityCode(['cvc2 789']), '789');
    });

    test('does not mistake other digits for a security code', () {
      expect(CardNumberParser.securityCode(['4242 4242 4242 4242']), isNull);
      expect(CardNumberParser.securityCode(['VALID THRU 12/28']), isNull);
      expect(CardNumberParser.securityCode(['MEMBER SINCE 2014']), isNull);
    });

    test('reads the expiry date', () {
      expect(CardNumberParser.expiry(['VALID THRU 08/20']), '08/20');
      expect(CardNumberParser.expiry(['MONTH/YEAR 12 / 2028']), '12/28');
      expect(CardNumberParser.expiry(['PETER PAN']), isNull);
      // 13 is not a month.
      expect(CardNumberParser.expiry(['13/25']), isNull);
    });
  });
}
