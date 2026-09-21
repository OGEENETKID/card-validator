import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/country.dart';
import '../../models/credit_card.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';

/// Everything held against one saved card.
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.card});

  final CreditCard card;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  bool _codeVisible = false;

  CreditCard get card => widget.card;

  Future<void> _copyNumber() async {
    await Clipboard.setData(ClipboardData(text: card.number));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Card number copied.')));
  }

  Future<void> _delete() async {
    final confirmed = await confirmRemoveCard(context, card);
    if (!confirmed || !mounted) return;

    await AppScope.read(context).removeCard(card.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final country = Countries.byCode(card.countryCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Card details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BrandMark(card.brand),
                    const SizedBox(width: 12),
                    Text(card.brand.label,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 18),
                SelectableText(card.formatted, style: AppTheme.pan),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: _copyNumber,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.action,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: const Text('Copy number'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _DetailRow(label: 'Card type', value: card.brand.label),
          _DetailRow(
            label: 'Expiry date',
            value: card.expiry.isEmpty ? 'Not recorded' : card.expiry,
          ),
          _DetailRow(
            label: card.brand.securityCodeLabel,
            value: card.cvv.isEmpty
                ? 'Not recorded'
                : (_codeVisible ? card.cvv : '\u2022' * card.cvv.length),
            trailing: card.cvv.isEmpty
                ? null
                : TextButton(
                    onPressed: () => setState(() => _codeVisible = !_codeVisible),
                    style: TextButton.styleFrom(foregroundColor: AppColors.action),
                    child: Text(_codeVisible ? 'Hide' : 'Show'),
                  ),
          ),
          _DetailRow(
            label: 'Issuing country',
            value: country == null
                ? card.countryCode
                : '${country.flag}  ${country.name} (${country.code})',
          ),
          _DetailRow(label: 'Captured', value: _formatTimestamp(card.capturedAt)),

          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rejected,
              side: const BorderSide(color: AppColors.hairline),
            ),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Delete this card'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 15, color: AppColors.ink)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Asks before deleting. Shared with the swipe action on the list.
Future<bool> confirmRemoveCard(BuildContext context, CreditCard card) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Remove this card?'),
      content: Text('${card.brand.label} ending ${card.last4} will be deleted '
          'from this device.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.rejected),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  return result ?? false;
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatTimestamp(DateTime at) {
  final hh = at.hour.toString().padLeft(2, '0');
  final mm = at.minute.toString().padLeft(2, '0');
  return '${at.day} ${_months[at.month - 1]} ${at.year} at $hh:$mm';
}
