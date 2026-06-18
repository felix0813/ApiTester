import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/api_request.dart';
import '../../data/models/api_response.dart';
import '../../data/repositories/request_repository_impl.dart';
import '../../domain/repositories/request_repository.dart';
import '../../data/models/history_entry.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/history_repository.dart';
import '../../services/http_engine.dart';

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepositoryImpl();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl();
});

// Current request being edited
class CurrentRequestNotifier extends StateNotifier<ApiRequest> {
  CurrentRequestNotifier() : super(ApiRequest());

  void updateRequest(ApiRequest Function(ApiRequest) updater) {
    state = updater(state);
  }

  void loadRequest(ApiRequest request) {
    state = request;
  }

  void setMethod(String method) {
    state = state.copyWith(method: method);
  }

  void setUrl(String url) {
    state = state.copyWith(url: url);
  }

  void reset() {
    state = ApiRequest();
  }
}

final currentRequestProvider =
    StateNotifierProvider<CurrentRequestNotifier, ApiRequest>((ref) {
  return CurrentRequestNotifier();
});

// Response state
class ResponseState {
  final ApiResponse? response;
  final bool isLoading;
  final String? error;

  const ResponseState({this.response, this.isLoading = false, this.error});

  ResponseState copyWith({
    ApiResponse? response,
    bool? isLoading,
    String? error,
    bool clearResponse = false,
    bool clearError = false,
  }) {
    return ResponseState(
      response: clearResponse ? null : (response ?? this.response),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ResponseNotifier extends StateNotifier<ResponseState> {
  final HttpEngine _httpEngine;
  final Ref _ref;

  ResponseNotifier(this._httpEngine, this._ref)
      : super(const ResponseState());

  Future<void> sendRequest(Map<String, String>? environmentVariables) async {
    final request = _ref.read(currentRequestProvider);

    if (request.url.isEmpty) {
      state = state.copyWith(error: 'Please enter a URL', clearResponse: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _httpEngine.sendRequest(
        request,
        environmentVariables: environmentVariables,
      );

      state = state.copyWith(
        response: response,
        isLoading: false,
        clearError: true,
      );

      final historyRepo = _ref.read(historyRepositoryProvider);
      await historyRepo.save(HistoryEntry(
        method: request.method,
        url: request.url,
        statusCode: response.statusCode,
        durationMs: response.durationMs,
        bodySize: response.bodySize,
      ));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearResponse: true,
      );
    }
  }

  void clearResponse() {
    state = const ResponseState();
  }
}

final responseProvider =
    StateNotifierProvider<ResponseNotifier, ResponseState>((ref) {
  final httpEngine = HttpEngine();
  return ResponseNotifier(httpEngine, ref);
});
