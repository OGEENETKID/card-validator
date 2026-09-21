import '../models/card_brand.dart';

/// Card scheme inference from the number.
abstract final class CardBrandDetector {
  /// Digits only.
  static String normalise(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// The brand that claims [input], or [CardBrand.unknown].
  ///
  /// Longest matching prefix wins: the published ranges overlap, e.g.
  /// 622126-622925 (Discover) sits inside 62 (UnionPay).
  static CardBrand detect(String input) {
    final digits = normalise(input);
    if (digits.isEmpty) return CardBrand.unknown;

    IinRange? best;
    CardBrand match = CardBrand.unknown;

    for (final brand in CardBrand.selectable) {
      for (final range in brand.ranges) {
        if (!range.matches(digits)) continue;
        final width = range.low.toString().length;
        if (best == null || width > best.low.toString().length) {
          best = range;
          match = brand;
        }
      }
    }

    return match;
  }

  /// Resolves only once one brand is still possible, for the live badge.
  /// A leading 3 could still be Amex, Diners or JCB.
  static CardBrand detectWhileTyping(String input) {
    final digits = normalise(input);
    if (digits.isEmpty) return CardBrand.unknown;

    final settled = detect(digits);
    if (settled != CardBrand.unknown) return settled;

    final candidates = <CardBrand>{};
    for (final brand in CardBrand.selectable) {
      for (final range in brand.ranges) {
        if (range.couldMatch(digits)) candidates.add(brand);
      }
    }

    return candidates.length == 1 ? candidates.first : CardBrand.unknown;
  }
}
