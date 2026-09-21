import 'card_brand_detector.dart';
import 'luhn.dart';
import '../models/card_brand.dart';

/// A scored card number candidate from a scan.
class ScanCandidate {
  const ScanCandidate({
    required this.digits,
    required this.brand,
    required this.score,
    required this.checksumValid,
  });

  final String digits;
  final CardBrand brand;
  final int score;

  /// Whether the digits satisfy the scheme's checksum rules.
  final bool checksumValid;

  @override
  String toString() => 'ScanCandidate($digits, ${brand.label}, score: $score)';
}

/// Extracts card number candidates from recognised text.
///
/// No ML Kit types here, so it can be tested without a device.
abstract final class CardNumberParser {
  /// Lookalikes OCR returns instead of digits. Applied only to runs that
  /// already look like a number, never to the whole page.
  static const Map<String, String> _lookalikes = {
    'O': '0', 'o': '0', 'D': '0', 'Q': '0',
    'I': '1', 'l': '1', '|': '1', 'i': '1',
    'Z': '2', 'z': '2',
    'S': '5', 's': '5',
    'G': '6',
    'T': '7', '?': '7',
    'B': '8',
    'g': '9', 'q': '9',
  };

  /// A grouped run of digit-like characters. The word boundaries stop it
  /// swallowing the cardholder name.
  static final RegExp _run = RegExp(
    r'(?<![\w])[0-9OoDQIl|iZzSsGT?Bgq][0-9OoDQIl|iZzSsGT?Bgq \-\u2013\u2014.]{10,26}[0-9OoDQIl|iZzSsGT?Bgq](?![\w])',
  );

  /// Expiry dates: MM/YY or MM/YYYY.
  static final RegExp _expiry = RegExp(r'\b(0[1-9]|1[0-2])\s*[/\-]\s*(\d{2}(?:\d{2})?)\b');

  /// Every plausible card number in [lines], best first.
  ///
  /// [lines] must be split per line. Cards often print a repeat of the last
  /// four digits under the PAN; flattening the page splices them together.
  static List<ScanCandidate> candidates(Iterable<String> lines) {
    final seen = <String>{};
    final found = <ScanCandidate>[];

    for (final line in lines) {
      for (final match in _run.allMatches(line)) {
        for (final digits in _expand(_repair(match.group(0)!))) {
          if (!seen.add(digits)) continue;
          final brand = CardBrandDetector.detect(digits);
          found.add(ScanCandidate(
            digits: digits,
            brand: brand,
            score: _score(digits, brand),
            checksumValid: !brand.requiresLuhn || Luhn.isValid(digits),
          ));
        }
      }
    }

    found.sort((a, b) => b.score.compareTo(a.score));
    return found;
  }

  /// The best candidate, or null if nothing reads as a card number. A
  /// candidate that fails validation is still returned so it can be fixed.
  static ScanCandidate? best(Iterable<String> lines) {
    final all = candidates(lines);
    return all.isEmpty ? null : all.first;
  }

  /// The security code, if the card prints it on the front. Schemes label it
  /// CVV, CVC, CID or CVN, so the usual spellings are all matched.
  static final RegExp _securityCode = RegExp(
    r'\b(?:CVV2?|CVC2?|CID|CVN2?|CSC|CV2)\b\s*[:.\-]?\s*(\d{3,4})\b',
    caseSensitive: false,
  );

  /// The security code printed on the card, if there is one.
  static String? securityCode(Iterable<String> lines) {
    for (final line in lines) {
      final match = _securityCode.firstMatch(line);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// The expiry date printed on the card, as `MM/YY`, if present.
  static String? expiry(Iterable<String> lines) {
    for (final line in lines) {
      final match = _expiry.firstMatch(line);
      if (match == null) continue;
      final year = match.group(2)!;
      return '${match.group(1)}/${year.length == 4 ? year.substring(2) : year}';
    }
    return null;
  }

  /// A run, plus the shorter numbers inside it.
  ///
  /// OCR sometimes joins the PAN to the expiry or CVC hint beside it. Testing
  /// prefixes of a valid card length recovers the PAN.
  static Iterable<String> _expand(String digits) sync* {
    if (digits.length >= 12 && digits.length <= 19) yield digits;
    if (digits.length <= 12) return;

    final brand = CardBrandDetector.detect(digits);

    // Leave a plausible run alone: a prefix of a good number can pass the
    // checksum by coincidence.
    final plausible = digits.length <= 19 &&
        (brand == CardBrand.unknown || brand.lengths.contains(digits.length));
    if (plausible) return;

    final lengths = brand == CardBrand.unknown ? const {19, 16, 15, 14, 13} : brand.lengths;
    for (final length in lengths) {
      if (length < digits.length && length >= 12) yield digits.substring(0, length);
    }
  }

  static String _repair(String raw) {
    final buffer = StringBuffer();
    for (final char in raw.split('')) {
      if (char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39) {
        buffer.write(char);
      } else if (_lookalikes.containsKey(char)) {
        buffer.write(_lookalikes[char]);
      }
    }
    return buffer.toString();
  }

  /// Ranks candidates so a valid number beats a stray run of digits.
  static int _score(String digits, CardBrand brand) {
    var score = 0;
    if (Luhn.isValid(digits)) score += 100;
    if (brand != CardBrand.unknown) score += 50;
    if (brand.lengths.contains(digits.length)) score += 25;
    if (digits.length >= 15) score += 10;
    // Tie-break towards the longer reading.
    return score + digits.length;
  }
}
