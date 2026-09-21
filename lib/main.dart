import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'ui/screens/cards_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardValidatorApp());
}

class CardValidatorApp extends StatefulWidget {
  const CardValidatorApp({super.key, this.state});

  /// Injectable for tests.
  final AppState? state;

  @override
  State<CardValidatorApp> createState() => _CardValidatorAppState();
}

class _CardValidatorAppState extends State<CardValidatorApp> {
  late final AppState _state = widget.state ?? AppState();

  @override
  void initState() {
    super.initState();
    // Read storage once so no screen carries its own loading state.
    if (!_state.isReady) _state.load();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'Card Validator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const CardsScreen(),
      ),
    );
  }
}
