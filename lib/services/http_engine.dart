import 'dart:convert';
import 'package:dio/dio.dart';
import '../data/models/api_request.dart';
import '../data/models/api_response.dart';
import '../data/models/auth_config.dart';
import '../core/utils/variable_resolver.dart';

class HttpEngine {
  late final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

  HttpEngine() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 10),
      followRedirects: true,
      validateStatus: (_) => true, // Accept all status codes
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  /// Send an HTTP request and return the response.
  Future<ApiResponse> sendRequest(
    ApiRequest request, {
    CancelToken? cancelToken,
    Map<String, String>? environmentVariables,
  }) async {
    // Resolve variables in URL
    final variables = environmentVariables ?? {};
    final resolvedUrl = VariableResolver.resolve(request.url, variables);

    // Resolve headers
    final resolvedHeaders = VariableResolver.resolveMap(
      request.headers,
      variables,
    );

    // Inject auth headers
    if (request.auth != null && request.auth!.type != AuthType.none) {
      final auth = request.auth!;
      switch (auth.type) {
        case AuthType.bearer:
          resolvedHeaders['Authorization'] = 'Bearer ${auth.token}';
          break;
        case AuthType.basic:
          final credentials = '${auth.username}:${auth.password}';
          final encoded = base64Encode(utf8.encode(credentials));
          resolvedHeaders['Authorization'] = 'Basic $encoded';
          break;
        case AuthType.apiKey:
          resolvedHeaders[auth.apiKeyHeader] = auth.apiKey;
          break;
        case AuthType.none:
          break;
      }
    }

    // Build query parameters
    final queryParams = <String, dynamic>{};
    for (final entry in request.queryParams.entries) {
      if (entry.value.isNotEmpty) {
        queryParams[entry.key] = entry.value;
      }
    }

    // Build request body
    dynamic data;
    if (request.body != null) {
      if (request.body!.type.name == 'json') {
        if (request.body!.jsonContent.isNotEmpty) {
          data = request.body!.jsonContent;
        }
      } else if (request.body!.type.name == 'formData') {
        final formData = FormData();
        for (final field in request.body!.formFields) {
          if (field.enabled && field.key.isNotEmpty) {
            formData.fields.add(MapEntry(field.key, field.value));
          }
        }
        data = formData;
      }
    }

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.request(
        resolvedUrl,
        data: data,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          method: request.method,
          headers: resolvedHeaders,
          contentType: request.body?.type.name == 'json'
              ? 'application/json'
              : null,
        ),
        cancelToken: cancelToken,
      );

      stopwatch.stop();

      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      final body = response.data?.toString() ?? '';

      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        headers: responseHeaders,
        body: body,
        durationMs: stopwatch.elapsedMilliseconds,
        bodySize: body.length,
      );
    } on DioException catch (e) {
      stopwatch.stop();

      if (e.type == DioExceptionType.cancel) {
        return ApiResponse(
          statusCode: 0,
          body: 'Request cancelled',
          durationMs: stopwatch.elapsedMilliseconds,
          statusText: 'Cancelled',
        );
      }

      return ApiResponse(
        statusCode: e.response?.statusCode ?? 0,
        headers: _extractHeaders(e.response?.headers),
        body: e.response?.data?.toString() ?? e.message ?? 'Unknown error',
        durationMs: stopwatch.elapsedMilliseconds,
        statusText: e.type.name,
      );
    }
  }

  CancelToken createCancelToken(String requestId) {
    final token = CancelToken();
    _cancelTokens[requestId] = token;
    return token;
  }

  void cancelRequest(String requestId) {
    _cancelTokens[requestId]?.cancel('User cancelled');
    _cancelTokens.remove(requestId);
  }

  Map<String, String> _extractHeaders(Headers? headers) {
    final result = <String, String>{};
    headers?.forEach((name, values) {
      result[name] = values.join(', ');
    });
    return result;
  }
}
