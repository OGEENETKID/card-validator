import '../models/card_brand.dart';
import 'card_brand_detector.dart';
import 'luhn.dart';

/// The field a rule failed on, so the form can place the message.
enum CardField { number, brand, expiry, cvv, country }

class ValidationFailure {
  const ValidationFailure(this.field, this.message);

  final CardField field;
  final String message;

  @override
  String toString() => message;
}

class ValidationResult {
  const ValidationResult(this.failures);

  const ValidationResult.valid() : failures = const [];

  final List<ValidationFailure> failures;

  bool get isValid => failures.isEmpty;

  String? messageFor(CardField field) {
    for (final failure in failures) {
      if (failure.field == field) return failure.message;
    }
    return null;
  }
}

/// The rules that decide whether a submitted card may be stored.
class CardValidator {
  const CardValidator({
    required this.bannedCountryCodes,
    required this.existingNumbers,
    this.now,
  });

  /// ISO 3166-1 alpha-2 codes that may not issue a card.
  final Set<String> bannedCountryCodes;

  /// Numbers already captured, for the duplicate check.
  final Set<String> existingNumbers;

  /// Injectable for tests; defaults to the current date.
  final DateTime? now;

  ValidationResult validate({
    required String number,
    required CardBrand brand,
    required String expiry,
    required String cvv,
    required String countryCode,
  }) {
    final digits = CardBrandDetector.normalise(number);
    final failures = <ValidationFailure>[];

    if (digits.isEmpty) {
      failures.add(const ValidationFailure(CardField.number, 'Enter the card number.'));
    } else if (digits.length < 12) {
      failures.add(const ValidationFailure(CardField.number, 'A card number has at least 12 digits.'));
    } else if (!brand.lengths.contains(digits.length)) {
      failures.add(ValidationFailure(
        CardField.number,
        '${brand.label} numbers are ${_lengthsPhrase(brand)} digits long, not ${digits.length}.',
      ));
    } else if (brand.requiresLuhn && !Luhn.isValid(digits)) {
      failures.add(const ValidationFailure(
        CardField.number,
        'This number fails the checksum. Check for a mistyped digit.',
      ));
    } else if (existingNumbers.contains(digits)) {
      failures.add(const ValidationFailure(
        CardField.number,
        'This card has already been captured.',
      ));
    }

    final inferred = CardBrandDetector.detect(digits);
    if (inferred != CardBrand.unknown && inferred != brand && digits.length >= 6) {
      failures.add(ValidationFailure(
        CardField.brand,
        'This number is issued by ${inferred.label}.',
      ));
    }

    final expiryDate = parseExpiry(expiry);
    if (expiry.isEmpty) {
      failures.add(const ValidationFailure(CardField.expiry, 'Enter the expiry date.'));
    } else if (expiryDate == null) {
      failures.add(const ValidationFailure(CardField.expiry, 'Use the format MM/YY.'));
    } else if (expiryDate.isBefore(_startOfThisMonth)) {
      failures.add(const ValidationFailure(CardField.expiry, 'This card has expired.'));
    }

    if (cvv.isEmpty) {
      failures.add(ValidationFailure(
        CardField.cvv,
        'Enter the ${brand.securityCodeLabel}.',
      ));
    } else if (cvv.length != brand.cvvLength || int.tryParse(cvv) == null) {
      failures.add(ValidationFailure(
        CardField.cvv,
        '${brand.label} cards use a ${brand.cvvLength}-digit code.',
      ));
    }

    if (countryCode.isEmpty) {
      failures.add(const ValidationFailure(CardField.country, 'Select the issuing country.'));
    } else if (bannedCountryCodes.contains(countryCode.toUpperCase())) {
      failures.add(const ValidationFailure(
        CardField.country,
        'Cards issued in this country cannot be accepted.',
      ));
    }

    return ValidationResult(failures);
  }

  DateTime get _startOfThisMonth {
    final today = now ?? DateTime.now();
    return DateTime(today.year, today.month);
  }

  /// The first day of the month an MM/YY string refers to, or null if it is
  /// not a valid month. A card is good until the end of its expiry month.
  static DateTime? parseExpiry(String input) {
    final match = RegExp(r'^\s*(\d{1,2})\s*/?\s*(\d{2}|\d{4})\s*$').firstMatch(input);
    if (match == null) return null;

    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return null;

    final rawYear = match.group(2)!;
    final year = rawYear.length == 2 ? 2000 + int.parse(rawYear) : int.parse(rawYear);
    return DateTime(year, month);
  }

  static String _lengthsPhrase(CardBrand brand) {
    final lengths = brand.lengths.toList()..sort();
    if (lengths.length == 1) return '${lengths.first}';
    if (lengths.last - lengths.first == lengths.length - 1) {
      return '${lengths.first}–${lengths.last}';
    }
    return '${lengths.sublist(0, lengths.length - 1).join(', ')} or ${lengths.last}';
  }
}
