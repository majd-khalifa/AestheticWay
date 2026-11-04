import 'package:flutter/foundation.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_exception.dart';
import '../data/analytics_v2_repository.dart';
import '../models/analytics_v2.dart';

class AnalyticsV2Controller extends ChangeNotifier {
  AnalyticsV2Controller({
    AnalyticsV2Repository? repository,
    AnalyticsV2Query? initialQuery,
  }) : _repository = repository ?? AnalyticsV2Repository(),
       query = initialQuery ?? AnalyticsV2Query.initial() {
    _owner = SessionSnapshot();
    AuthState().addListener(_identityChanged);
  }
  final AnalyticsV2Repository _repository;
  AnalyticsV2Query query;
  AnalyticsV2Page? page;
  AnalyticsV2Detail? detail;
  String? selectedId, error, detailError;
  bool loading = false, detailLoading = false;
  int _revision = 0, _detailRevision = 0;
  bool _disposed = false;
  late SessionSnapshot _owner;
  bool get authorized => AuthState().isLoggedIn && AuthState().isSuperAdmin;

  String _message(Object e) => e is ApiException
      ? e.message
      : (LocaleService().isArabic
            ? 'تعذر تحميل تقرير V2. يرجى المحاولة مجدداً.'
            : 'Unable to load the V2 report. Please try again.');

  void _identityChanged() {
    if (!_owner.isCurrent || !authorized) {
      _revision++;
      _detailRevision++;
      page = null;
      detail = null;
      selectedId = null;
      error = null;
      detailError = null;
      loading = false;
      detailLoading = false;
      _owner = SessionSnapshot();
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> load({AnalyticsV2Query? filters}) async {
    if (!authorized || _disposed || (loading && filters == null)) return;
    final revision = ++_revision;
    final session = SessionSnapshot();
    _owner = session;
    _detailRevision++;
    query = filters ?? query;
    page = null;
    detail = null;
    selectedId = null;
    error = null;
    detailError = null;
    loading = true;
    detailLoading = false;
    notifyListeners();
    try {
      final result = await _repository.clinics(query);
      if (!_disposed &&
          session.isCurrent &&
          authorized &&
          revision == _revision) {
        page = result;
      }
    } catch (e) {
      if (!_disposed &&
          session.isCurrent &&
          authorized &&
          revision == _revision) {
        error = _message(e);
      }
    } finally {
      if (!_disposed && session.isCurrent && revision == _revision) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> select(
    String clinicId, {
    int seriesPage = 1,
    bool? compare,
  }) async {
    if (!authorized ||
        _disposed ||
        page == null ||
        (detailLoading && selectedId == clinicId)) {
      return;
    }
    if (!page!.clinics.any((c) => c.id == clinicId)) return;
    final revision = ++_detailRevision;
    final session = SessionSnapshot();
    selectedId = clinicId;
    detail = null;
    detailError = null;
    detailLoading = true;
    final filters = query.copyWith(seriesPage: seriesPage, compare: compare);
    notifyListeners();
    try {
      final result = await _repository.detail(clinicId, filters);
      if (!_disposed &&
          session.isCurrent &&
          authorized &&
          revision == _detailRevision) {
        detail = result;
      }
    } catch (e) {
      if (!_disposed &&
          session.isCurrent &&
          authorized &&
          revision == _detailRevision) {
        detailError = _message(e);
      }
    } finally {
      if (!_disposed && session.isCurrent && revision == _detailRevision) {
        detailLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _detailRevision++;
    AuthState().removeListener(_identityChanged);
    super.dispose();
  }
}
