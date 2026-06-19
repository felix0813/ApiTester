import 'dart:async';
import '../data/models/api_request.dart';
import '../data/models/api_response.dart';
import 'http_engine.dart';
import 'script_engine.dart';

class RunnerRequestResult {
  final ApiRequest request;
  final ApiResponse? response;
  final ScriptResult? scriptResult;
  final String? error;
  final Duration duration;

  const RunnerRequestResult({
    required this.request,
    this.response,
    this.scriptResult,
    this.error,
    required this.duration,
  });

  bool get passed => error == null && (scriptResult?.passed ?? true);
}

class RunnerResult {
  final String collectionName;
  final List<RunnerRequestResult> results;
  final Duration totalDuration;

  const RunnerResult({
    required this.collectionName,
    required this.results,
    required this.totalDuration,
  });

  int get passCount => results.where((r) => r.passed).length;
  int get failCount => results.length - passCount;
  bool get allPassed => failCount == 0;
}

typedef RunnerProgressCallback = void Function(int current, int total, RunnerRequestResult result);

class RunnerEngine {
  final HttpEngine _httpEngine;
  final ScriptEngine _scriptEngine;

  RunnerEngine({
    HttpEngine? httpEngine,
    ScriptEngine? scriptEngine,
  })  : _httpEngine = httpEngine ?? HttpEngine(),
        _scriptEngine = scriptEngine ?? ScriptEngine();

  Future<RunnerResult> runRequests({
    required String collectionName,
    required List<ApiRequest> requests,
    Map<String, String>? environmentVariables,
    RunnerProgressCallback? onProgress,
  }) async {
    final results = <RunnerRequestResult>[];
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < requests.length; i++) {
      final request = requests[i];
      final requestStopwatch = Stopwatch()..start();

      try {
        final response = await _httpEngine.sendRequest(
          request,
          environmentVariables: environmentVariables,
        );

        ScriptResult? scriptResult;
        if (request.testsScript.isNotEmpty) {
          scriptResult = await _scriptEngine.executeTestScript(
            script: request.testsScript,
            statusCode: response.statusCode,
            responseHeaders: response.headers,
            responseBody: response.body,
            environmentVars: environmentVariables ?? {},
          );
        }

        requestStopwatch.stop();

        final result = RunnerRequestResult(
          request: request,
          response: response,
          scriptResult: scriptResult,
          duration: requestStopwatch.elapsed,
        );
        results.add(result);

        onProgress?.call(i + 1, requests.length, result);
      } catch (e) {
        requestStopwatch.stop();

        final result = RunnerRequestResult(
          request: request,
          error: e.toString(),
          duration: requestStopwatch.elapsed,
        );
        results.add(result);

        onProgress?.call(i + 1, requests.length, result);
      }
    }

    stopwatch.stop();

    return RunnerResult(
      collectionName: collectionName,
      results: results,
      totalDuration: stopwatch.elapsed,
    );
  }
}
