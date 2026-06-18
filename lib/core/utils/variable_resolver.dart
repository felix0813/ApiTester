/// Resolves `{{variable}}` placeholders in a string against a variables map.
class VariableResolver {
  /// Replace all {{key}} occurrences in [input] with values from [variables].
  /// Returns the resolved string. Unknown keys are left unchanged.
  static String resolve(String input, Map<String, String> variables) {
    if (input.isEmpty || variables.isEmpty) return input;
    final pattern = RegExp(r'\{\{(\w+)\}\}');
    return input.replaceAllMapped(pattern, (match) {
      final key = match.group(1)!;
      return variables[key] ?? match.group(0)!;
    });
  }

  /// Resolve all values in a map recursively (shallow — values only, not keys).
  static Map<String, String> resolveMap(
    Map<String, String> map,
    Map<String, String> variables,
  ) {
    return map.map((key, value) => MapEntry(key, resolve(value, variables)));
  }
}
