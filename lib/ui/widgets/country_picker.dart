import 'package:flutter/material.dart';

import '../../models/country.dart';
import '../theme.dart';

/// Searchable country list. Returns the chosen ISO code, or null.
/// [bannedCodes] are listed but marked.
Future<String?> showCountryPicker(
  BuildContext context, {
  Set<String> bannedCodes = const {},
  Set<String> excludeCodes = const {},
  String title = 'Issuing country',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => _CountryPickerSheet(
      bannedCodes: bannedCodes,
      excludeCodes: excludeCodes,
      title: title,
    ),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.bannedCodes,
    required this.excludeCodes,
    required this.title,
  });

  final Set<String> bannedCodes;
  final Set<String> excludeCodes;
  final String title;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = Countries.search(_query)
        .where((c) => !widget.excludeCodes.contains(c.code))
        .toList();
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search countries',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text('No country matches that search.',
                          style: TextStyle(color: AppColors.muted)),
                    )
                  : ListView.separated(
                      controller: controller,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                      itemBuilder: (context, index) {
                        final country = results[index];
                        final banned = widget.bannedCodes.contains(country.code);
                        return ListTile(
                          leading: Text(country.flag, style: const TextStyle(fontSize: 22)),
                          title: Text(country.name),
                          subtitle: banned
                              ? const Text('On the banned list',
                                  style: TextStyle(color: AppColors.rejected, fontSize: 13))
                              : null,
                          trailing: Text(
                            country.code,
                            style: const TextStyle(
                              fontFamily: AppTheme.monoFamily,
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(country.code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
