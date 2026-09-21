import 'package:card_validator/ui/widgets/expiry_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final formatter = ExpiryFormatter();

  TextEditingValue value(String text) => TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );

  String format(String text, {String previous = ''}) =>
      formatter.formatEditUpdate(value(previous), value(text)).text;

  group('ExpiryFormatter', () {
    test('inserts the slash', () {
      expect(format('1229'), '12/29');
      expect(format('0825'), '08/25');
    });

    test('pads a month that can only be a month', () {
      expect(format('4'), '04');
      expect(format('9'), '09');
      // 1 is left alone, since 10, 11 and 12 are still possible.
      expect(format('1'), '1');
    });

    test('clamps an impossible month', () {
      expect(format('1329'), '12/29');
      expect(format('0029'), '01/29');
    });

    test('stops at four digits', () {
      expect(format('122912'), '12/29');
    });

    test('strips anything that is not a digit', () {
      expect(format('12/29'), '12/29');
      expect(format('12-29'), '12/29');
      expect(format('ab12'), '12');
    });

    test('allows deleting back through the slash', () {
      expect(format('12/2', previous: '12/29'), '12/2');
      expect(format('12', previous: '12/2'), '12');
      expect(format('1', previous: '12'), '1');
    });
  });
}
