import 'package:flutter/services.dart';

import '../../core/card_brand_detector.dart';
import '../../models/card_brand.dart';

/// Groups digits per the brand's print layout and caps the length at the
/// longest number that brand issues. Holds the caret position on mid-string
/// edits.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = CardBrandDetector.normalise(newValue.text);
    final brand = CardBrandDetector.detectWhileTyping(digits);
    final limit = brand == CardBrand.unknown ? 19 : brand.maxLength;
    final trimmed = digits.length > limit ? digits.substring(0, limit) : digits;

    // Digits to the left of the caret before reformatting.
    final rawCaret = newValue.selection.baseOffset;
    final safeCaret = rawCaret < 0
        ? newValue.text.length
        : (rawCaret > newValue.text.length ? newValue.text.length : rawCaret);
    final digitsBeforeCaret =
        CardBrandDetector.normalise(newValue.text.substring(0, safeCaret)).length;
    final caretAtEnd = digitsBeforeCaret >= trimmed.length;

    final buffer = StringBuffer();
    var index = 0;
    int? caret;

    for (final size in brand.groups) {
      if (index >= trimmed.length) break;
      if (buffer.isNotEmpty) buffer.write(' ');

      final remaining = trimmed.length - index;
      final end = index + (size < remaining ? size : remaining);
      buffer.write(trimmed.substring(index, end));
      index = end;

      if (!caretAtEnd && caret == null && index >= digitsBeforeCaret) {
        caret = buffer.length - (index - digitsBeforeCaret);
      }
    }

    // Anything past the last defined group.
    if (index < trimmed.length) buffer.write(' ${trimmed.substring(index)}');

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
    );
  }
}
