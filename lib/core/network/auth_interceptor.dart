import 'package:dio/dio.dart';
import '../auth/guest_auth_guard.dart';
import '../auth/token_storage.dart';
import '../localization/app_locale.dart';
import 'api_config.dart';

/// A single refresh Future is shared by all requests for the same session.
/// Retries leave the refresh critical section before re-entering Dio.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, {Dio? refreshDio, TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      _refreshDio =
          refreshDio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            ),
          );
  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  Future<String>? _refreshFlight;
  static const _retried = 'aw_auth_retried';
  static const _session = 'aw_auth_session';
  static const _publicEndpoints = [
    ApiConfig.register,
    ApiConfig.login,
    ApiConfig.verifyOtp,
    ApiConfig.resendOtp,
    ApiConfig.forgotPassword,
    ApiConfig.resetPassword,
    ApiConfig.refresh,
  ];
  bool _isPublic(String path) => _publicEndpoints.any(
    (endpoint) => Uri.parse(path).path.endsWith(endpoint),
  );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final uri = Uri.parse(options.path);
      if (!uri.path.endsWith('/')) {
        options.path = uri.replace(path: '${uri.path}/').toString();
      }
      options.headers['Accept'] = 'application/json';
      options.headers['Accept-Language'] = LocaleService().currentLanguage.code;
      if (options.data is FormData) {
        options.headers.remove('Content-Type');
        options.contentType = null;
      } else if (options.data != null) {
        options.contentType ??= Headers.jsonContentType;
      }
      if (!_isPublic(options.path)) {
        final token = await _tokenStorage.getAccessToken();
        options.extra[_session] = _tokenStorage.sessionEpoch;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      handler.next(options);
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  Future<String> _refresh() async {
    final existing = _refreshFlight;
    if (existing != null) return existing;
    final flight = _refreshTokens();
    _refreshFlight = flight;
    try {
      return await flight;
    } finally {
      if (identical(_refreshFlight, flight)) _refreshFlight = null;
    }
  }

  Future<String> _refreshTokens() async {
    final epoch = _tokenStorage.sessionEpoch;
    final version = _tokenStorage.credentialVersion;
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiConfig.refresh),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: ApiConfig.refresh),
        ),
      );
    }
    final response = await _refreshDio.post(
      ApiConfig.refresh,
      data: {'refresh': refresh},
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Accept-Language': LocaleService().currentLanguage.code,
        },
        contentType: Headers.jsonContentType,
      ),
    );
    if (epoch != _tokenStorage.sessionEpoch ||
        version != _tokenStorage.credentialVersion) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.cancel,
        error: 'Session changed while refreshing credentials.',
      );
    }
    final data = response.data;
    final token = data is Map
        ? (data['access_token'] ?? data['access'])?.toString()
        : null;
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Refresh response is missing the access token.',
      );
    }
    final nextRefresh = (data['refresh_token'] ?? data['refresh'] ?? refresh)
        .toString();
    await _tokenStorage.saveTokens(
      accessToken: token,
      refreshToken: nextRefresh,
    );
    if (epoch != _tokenStorage.sessionEpoch) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.cancel,
      );
    }
    return token;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final error = err;
    final request = error.requestOptions;
    final epoch = request.extra[_session];
    if (error.response?.statusCode != 401 ||
        _isPublic(request.path) ||
        request.extra[_retried] == true ||
        epoch != _tokenStorage.sessionEpoch) {
      handler.next(error);
      return;
    }
    String token;
    try {
      final current = await _tokenStorage.getAccessToken();
      final sent = request.headers['Authorization'];
      // A late 401 may refer to credentials that another request already refreshed.
      token = current != null && 'Bearer $current' != sent
          ? current
          : await _refresh();
    } catch (refreshError) {
      if (epoch == _tokenStorage.sessionEpoch &&
          refreshError is DioException &&
          (refreshError.response?.statusCode == 401 ||
              refreshError.response?.statusCode == 403)) {
        await _tokenStorage.clear();
        AuthState().logout();
      }
      handler.next(error);
      return;
    }
    if (epoch != _tokenStorage.sessionEpoch ||
        request.cancelToken?.isCancelled == true) {
      handler.next(error);
      return;
    }
    final retry = request.copyWith(
      headers: {...request.headers, 'Authorization': 'Bearer $token'},
      extra: {...request.extra, _retried: true},
      data: request.data is FormData
          ? (request.data as FormData).clone()
          : request.data,
    );
    try {
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (retryError) {
      // A validation/server error after refresh must not log out the user.
      handler.next(retryError);
    } catch (_) {
      handler.next(error);
    }
  }
}
