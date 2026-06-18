/// Result of executing a test script
class ScriptResult {
  final bool passed;
  final String? errorMessage;
  final List<String> testResults;
  final Map<String, String> variables;

  const ScriptResult({
    required this.passed,
    this.errorMessage,
    this.testResults = const [],
    this.variables = const {},
  });
}

/// Lightweight script engine for Pre-request and Tests scripts
class ScriptEngine {
  /// Execute a test script after receiving the response
  Future<ScriptResult> executeTestScript({
    required String script,
    required int statusCode,
    required Map<String, String> responseHeaders,
    required String responseBody,
    required Map<String, String> environmentVars,
  }) async {
    if (script.trim().isEmpty) {
      return const ScriptResult(passed: true);
    }

    final errors = <String>[];
    final testResults = <String>[];
    final newVariables = <String, String>{};

    final lines = script.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('//')) continue;

      if (trimmed.contains('pm.test')) {
        final testName = _extractBetween(trimmed, 'pm.test("', '"');
        final result = _evaluateAssertion(trimmed, statusCode, responseBody);
        if (result != null) {
          testResults.add('$testName: $result');
          errors.add('$testName: $result');
        } else {
          testResults.add('$testName: PASS');
        }
      }

      if (trimmed.contains('pm.environment.set')) {
        final key = _extractBetween(trimmed, 'pm.environment.set("', '"');
        final value = _extractAfter(trimmed, 'pm.environment.set("$key", "');
        if (key.isNotEmpty) {
          newVariables[key] = value;
        }
      }
    }

    return ScriptResult(
      passed: errors.isEmpty,
      errorMessage: errors.isEmpty ? null : errors.join('\n'),
      testResults: testResults,
      variables: newVariables,
    );
  }

  String _extractBetween(String source, String start, String end) {
    final startIdx = source.indexOf(start);
    if (startIdx == -1) return '';
    final from = startIdx + start.length;
    final endIdx = source.indexOf(end, from);
    if (endIdx == -1) return source.substring(from);
    return source.substring(from, endIdx);
  }

  String _extractAfter(String source, String marker) {
    final idx = source.indexOf(marker);
    if (idx == -1) return '';
    final from = idx + marker.length;
    final endIdx = source.indexOf('"', from);
    if (endIdx == -1) return source.substring(from);
    return source.substring(from, endIdx);
  }

  String? _evaluateAssertion(String line, int statusCode, String responseBody) {
    // pm.expect(pm.response.code).to.eql(200)
    if (line.contains('pm.response.code') && line.contains('.to.eql(')) {
      final val = _extractBetween(line, '.to.eql(', ')');
      final expected = int.tryParse(val);
      if (expected != null && statusCode != expected) {
        return 'FAIL: expected status $expected, got $statusCode';
      }
      return null;
    }

    // pm.expect(pm.response.code).to.equal(200)
    if (line.contains('pm.response.code') && line.contains('.to.equal(')) {
      final val = _extractBetween(line, '.to.equal(', ')');
      final expected = int.tryParse(val);
      if (expected != null && statusCode != expected) {
        return 'FAIL: expected status $expected, got $statusCode';
      }
      return null;
    }

    // pm.expect(pm.response.text()).to.include("text")
    if (line.contains('pm.response.text()') && line.contains('.to.include(')) {
      final expected = _extractBetween(line, '.to.include("', '"');
      if (expected.isNotEmpty && !responseBody.contains(expected)) {
        return 'FAIL: response does not contain "$expected"';
      }
      return null;
    }

    // pm.expect(pm.response.text()).to.contain("text")
    if (line.contains('pm.response.text()') && line.contains('.to.contain(')) {
      final expected = _extractBetween(line, '.to.contain("', '"');
      if (expected.isNotEmpty && !responseBody.contains(expected)) {
        return 'FAIL: response does not contain "$expected"';
      }
      return null;
    }

    // pm.expect(pm.response.json()).to.have.property("key")
    if (line.contains('pm.response.json()') && line.contains('.to.have.property(')) {
      final prop = _extractBetween(line, '.to.have.property("', '"');
      if (prop.isNotEmpty && !responseBody.contains('"$prop"')) {
        return 'FAIL: response JSON missing property "$prop"';
      }
      return null;
    }

    // pm.expect(pm.response.code).to.not.eql(404)
    if (line.contains('pm.response.code') && line.contains('.to.not.eql(')) {
      final val = _extractBetween(line, '.to.not.eql(', ')');
      final notExpected = int.tryParse(val);
      if (notExpected != null && statusCode == notExpected) {
        return 'FAIL: expected status to not be $notExpected';
      }
      return null;
    }

    return null;
  }
}

class ScriptException implements Exception {
  final String message;
  ScriptException(this.message);

  @override
  String toString() => message;
}
