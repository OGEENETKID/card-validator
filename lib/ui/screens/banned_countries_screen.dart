import 'package:flutter/material.dart';

import '../../models/country.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/country_picker.dart';

class BannedCountriesScreen extends StatelessWidget {
  const BannedCountriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final codes = state.bannedCountryCodes.toList()
      ..sort((a, b) => Countries.nameOf(a).compareTo(Countries.nameOf(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banned countries'),
        actions: [
          if (state.bannedListIsCustomised)
            TextButton(
              onPressed: () => state.resetBannedCountries(),
              child: const Text('Reset'),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cards issued in these countries are refused. Tap a country to '
                  'change the reason. Changes apply to the next card you submit '
                  'and are kept on this device.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (state.bannedListSource != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.bannedListReviewed == null
                        ? 'Source: ${state.bannedListSource}'
                        : 'Source: ${state.bannedListSource} '
                            '(reviewed ${state.bannedListReviewed})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: codes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'No countries are banned. Every card will pass the country check.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: codes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final code = codes[index];
                      final country = Countries.byCode(code);
                      final reason = state.bannedCountryReason(code);

                      return ListTile(
                        leading: Text(country?.flag ?? '\u{1F3F3}',
                            style: const TextStyle(fontSize: 22)),
                        title: Text(Countries.nameOf(code)),
                        subtitle: Text(
                          reason ?? 'No reason recorded',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            fontStyle: reason == null ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                        onTap: () async {
                          final updated = await showReasonDialog(
                            context,
                            countryName: Countries.nameOf(code),
                            initial: reason,
                          );
                          if (updated != null) {
                            await state.setBannedCountryReason(code, updated);
                          }
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(code,
                                style: const TextStyle(
                                    fontFamily: AppTheme.monoFamily,
                                    fontSize: 13,
                                    color: AppColors.muted)),
                            IconButton(
                              tooltip: 'Allow ${Countries.nameOf(code)}',
                              icon: const Icon(Icons.close, color: AppColors.muted),
                              onPressed: () => state.unbanCountry(code),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.block),
        label: const Text('Ban a country'),
        onPressed: () async {
          final code = await showCountryPicker(
            context,
            title: 'Ban a country',
            excludeCodes: state.bannedCountryCodes,
          );
          if (code == null || !context.mounted) return;

          final reason = await showReasonDialog(
            context,
            countryName: Countries.nameOf(code),
            initial: state.defaultBannedReason(code),
          );
          if (reason == null) return;

          await state.banCountry(code, reason: reason);
        },
      ),
    );
  }
}

/// Captures or edits the reason a country is refused. Returns null if
/// dismissed, so an empty string can still mean "no reason".
Future<String?> showReasonDialog(
  BuildContext context, {
  required String countryName,
  String? initial,
}) {
  final controller = TextEditingController(text: initial ?? '');

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Why is $countryName refused?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Comprehensive sanctions',
              counterText: '',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          const SizedBox(height: 8),
          Text(
            'Shown against the country and kept with the rule.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
