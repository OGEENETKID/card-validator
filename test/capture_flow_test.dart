import 'package:card_validator/main.dart';
import 'package:card_validator/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End to end through the real screens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> start(WidgetTester tester) async {
    final state = AppState();
    await state.load();
    await tester.pumpWidget(CardValidatorApp(state: state));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    required String number,
    required String expiry,
    required String cvv,
    required String country,
  }) async {
    await tester.tap(find.text('Add card'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), number);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), expiry);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(2), cvv);
    await tester.pump();

    await tester.tap(find.text('Issuing country'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, country);
    await tester.pumpAndSettle();
    // The search box holds the same string, so scope the finder.
    await tester.tap(find.widgetWithText(ListTile, country));
    await tester.pumpAndSettle();
  }

  testWidgets('captures a valid card and lists it', (tester) async {
    await start(tester);
    expect(find.text('No cards captured yet'), findsOneWidget);

    await fillForm(tester, number: '4574487405351567', expiry: '1229', cvv: '123', country: 'South Africa');

    expect(find.text('Inferred from the number'), findsOneWidget);

    await tester.tap(find.text('Validate and save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1567'), findsOneWidget);
    expect(find.textContaining('exp 12/29'), findsOneWidget);
    expect(find.text('No cards captured yet'), findsNothing);
    // Only the last four digits are ever shown.
    expect(find.textContaining('4574 4874'), findsNothing);
  });

  testWidgets('opens a saved card and shows the full details', (tester) async {
    await start(tester);
    await fillForm(tester,
        number: '4574487405351567', expiry: '1229', cvv: '123', country: 'South Africa');
    await tester.tap(find.text('Validate and save'));
    await tester.pumpAndSettle();

    // The list masks the number; the detail screen shows it in full.
    await tester.tap(find.textContaining('1567'));
    await tester.pumpAndSettle();

    expect(find.text('4574 4874 0535 1567'), findsOneWidget);
    expect(find.text('12/29'), findsOneWidget);
    expect(find.textContaining('South Africa'), findsWidgets);

    // The security code stays hidden until it is asked for.
    expect(find.text('123'), findsNothing);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('deletes a card from the detail screen', (tester) async {
    await start(tester);
    await fillForm(tester,
        number: '4574487405351567', expiry: '1229', cvv: '123', country: 'South Africa');
    await tester.tap(find.text('Validate and save'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('1567'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete this card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('No cards captured yet'), findsOneWidget);
  });

  testWidgets('refuses the same card twice', (tester) async {
    await start(tester);

    await fillForm(tester, number: '4574487405351567', expiry: '1229', cvv: '123', country: 'South Africa');
    await tester.tap(find.text('Validate and save'));
    await tester.pumpAndSettle();

    // Clear the snackbar so it cannot swallow the next tap.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await fillForm(tester, number: '4574487405351567', expiry: '1229', cvv: '123', country: 'South Africa');
    await tester.tap(find.text('Validate and save'));
    await tester.pumpAndSettle();

    expect(find.text('This card has already been captured.'), findsWidgets);
  });

  testWidgets('refuses a card from a banned country', (tester) async {
    await start(tester);

    await fillForm(tester, number: '4574487405351567', expiry: '1229', cvv: '123', country: 'Iran');
    await tester.tap(find.text('Validate and save'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cards issued in this country cannot be accepted.'),
      findsWidgets,
    );
  });
}
