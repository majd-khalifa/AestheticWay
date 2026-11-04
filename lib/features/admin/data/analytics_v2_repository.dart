import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/analytics/analytics_ids.dart' show isAnalyticsUuid;
import '../models/analytics_v2.dart';

class AnalyticsV2Repository {
  AnalyticsV2Repository({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;
  static const clinicsPath = 'admin/analytics/clinics/';

  void _authorize() {
    if (!AuthState().isLoggedIn || !AuthState().isSuperAdmin) {
      throw ApiException(
        message: LocaleService().isArabic
            ? 'يتطلب الوصول حساب مشرف عام.'
            : 'Super Admin access is required.',
        statusCode: 403,
      );
    }
  }

  Future<T> _fetch<T>(
    String path,
    AnalyticsV2Query query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    _authorize();
    final session = SessionSnapshot();
    final response = await _client.get<Object?>(
      path,
      queryParameters: query.parameters,
    );
    session.ensureCurrent();
    _authorize();
    try {
      if (response.statusCode != 200 ||
          response.data is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return parse(response.data as Map<String, dynamic>);
    } on FormatException {
      throw _contractError();
    } on TypeError {
      throw _contractError();
    }
  }

  ApiException _contractError() => ApiException(
    message: LocaleService().isArabic
        ? 'لم يؤكد الخادم مخطط V2 أو فترة التقرير. حدّث البيانات قبل استخدام الأرقام.'
        : 'The server did not confirm the V2 schema or report window. Refresh before using these figures.',
  );

  Future<AnalyticsV2Page> clinics(AnalyticsV2Query query) => _fetch(
    clinicsPath,
    query,
    (json) => AnalyticsV2Page.fromJson(json, query),
  );

  Future<AnalyticsV2Detail> detail(String clinicId, AnalyticsV2Query query) {
    if (!isAnalyticsUuid(clinicId)) {
      throw const FormatException('Invalid clinic UUID');
    }
    return _fetch(
      'admin/clinics/$clinicId/analytics/',
      query,
      (json) => AnalyticsV2Detail.fromJson(json, query, clinicId),
    );
  }
}
