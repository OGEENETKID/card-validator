import 'package:flutter/material.dart';

import '../../models/card_brand.dart';
import '../theme.dart';

/// Scheme mark, set in type rather than shipping trademarked logos.
class BrandMark extends StatelessWidget {
  const BrandMark(this.brand, {super.key, this.dense = false});

  final CardBrand brand;

  /// Smaller, for use inside a list row or a dropdown item.
  final bool dense;

  static String abbreviate(CardBrand brand) => switch (brand) {
        CardBrand.visa => 'VISA',
        CardBrand.mastercard => 'MC',
        CardBrand.amex => 'AMEX',
        CardBrand.discover => 'DISC',
        CardBrand.dinersClub => 'DINE',
        CardBrand.jcb => 'JCB',
        CardBrand.unionPay => 'UPAY',
        CardBrand.maestro => 'MAES',
        CardBrand.unknown => '—',
      };

  @override
  Widget build(BuildContext context) {
    final known = brand != CardBrand.unknown;
    return Container(
      width: dense ? 44 : 52,
      height: dense ? 26 : 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: known ? AppColors.ink : AppColors.paper,
        borderRadius: BorderRadius.circular(4),
        border: known ? null : Border.all(color: AppColors.hairline),
      ),
      child: Text(
        abbreviate(brand),
        style: TextStyle(
          color: known ? Colors.white : AppColors.muted,
          fontSize: dense ? 10 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
