import '../auth/token_storage.dart';
import '../auth/guest_auth_guard.dart';
import '../data/single_flight.dart';
import '../localization/app_locale.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'request_backpressure.dart';

/// Centralized HTTP API Client powered by Dio
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _reads = SingleFlight();
  final _backpressure = RequestBackpressure();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    // Register Auth Interceptor
    dio.interceptors.add(AuthInterceptor(dio));
  }

  /// Update base URL dynamically (e.g. changing emulator vs real device IP)
  void updateBaseUrl(String newBaseUrl) {
    ApiConfig.setBaseUrl(newBaseUrl);
    dio.options.baseUrl = ApiConfig.baseUrl;
    _reads.clear();
    _backpressure.clear();
  }

  Options _sessionOptions(Options? options) {
    final value = options ?? Options();
    return value.copyWith(
      extra: {
        ...?value.extra,
        'aw_auth_session':
            value.extra?['aw_auth_session'] ?? TokenStorage().sessionEpoch,
      },
    );
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final stamped = _sessionOptions(options);
    // Unusual per-request Options may change decoding/headers/validation. Keep
    // those requests independent rather than guessing their equivalence.
    final key = options == null ? _readKey(path, queryParameters) : null;
    if (key == null) {
      return _send<T>(
        'GET',
        path,
        queryParameters: queryParameters,
        options: stamped,
      );
    }
    final response = await _reads.run(
      key,
      () => _send<dynamic>(
        'GET',
        path,
        queryParameters: queryParameters,
        options: stamped,
      ),
    );
    return Response<T>(
      data: response.data as T,
      requestOptions: response.requestOptions,
      headers: response.headers,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      isRedirect: response.isRedirect,
      redirects: response.redirects,
      extra: Map.of(response.extra),
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _send<T>(
      'POST',
      path,
      data: data,
      queryParameters: queryParameters,
      options: _sessionOptions(options),
    );
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _send<T>(
      'PATCH',
      path,
      data: data,
      queryParameters: queryParameters,
      options: _sessionOptions(options),
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _send<T>(
      'PUT',
      path,
      data: data,
      queryParameters: queryParameters,
      options: _sessionOptions(options),
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _send<T>(
      'DELETE',
      path,
      data: data,
      queryParameters: queryParameters,
      options: _sessionOptions(options),
    );
  }

  String _scope() =>
      '${dio.options.baseUrl}|${TokenStorage().sessionEpoch}|${AuthState().sessionEpoch}';

  String? _readKey(String path, Map<String, dynamic>? query) {
    Object? sorted(Object? value) {
      if (value is Map<String, dynamic>) {
        final keys = value.keys.toList()..sort();
        return {for (final key in keys) key: sorted(value[key])};
      }
      if (value is List) return value.map(sorted).toList();
      return value;
    }

    try {
      return jsonEncode([
        _scope(),
        LocaleService().currentLanguage.code,
        path,
        sorted(query),
        sorted(dio.options.headers),
      ]);
    } catch (_) {
      return null;
    }
  }

  Future<Response<T>> _send<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required Options options,
  }) async {
    final scope = _scope();
    _backpressure.check(scope);
    if (method != 'GET') _reads.clear();
    try {
      final response = await dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options.copyWith(method: method),
      );
      _backpressure.succeeded(scope);
      return response;
    } on DioException catch (error) {
      final mapped = ApiException.fromDioError(error);
      _backpressure.record(scope, mapped);
      throw mapped;
    } finally {
      // A GET started before/during a write must not service a post-write read.
      if (method != 'GET') _reads.clear();
    }
  }
}
