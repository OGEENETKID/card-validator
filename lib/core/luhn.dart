/// Luhn (mod 10) checksum. Expects digits only.
abstract final class Luhn {
  static bool isValid(String digits) {
    if (digits.length < 2) return false;

    var sum = 0;
    var double = false;

    for (var i = digits.length - 1; i >= 0; i--) {
      final code = digits.codeUnitAt(i) - 0x30;
      if (code < 0 || code > 9) return false;

      var value = code;
      if (double) {
        value *= 2;
        if (value > 9) value -= 9;
      }
      sum += value;
      double = !double;
    }

    return sum % 10 == 0;
  }

  /// The check digit that completes [partial].
  static int checkDigitFor(String partial) {
    var sum = 0;
    var double = true;

    for (var i = partial.length - 1; i >= 0; i--) {
      var value = partial.codeUnitAt(i) - 0x30;
      if (double) {
        value *= 2;
        if (value > 9) value -= 9;
      }
      sum += value;
      double = !double;
    }

    return (10 - (sum % 10)) % 10;
  }
}
