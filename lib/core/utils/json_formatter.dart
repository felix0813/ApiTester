import 'dart:convert';

class JsonFormatter {
  /// Try to pretty-print a JSON string.
  /// Returns the formatted string or the original if not valid JSON.
  static String prettyPrint(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  /// Check if a string is valid JSON.
  static bool isValid(String raw) {
    try {
      jsonDecode(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Minify a JSON string — remove all unnecessary whitespace.
  static String minify(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return jsonEncode(decoded);
    } catch (_) {
      return raw;
    }
  }
}
