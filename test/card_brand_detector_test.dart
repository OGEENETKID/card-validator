import 'package:card_validator/core/card_brand_detector.dart';
import 'package:card_validator/models/card_brand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardBrandDetector.detect', () {
    test('identifies the major schemes', () {
      expect(CardBrandDetector.detect('4574487405351567'), CardBrand.visa);
      expect(CardBrandDetector.detect('5412751234123456'), CardBrand.mastercard);
      expect(CardBrandDetector.detect('378282246310005'), CardBrand.amex);
      expect(CardBrandDetector.detect('6011111111111117'), CardBrand.discover);
      expect(CardBrandDetector.detect('30569309025904'), CardBrand.dinersClub);
      expect(CardBrandDetector.detect('3530111333300000'), CardBrand.jcb);
    });

    test('reads the Mastercard 2-series range', () {
      expect(CardBrandDetector.detect('2221000000000009'), CardBrand.mastercard);
      expect(CardBrandDetector.detect('2720990000000000'), CardBrand.mastercard);
      // 2721 is outside the range.
      expect(CardBrandDetector.detect('2721000000000000'), CardBrand.unknown);
    });

    test('prefers the more specific range where two overlap', () {
      // 622126-622925 is Discover, inside UnionPay's 62.
      expect(CardBrandDetector.detect('6221261111111119'), CardBrand.discover);
      expect(CardBrandDetector.detect('6229261111111116'), CardBrand.unionPay);
      // 6759 is Maestro.
      expect(CardBrandDetector.detect('6759649826438453'), CardBrand.maestro);
    });

    test('ignores spaces and dashes', () {
      expect(CardBrandDetector.detect('4574 4874 0535 1567'), CardBrand.visa);
      expect(CardBrandDetector.detect('3782-822463-10005'), CardBrand.amex);
    });

    test('returns unknown rather than guessing', () {
      expect(CardBrandDetector.detect('1234567898765432'), CardBrand.unknown);
      expect(CardBrandDetector.detect(''), CardBrand.unknown);
    });
  });

  group('CardBrandDetector.detectWhileTyping', () {
    test('resolves as soon as one brand is left', () {
      expect(CardBrandDetector.detectWhileTyping('4'), CardBrand.visa);
      expect(CardBrandDetector.detectWhileTyping('54'), CardBrand.mastercard);
    });

    test('waits while several schemes are still possible', () {
      // 3 could still become Amex, Diners or JCB.
      expect(CardBrandDetector.detectWhileTyping('3'), CardBrand.unknown);
      expect(CardBrandDetector.detectWhileTyping('37'), CardBrand.amex);
      expect(CardBrandDetector.detectWhileTyping('353'), CardBrand.jcb);
    });

    test('narrows the Mastercard 2-series as digits arrive', () {
      expect(CardBrandDetector.detectWhileTyping('22'), CardBrand.mastercard);
      expect(CardBrandDetector.detectWhileTyping('2221'), CardBrand.mastercard);
    });
  });
}
