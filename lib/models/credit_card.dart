import 'card_brand.dart';

/// A captured card. [number] is the full PAN, needed for the duplicate
/// check; the UI only ever renders [masked].
class CreditCard {
  const CreditCard({
    required this.id,
    required this.number,
    required this.brand,
    required this.countryCode,
    required this.capturedAt,
    required this.expiry,
    required this.cvv,
  });

  final String id;

  /// Digits only, no separators.
  final String number;
  final CardBrand brand;

  /// ISO 3166-1 alpha-2.
  final String countryCode;
  final DateTime capturedAt;

  /// Expiry as printed on the card, MM/YY.
  final String expiry;

  /// The security code, whatever the card calls it (CVV, CVC, CID, CVN).
  final String cvv;

  String get last4 => number.length >= 4 ? number.substring(number.length - 4) : number;

  /// `•••• •••• •••• 1567`, grouped the way the brand prints its numbers.
  String get masked {
    final hidden = '•' * (number.length - last4.length);
    return _group('$hidden$last4');
  }

  /// The full number, grouped. Only for an explicit reveal.
  String get formatted => _group(number);

  String _group(String value) {
    final buffer = StringBuffer();
    var index = 0;
    for (final size in brand.groups) {
      if (index >= value.length) break;
      final remaining = value.length - index;
      final end = index + (size < remaining ? size : remaining);
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(value.substring(index, end));
      index = end;
    }
    if (index < value.length) buffer.write(' ${value.substring(index)}');
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'brand': brand.name,
        'countryCode': countryCode,
        'capturedAt': capturedAt.toIso8601String(),
        'expiry': expiry,
        'cvv': cvv,
      };

  factory CreditCard.fromJson(Map<String, dynamic> json) => CreditCard(
        id: json['id'] as String,
        number: json['number'] as String,
        brand: CardBrand.fromName(json['brand'] as String? ?? ''),
        countryCode: json['countryCode'] as String? ?? '',
        capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ?? DateTime.now(),
        expiry: json['expiry'] as String? ?? '',
        cvv: json['cvv'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) => other is CreditCard && other.number == number;

  @override
  int get hashCode => number.hashCode;
}
