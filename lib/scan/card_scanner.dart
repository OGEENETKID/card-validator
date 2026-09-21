import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../core/card_number_parser.dart';
import '../models/card_brand.dart';

/// What a scan produced.
class ScanResult {
  const ScanResult({
    required this.number,
    required this.brand,
    this.expiry,
    this.securityCode,
    this.checksumPassed = false,
  });

  final String number;
  final CardBrand brand;
  final String? expiry;

  /// Only some cards print the code on the front.
  final String? securityCode;

  /// False when the digits read as a card number but fail validation.
  final bool checksumPassed;
}

class ScanException implements Exception {
  const ScanException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Captures a card image and reads the number off it. The text handling
/// lives in [CardNumberParser].
class CardScanner {
  CardScanner({ImagePicker? picker, TextRecognizer? recognizer})
      : _picker = picker ?? ImagePicker(),
        _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final ImagePicker _picker;
  final TextRecognizer _recognizer;

  /// Returns null if the camera is dismissed.
  Future<ScanResult?> scan({ImageSource source = ImageSource.camera}) async {
    final XFile? image;
    try {
      image = await _picker.pickImage(
        source: source,
        // Enough resolution for the digits without slowing the recogniser.
        maxWidth: 1920,
        imageQuality: 90,
      );
    } on Exception {
      throw const ScanException('Camera unavailable. Check the app\'s permissions.');
    }

    if (image == null) return null;

    final RecognizedText recognised;
    try {
      recognised = await _recognizer.processImage(InputImage.fromFilePath(image.path));
    } on Exception {
      throw const ScanException('Could not read that image. Try again in better light.');
    }

    final lines = <String>[
      for (final block in recognised.blocks)
        for (final line in block.lines) line.text,
    ];

    final candidate = CardNumberParser.best(lines);
    if (candidate == null) {
      throw const ScanException(
        'No card number found. Fill the frame with the card and hold it steady.',
      );
    }

    return ScanResult(
      number: candidate.digits,
      brand: candidate.brand,
      expiry: CardNumberParser.expiry(lines),
      securityCode: CardNumberParser.securityCode(lines),
      checksumPassed: candidate.checksumValid,
    );
  }

  void dispose() => _recognizer.close();
}
