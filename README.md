# Card Validator

Flutter app for capturing credit card details and validating them before they get saved.
Built as a technical test for The Rank Group.

## Running it

```bash
flutter pub get
flutter test
flutter run
```

The repo only has the Dart code and config in it, so `flutter create` is needed once to
generate the `android/` and `ios/` folders. It won't touch `lib/`.

### Setup for the scanner

The card scanner uses the camera and ML Kit, so a few platform bits need adding after
`flutter create`:

**android/app/build.gradle.kts**

```kotlin
defaultConfig {
    minSdk = 21
}
```

(If your template made a Groovy `build.gradle` instead, it's `minSdkVersion 21`.)

**android/app/src/main/AndroidManifest.xml**, inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**ios/Runner/Info.plist**

```xml
<key>NSCameraUsageDescription</key>
<string>Used to read the number from a credit card.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to read a credit card from a saved photo.</string>
```

ML Kit needs iOS 15.5, so set `platform :ios, '15.5'` in the Podfile.

The scanner needs a real device since emulators don't have a camera. To try it without one,
change `ImageSource.camera` to `ImageSource.gallery` in `CardScanner.scan` and save one of the
sample card images to the device.

## What it does

- Captures card number, type, expiry date, security code and issuing country.
- Works out the card type from the number while you type it. You can override it, and if your
  override doesn't match the number the form tells you.
- Checks the issuing country against a banned list. The list and the reason for each country
  can be edited in the app and both are saved.
- Saves valid cards to local storage and lists them, newest first.
- Won't save the same card twice, no matter how it was formatted.
- Scans a card with the camera and fills in the number, type, expiry date, and the
  security code if the card prints it on the front.
- Checks the expiry date and won't save a card that has already expired.

## Structure

```
lib/
  core/     luhn check, card type detection, scan text parsing, validation rules
  data/     local storage, banned country config
  models/   card type, saved card, country list
  scan/     camera + OCR
  state/    AppState
  ui/       theme, screens, widgets
```

Everything in `core/` is plain Dart with no Flutter imports. That's deliberate, since it means
the rules can be tested quickly without a device and the form, the scanner and the tests all
run the same validation code.

## Packages

Kept it to three:

- `shared_preferences` for local storage
- `image_picker` for the camera
- `google_mlkit_text_recognition` for the OCR

The Luhn check, card type detection, number formatting, country list and the parsing of the
scanned text are all written here rather than pulled in. For state I used a `ChangeNotifier`
with an `InheritedNotifier`, which is enough for three screens and comes with Flutter.

## A few decisions

- **The security code is called different things.** Visa prints CVV2, Mastercard CVC2, Amex
  CID, UnionPay CVN2, and plenty of cards just say CVC. The field label changes to match the
  card type, and the scanner looks for all of those spellings when reading the front of a card.
  The length follows the scheme too, so Amex wants 4 digits and the rest want 3.
- **The expiry date and security code are both saved** with the card, as asked. Worth saying
  though: PCI-DSS doesn't allow keeping the security code after the card has been checked, so
  in a real system this would be validated and dropped, or never stored on the device at all.
  It's one field on `CreditCard` and one line in `toJson` if that needs changing.
- **The full card number is saved but never shown.** The duplicate check needs the whole
  number. The list only shows the last four digits, plus the expiry. In a real app this should
  be a token from the payment provider instead.
- **UnionPay skips the Luhn check** because its numbers don't have to pass it. The flag sits on
  the card type rather than in an if statement in the form.
- **Card type ranges overlap**, so the longest matching prefix wins. For example
  622126-622925 is Discover but sits inside UnionPay's 62.
- **The scanner reads line by line.** Cards often print the last four digits again under the
  main number, and reading the whole page as one string joins them into a 20 digit number.

## Tests

`flutter test` runs them. Most are plain Dart tests on the rules, plus one widget test that
goes through the whole capture flow. The sample card numbers are used as fixtures, including
two that fail the Luhn check, which makes them useful for the negative cases.

## Things I'd do next

- Pull the banned country list from a proper config service or compliance feed instead of an
  asset. `BannedCountryStore` is the only thing that would change.
- Encrypt what's stored. `shared_preferences` is plain text, so card data should really go in
  the Keychain/Keystore, or not be on the device at all.
- Add a retention period so saved cards don't sit there forever.
- Encrypt or drop the security code, for the PCI-DSS reason above.
- Live camera preview instead of taking a photo first.
