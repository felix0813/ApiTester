import 'dart:convert';
import '../../services/script_engine.dart';

class ApiResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final int durationMs;
  final int bodySize;
  final String statusText;
  final ScriptResult? scriptResult;

  ApiResponse({
    required this.statusCode,
    this.headers = const {},
    this.body = '',
    this.durationMs = 0,
    this.bodySize = 0,
    String? statusText,
    this.scriptResult,
  }) : statusText = statusText ?? _defaultStatusText(statusCode);

  String get prettyBody {
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return body;
    }
  }

  bool get isJson {
    try {
      jsonDecode(body);
      return true;
    } catch (_) {
      return false;
    }
  }

  String get formattedDuration {
    if (durationMs < 1000) return '${durationMs}ms';
    return '${(durationMs / 1000).toStringAsFixed(2)}s';
  }

  String get formattedSize {
    if (bodySize < 1024) return '${bodySize}B';
    if (bodySize < 1024 * 1024) {
      return '${(bodySize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(bodySize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  static String _defaultStatusText(int code) {
    switch (code) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 204: return 'No Content';
      case 301: return 'Moved Permanently';
      case 302: return 'Found';
      case 304: return 'Not Modified';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 405: return 'Method Not Allowed';
      case 429: return 'Too Many Requests';
      case 500: return 'Internal Server Error';
      case 502: return 'Bad Gateway';
      case 503: return 'Service Unavailable';
      default: return 'Unknown';
    }
  }
}
