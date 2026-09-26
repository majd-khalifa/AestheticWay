import 'package:dio/dio.dart';
import '../auth/guest_auth_guard.dart';
import '../auth/token_storage.dart';
import '../localization/app_locale.dart';
import 'api_config.dart';

/// Interceptor that handles:
/// 1. Automatic trailing slash enforcement
/// 2. Header negotiation (Accept-Language, Content-Type)
/// 3. JWT Bearer token attachment
/// 4. Transparent token refresh on 401 Unauthorized
class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage = TokenStorage();

  AuthInterceptor(this._dio);

  static const List<String> _publicEndpoints = [
    ApiConfig.register,
    ApiConfig.login,
    ApiConfig.verifyOtp,
    ApiConfig.resendOtp,
    ApiConfig.forgotPassword,
    ApiConfig.resetPassword,
    ApiConfig.refresh,
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Ensure Trailing Slash
    try {
      final uri = Uri.parse(options.path);
      if (!uri.path.endsWith('/')) {
        final newPath = '${uri.path}/';
        options.path = uri.replace(path: newPath).toString();
      }
    } catch (_) {
      if (!options.path.endsWith('/')) {
        options.path = '${options.path}/';
      }
    }

    // 2. Set Standard Headers
    options.headers['Accept'] = 'application/json';
    if (options.data != null && options.headers['Content-Type'] == null) {
      options.headers['Content-Type'] = 'application/json';
    }

    // Dynamic Language Header
    options.headers['Accept-Language'] = LocaleService().currentLanguage.code;

    // 3. Attach Bearer Token if available and not a public auth endpoint
    final isPublic = _publicEndpoints.any((endpoint) => options.path.contains(endpoint));
    if (!isPublic) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final is401 = response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.contains(ApiConfig.refresh);
    final isLoginCall = err.requestOptions.path.contains(ApiConfig.login);

    if (is401 && !isRefreshCall && !isLoginCall) {
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Attempt refresh using a dedicated clean Dio instance to avoid interceptor recursion
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Accept-Language': LocaleService().currentLanguage.code,
              },
            ),
          );

          // Refresh body contract strictly requires "refresh": "<token>"
          final refreshResponse = await refreshDio.post(
            ApiConfig.refresh,
            data: {'refresh': refreshToken},
          );

          if (refreshResponse.statusCode == 200 && refreshResponse.data is Map<String, dynamic>) {
            final data = refreshResponse.data as Map<String, dynamic>;
            final newAccessToken = data['access_token']?.toString() ?? data['access']?.toString();
            final newRefreshToken = data['refresh_token']?.toString() ?? data['refresh']?.toString() ?? refreshToken;

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await _tokenStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Retry original request with new token
              final retryOptions = err.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await _dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          // Refresh failed - token is expired or revoked
          await _tokenStorage.clear();
          AuthState().logout();
        }
      } else {
        // No refresh token available
        await _tokenStorage.clear();
        AuthState().logout();
      }
    }

    return handler.next(err);
  }
}
