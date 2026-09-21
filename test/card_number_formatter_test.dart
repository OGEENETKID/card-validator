import 'package:card_validator/ui/widgets/card_number_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final formatter = CardNumberFormatter();

  TextEditingValue type(String text, {int? caret}) => TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret ?? text.length),
      );

  TextEditingValue format(String text, {int? caret, String previous = ''}) =>
      formatter.formatEditUpdate(type(previous), type(text, caret: caret));

  group('CardNumberFormatter', () {
    test('groups a Visa number in fours', () {
      expect(format('4574487405351567').text, '4574 4874 0535 1567');
    });

    test('groups Amex the way Amex prints it', () {
      expect(format('378282246310005').text, '3782 822463 10005');
    });

    test('groups Diners in 4-6-4', () {
      expect(format('30569309025904').text, '3056 930902 5904');
    });

    test('stops at the longest number the brand issues', () {
      // Amex is 15 digits.
      expect(format('3782822463100051234').text, '3782 822463 10005');
    });

    test('formats as you type', () {
      expect(format('4574').text, '4574');
      expect(format('45744').text, '4574 4');
      expect(format('4574 48').text, '4574 48');
    });

    test('ignores characters that are not digits', () {
      expect(format('4574-4874-0535-1567').text, '4574 4874 0535 1567');
      expect(format('4574abc4874').text, '4574 4874');
    });

    test('leaves the caret where the typist put it', () {
      // Inserting a 9 after the first group.
      final result = format('4574 94874 0535 1567', caret: 6);
      expect(result.text, '4574 9487 4053 5156 7');
      expect(result.selection.baseOffset, 6);
    });

    test('puts the caret at the end when appending', () {
      final result = format('45744874', caret: 8);
      expect(result.text, '4574 4874');
      expect(result.selection.baseOffset, result.text.length);
    });
  });
}
