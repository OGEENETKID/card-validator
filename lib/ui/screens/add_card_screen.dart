import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/card_brand_detector.dart';
import '../../core/card_validator.dart';
import '../../models/card_brand.dart';
import '../../models/country.dart';
import '../../scan/card_scanner.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/card_number_formatter.dart';
import '../widgets/country_picker.dart';
import '../widgets/expiry_formatter.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key, this.scanner});

  /// Injectable for tests.
  final CardScanner? scanner;

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _numberFocus = FocusNode();

  // Built on first use so opening the form does not touch the camera.
  CardScanner? _scanner;

  CardScanner get _cardScanner => _scanner ??= widget.scanner ?? CardScanner();

  CardBrand _brand = CardBrand.unknown;
  bool _brandChosenByHand = false;
  String _countryCode = '';
  bool _codeWasScanned = false;
  bool _scanning = false;
  bool _submitting = false;
  Map<CardField, String> _errors = {};

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _numberFocus.dispose();
    if (widget.scanner == null) _scanner?.dispose();
    super.dispose();
  }

  void _onNumberChanged(String value) {
    final inferred = CardBrandDetector.detectWhileTyping(value);
    setState(() {
      _errors = {..._errors}..remove(CardField.number);
      if (!_brandChosenByHand && inferred != _brand) {
        _brand = inferred;
        _errors.remove(CardField.brand);
      }
    });
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      final result = await _cardScanner.scan();
      if (result == null || !mounted) return;

      // Same formatter the keyboard uses, so the field reads identically.
      _numberController.value = CardNumberFormatter().formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: result.number,
          selection: TextSelection.collapsed(offset: result.number.length),
        ),
      );

      if (result.expiry != null) _expiryController.text = result.expiry!;
      if (result.securityCode != null) _cvvController.text = result.securityCode!;

      setState(() {
        _brand = result.brand;
        _brandChosenByHand = false;
        _codeWasScanned = result.securityCode != null;
        _errors = {}
          ..addAll(_errors)
          ..remove(CardField.number)
          ..remove(CardField.expiry)
          ..remove(CardField.cvv);
      });

      if (!result.checksumPassed) {
        _notify('Scanned, but the number didn\'t check out. Compare it with the card.');
      }
    } on ScanException catch (error) {
      if (mounted) _notify(error.message);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _pickCountry() async {
    final state = AppScope.read(context);
    final code = await showCountryPicker(context, bannedCodes: state.bannedCountryCodes);
    if (code == null || !mounted) return;
    setState(() {
      _countryCode = code;
      _errors = {..._errors}..remove(CardField.country);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final result = await AppScope.read(context).submit(
      number: _numberController.text,
      brand: _brand,
      expiry: _expiryController.text,
      cvv: _cvvController.text,
      countryCode: _countryCode,
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _errors = {for (final f in result.failures) f.field: f.message};
    });

    if (result.isValid) {
      Navigator.of(context).pop(true);
    } else {
      _notify(result.failures.first.message);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final inferred = CardBrandDetector.detect(_numberController.text);
    final country = _countryCode.isEmpty ? null : Countries.byCode(_countryCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Add card')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          OutlinedButton.icon(
            onPressed: _scanning ? null : _scan,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined, size: 20),
            label: Text(_scanning ? 'Reading card' : 'Scan card'),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _numberController,
            focusNode: _numberFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [CardNumberFormatter()],
            style: AppTheme.pan,
            autocorrect: false,
            onChanged: _onNumberChanged,
            decoration: InputDecoration(
              labelText: 'Card number',
              errorText: _errors[CardField.number],
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 1,
                  child: BrandMark(_brand),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<CardBrand>(
            value: _brand,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Card type',
              errorText: _errors[CardField.brand],
              helperText: _brandChosenByHand || inferred == CardBrand.unknown
                  ? null
                  : 'Inferred from the number',
              helperStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            // The closed field shows the name on its own, without the mark
            // squeezing it, so the selected type is unambiguous.
            selectedItemBuilder: (context) => [
              for (final brand in CardBrand.selectable)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    brand == CardBrand.unknown ? 'Not recognised' : brand.label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                ),
            ],
            items: [
              for (final brand in CardBrand.selectable)
                DropdownMenuItem(
                  value: brand,
                  child: Row(
                    children: [
                      BrandMark(brand, dense: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          brand == CardBrand.unknown ? 'Not recognised' : brand.label,
                          style: const TextStyle(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (brand) => setState(() {
              _brand = brand ?? CardBrand.unknown;
              _brandChosenByHand = true;
              _errors = {..._errors}..remove(CardField.brand);
            }),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ExpiryFormatter()],
                  onChanged: (_) =>
                      setState(() => _errors = {..._errors}..remove(CardField.expiry)),
                  decoration: InputDecoration(
                    labelText: 'Expiry date',
                    hintText: 'MM/YY',
                    errorText: _errors[CardField.expiry],
                    helperText: 'Valid thru',
                    helperStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: _brand.cvvLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {
                    _codeWasScanned = false;
                    _errors = {..._errors}..remove(CardField.cvv);
                  }),
                  decoration: InputDecoration(
                    labelText: _brand.securityCodeLabel,
                    counterText: '',
                    errorText: _errors[CardField.cvv],
                    helperText: _codeWasScanned
                        ? 'Read from the card'
                        : '${_brand.cvvLength} digits',
                    helperStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cards print the security code as ${_brand.securityCodeLabel}, CVV or CVC '
            'depending on the issuer.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          InkWell(
            onTap: _pickCountry,
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              isEmpty: country == null,
              decoration: InputDecoration(
                labelText: 'Issuing country',
                errorText: _errors[CardField.country],
                suffixIcon: const Icon(Icons.expand_more, color: AppColors.muted),
              ),
              child: country == null
                  ? null
                  : Text('${country.flag}  ${country.name}',
                      style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Checking' : 'Validate and save'),
          ),
        ],
      ),
    );
  }
}
