import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  /// Backwards-compatible: returns the first detected medicine name (if any).
  static Future<String> processImage(XFile image) async {
    final meds = await processImageMedicines(image);
    return meds.isNotEmpty ? meds.first : '';
  }

  /// Extracts a list of candidate medicine names from a prescription image.
  static Future<List<String>> processImageMedicines(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return _extractMedicineNames(recognizedText.text);
    } catch (e) {
      print('Error during OCR scanning: $e');
      return const <String>[];
    } finally {
      textRecognizer.close();
    }
  }

  static List<String> _extractMedicineNames(String rawText, {bool useHeaderHeuristic = true}) {
    if (rawText.trim().isEmpty) return const <String>[];

    final noisePhrases = <String>{
      'patient prescription',
      'drug name',
      'number of units',
      'number of times',
      'number of days',
      'doctors signature',
    };

    final noiseWords = <String>{
      'dr', 'doctor', 'patient', 'name', 'age', 'sex', 'male', 'female',
      'date', 'signature', 'clinic', 'hospital', 'rx',
      'tablet', 'capsule', 'syrup', 'daily', 'times', 'day', 'address', 'tel',
      'phone', 'email', 'prescription', 'dispense', 'refill', 'mr', 'mrs', 'ms',
      'once', 'twice', 'thrice', 'morning', 'night', 'no', 'box', 'p', 'o',
    };

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Heuristic: if we see a "Drug Name" header, prioritize subsequent lines.
    int startIdx = 0;
    if (useHeaderHeuristic) {
      for (int i = 0; i < lines.length; i++) {
        final lower = lines[i].toLowerCase();
        if (lower.contains('drug name')) {
          startIdx = i + 1;
          break;
        }
      }
    }

    final candidates = <String>[];
    final seen = <String>{};

    for (int i = startIdx; i < lines.length; i++) {
      final original = lines[i];
      final lower = original.toLowerCase();

      if (noisePhrases.any(lower.contains)) continue;

      // Remove punctuation but keep spaces.
      var clean = original.replaceAll(RegExp(r'[^\w\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (clean.isEmpty) continue;

      // Skip lines that are mostly numbers.
      final noSpaces = clean.replaceAll(' ', '');
      if (noSpaces.isNotEmpty && num.tryParse(noSpaces) != null) continue;

      // Strip dosage/units like "10.0gm", "500 mg", etc.
      clean = clean.replaceAll(RegExp(r'\b\d+(\.\d+)?\s*(mg|ml|g|gm|mcg)\b', caseSensitive: false), '').trim();
      if (clean.isEmpty) continue;

      // Extract a name-like prefix: words until we hit a number.
      final parts = clean.split(' ');
      final nameParts = <String>[];
      for (final p in parts) {
        if (p.isEmpty) continue;
        if (num.tryParse(p) != null) break;
        final pl = p.toLowerCase();
        if (noiseWords.contains(pl)) continue;
        if (p.length < 3) continue;
        nameParts.add(p);
      }

      if (nameParts.isEmpty) continue;

      // Many prescriptions have single-word drug names; keep max 3 words for safety.
      final name = nameParts.take(3).join(' ').trim();
      if (name.length < 3) continue;

      final key = name.toLowerCase();
      if (seen.add(key)) candidates.add(name);

      // Stop if we already found a reasonable amount.
      if (candidates.length >= 10) break;
    }

    // Fallback: if header heuristic failed, scan all lines (without recursion loops).
    if (candidates.isEmpty && useHeaderHeuristic && startIdx > 0) {
      return _extractMedicineNames(rawText, useHeaderHeuristic: false);
    }

    return candidates;
  }
}
