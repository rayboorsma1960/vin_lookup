import 'package:logging/logging.dart';

class VinValidator {
  static final _log = Logger('VinValidator');
  static const _validCharacters = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789';
  static const _weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];
  static const _transliterationMap = {
    'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8,
    'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'P': 7, 'R': 9,
    'S': 2, 'T': 3, 'U': 4, 'V': 5, 'W': 6, 'X': 7, 'Y': 8, 'Z': 9,
  };

  static bool isValid(String vin) {
    if (vin.length != 17) return false;
    vin = vin.toUpperCase();
    if (vin.contains(RegExp(r'[IOQ]'))) return false;
    if (!vin.contains(RegExp(r'^[A-HJ-NPR-Z0-9]{17}$'))) return false;

    // Check digit calculation
    int sum = 0;
    for (int i = 0; i < 17; i++) {
      int value = _transliterationMap[vin[i]] ?? int.parse(vin[i]);
      sum += value * _weights[i];
    }
    int checkDigit = sum % 11;
    String expectedCheckDigit = checkDigit == 10 ? 'X' : checkDigit.toString();

    return vin[8] == expectedCheckDigit;
  }

  static String? suggestCorrection(String input) {
    //_Log.info('Attempting to suggest correction for: $input');
    if (input.length != 17) {
      //_Log.warning('Input length is not 17, cannot suggest correction');
      return null;
    }

    String suggestion = input.toUpperCase();

    // Replace I, O, Q with similar looking valid characters
    suggestion = suggestion.replaceAll('I', '1');
    suggestion = suggestion.replaceAll('O', '0');
    suggestion = suggestion.replaceAll('Q', '9');

    // Replace any other invalid characters with a placeholder
    for (int i = 0; i < suggestion.length; i++) {
      if (!_validCharacters.contains(suggestion[i])) {
        suggestion = suggestion.replaceRange(i, i + 1, 'X');
      }
    }

    if (isValid(suggestion)) {
      //_Log.info('Suggested correction: $suggestion');
      return suggestion;
    }

    //_Log.warning('Unable to suggest a valid correction');
    return null;
  }
}