import 'package:flutter/material.dart';

import '../../models/country.dart';
import '../../models/credit_card.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';
import 'add_card_screen.dart';
import 'banned_countries_screen.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cards = state.cards;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Captured cards'),
        actions: [
          IconButton(
            tooltip: 'Banned countries',
            icon: const Icon(Icons.public_off_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BannedCountriesScreen()),
            ),
          ),
        ],
      ),
      body: !state.isReady
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
              ? const _EmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: Text(
                        '${cards.length} card${cards.length == 1 ? '' : 's'} on this device · '
                        '${state.bannedCountryCodes.length} country rules active',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) => _CardRow(card: cards[index]),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.action,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add card'),
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddCardScreen()),
          );
          if (saved == true && context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('Card saved.')));
          }
        },
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card});

  final CreditCard card;

  @override
  Widget build(BuildContext context) {
    final country = Countries.byCode(card.countryCode);

    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.rejected,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
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
          ) ??
          false,
      onDismissed: (_) => AppScope.read(context).removeCard(card.id),
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandMark(card.brand),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.masked, style: AppTheme.pan),
                  const SizedBox(height: 6),
                  Text(
                    '${card.brand.label} · ${country?.flag ?? ''} '
                    '${Countries.nameOf(card.countryCode)}'
                    '${card.expiry.isEmpty ? '' : ' · exp ${card.expiry}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(_time(card.capturedAt), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime at) {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_outlined, size: 40, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              'No cards captured yet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a card by typing the details, or scan one with the camera.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
