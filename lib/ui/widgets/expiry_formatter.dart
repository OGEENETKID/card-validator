import 'package:flutter/services.dart';

/// Formats an expiry date as MM/YY while it is typed, inserting the slash and
/// padding a single-digit month that can only be a month (2 to 9 becomes 02
/// to 09, but 1 is left alone in case 10, 11 or 12 is coming).
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final deleting = newValue.text.length < oldValue.text.length;
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 4) digits = digits.substring(0, 4);

    if (!deleting && digits.length == 1) {
      final first = int.parse(digits);
      if (first > 1) digits = '0$digits';
    }

    if (digits.length >= 3) {
      final month = int.parse(digits.substring(0, 2));
      if (month < 1) digits = '01${digits.substring(2)}';
      if (month > 12) digits = '12${digits.substring(2)}';
    }

    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
