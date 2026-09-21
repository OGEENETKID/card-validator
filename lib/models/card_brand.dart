/// Supported card schemes and the rules needed to infer and validate them.
///
/// Prefixes are IIN (issuer identification number) ranges, the form the
/// schemes publish them in.
enum CardBrand {
  visa(
    label: 'Visa',
    ranges: [IinRange(4, 4)],
    lengths: {13, 16, 19},
    cvvLength: 3,
    securityCodeLabel: 'CVV2',
  ),
  mastercard(
    label: 'Mastercard',
    // 2221-2720 is the 2-series range, opened 2017.
    ranges: [IinRange(51, 55), IinRange(2221, 2720)],
    lengths: {16},
    cvvLength: 3,
    securityCodeLabel: 'CVC2',
  ),
  amex(
    label: 'American Express',
    ranges: [IinRange(34, 34), IinRange(37, 37)],
    lengths: {15},
    cvvLength: 4,
    securityCodeLabel: 'CID',
  ),
  discover(
    label: 'Discover',
    ranges: [
      IinRange(6011, 6011),
      IinRange(644, 649),
      IinRange(65, 65),
      IinRange(622126, 622925),
    ],
    lengths: {16, 19},
    cvvLength: 3,
    securityCodeLabel: 'CID',
  ),
  dinersClub(
    label: 'Diners Club',
    ranges: [IinRange(300, 305), IinRange(3095, 3095), IinRange(36, 36), IinRange(38, 39)],
    lengths: {14, 16, 19},
    cvvLength: 3,
  ),
  jcb(
    label: 'JCB',
    ranges: [IinRange(3528, 3589)],
    lengths: {16, 17, 18, 19},
    cvvLength: 3,
    securityCodeLabel: 'CAV2',
  ),
  unionPay(
    label: 'UnionPay',
    ranges: [IinRange(62, 62), IinRange(81, 81)],
    lengths: {16, 17, 18, 19},
    cvvLength: 3,
    securityCodeLabel: 'CVN2',
    // UnionPay numbers need not satisfy the Luhn checksum.
    requiresLuhn: false,
  ),
  maestro(
    label: 'Maestro',
    ranges: [
      IinRange(5018, 5018),
      IinRange(5020, 5020),
      IinRange(5038, 5038),
      IinRange(5893, 5893),
      IinRange(6304, 6304),
      IinRange(6759, 6759),
      IinRange(6761, 6763),
    ],
    lengths: {12, 13, 14, 15, 16, 17, 18, 19},
    cvvLength: 3,
  ),

  /// No scheme claims the number. A real value rather than null so the form
  /// can still capture the card.
  unknown(
    label: 'Unknown',
    ranges: [],
    lengths: {12, 13, 14, 15, 16, 17, 18, 19},
    cvvLength: 3,
  );

  const CardBrand({
    required this.label,
    required this.ranges,
    required this.lengths,
    required this.cvvLength,
    this.securityCodeLabel = 'CVV',
    this.requiresLuhn = true,
  });

  final String label;
  final List<IinRange> ranges;
  final Set<int> lengths;
  final int cvvLength;
  final bool requiresLuhn;

  /// What the scheme calls the security code. Cards print CVV, CVC, CID or
  /// CVN depending on the issuer.
  final String securityCodeLabel;

  /// Selectable in the form, most common first.
  static const List<CardBrand> selectable = [
    CardBrand.visa,
    CardBrand.mastercard,
    CardBrand.amex,
    CardBrand.discover,
    CardBrand.dinersClub,
    CardBrand.jcb,
    CardBrand.unionPay,
    CardBrand.maestro,
    CardBrand.unknown,
  ];

  /// Display grouping. Amex prints 4-6-5, Diners 4-6-4.
  List<int> get groups => switch (this) {
        CardBrand.amex => const [4, 6, 5],
        CardBrand.dinersClub => const [4, 6, 4],
        _ => const [4, 4, 4, 4, 3],
      };

  int get maxLength => lengths.reduce((a, b) => a > b ? a : b);

  static CardBrand fromName(String name) =>
      CardBrand.values.firstWhere((b) => b.name == name, orElse: () => CardBrand.unknown);
}

/// An inclusive IIN prefix range, compared at the width of its own digits:
/// `IinRange(2221, 2720)` looks at the first four.
class IinRange {
  const IinRange(this.low, this.high);

  final int low;
  final int high;

  bool matches(String digits) {
    final width = low.toString().length;
    if (digits.length < width) return false;
    final prefix = int.tryParse(digits.substring(0, width));
    return prefix != null && prefix >= low && prefix <= high;
  }

  /// True while a partial number could still fall in range.
  bool couldMatch(String digits) {
    final width = low.toString().length;
    if (digits.isEmpty) return false;
    if (digits.length >= width) return matches(digits);
    final typed = int.tryParse(digits);
    if (typed == null) return false;
    final scale = _pow10(width - digits.length);
    return typed * scale <= high && (typed + 1) * scale - 1 >= low;
  }

  static int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}
