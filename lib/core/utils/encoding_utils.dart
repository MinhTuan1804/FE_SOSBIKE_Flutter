import 'dart:convert';

class EncodingUtils {
  /// Fixes Vietnamese encoding issues (e.g., Unicode escape sequences and double UTF-8 encoding).
  static String fixVietnameseEncoding(String input) {
    if (input.isEmpty) return input;
    try {
      // 1. Fix raw unicode escape sequences (e.g. \u00e3 or \u00fa)
      var result = input.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
        final hex = match.group(1)!;
        final code = int.parse(hex, radix: 16);
        return String.fromCharCode(code);
      });

      // 2. Fix double UTF-8 encoding (UTF-8 bytes decoded as Latin-1/ISO-8859-1)
      if (result.contains('Ã') || result.contains('Â') || result.contains('Æ') || result.contains('ï¿½')) {
        try {
          final bytes = result.codeUnits;
          final decoded = utf8.decode(bytes, allowMalformed: false);
          return decoded;
        } catch (_) {
          try {
            final bytes = latin1.encode(result);
            final decoded = utf8.decode(bytes, allowMalformed: false);
            return decoded;
          } catch (_) {}
        }
      }
      return result;
    } catch (_) {
      return input;
    }
  }
}
