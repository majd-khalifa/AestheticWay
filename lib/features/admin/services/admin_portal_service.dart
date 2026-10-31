import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/local_media_cache.dart';
import 'dart:collection';
import '../../../core/data/single_flight.dart';
import '../../../core/data/paged_collection.dart';
import '../../../core/auth/session_changed_exception.dart';
import 'package:flutter/foundation.dart';
import '../../../data/mock_data.dart';
import '../../offers/models/offer_model.dart';
import '../../products/models/product_model.dart';
import '../../articles/models/article_model.dart';
import '../../appointment_lead/models/appointment_request_model.dart';
import '../data/admin_repository.dart';
import '../models/admin_analytics_model.dart';
import '../models/admin_clinic_model.dart';
import '../models/admin_dashboard_model.dart';
import '../models/admin_lead_model.dart';

/// Super Admin Service managing platform-wide analytics, clinic controls, global leads and moderation
class AdminPortalService extends ChangeNotifier {
  static final AdminPortalService _instance = AdminPortalService._internal();
  factory AdminPortalService({AdminRepository? repository}) {
    if (repository != null) {
      _instance._repository = repository;
    }
    return _instance;
  }
  AdminPortalService._internal();

  AdminRepository _repository = AdminRepository();
  bool _mockMode = false;

  bool _isLoading = false;
  String? _errorMessage;

  AdminDashboardModel _dashboard = const AdminDashboardModel();
  final List<AdminClinicModel> _clinics = [];
  final List<AdminLeadModel> _allLeads = [];
  final List<AdminLeadModel> _recentLeads = [];
  String? _recentLeadsError;
  bool _recentLeadsLoading = false;
  List<AdminLeadModel> get recentLeads => UnmodifiableListView(
    _mockMode ? _allLeads.take(4).toList() : _recentLeads,
  );
  String? get recentLeadsError => _recentLeadsError;
  bool get recentLeadsLoading => _recentLeadsLoading;

  final List<OfferModel> _allOffers = [];
  AdminAnalyticsModel _analytics = const AdminAnalyticsModel();
  final Set<String> _suspendedOfferIds = {};
  final Set<String> _pendingWrites = {};
  final Map<String, String> _writeErrors = {};
  final Map<String, AdminClinicModel> _clinicDetails = {};
  final Map<String, String> _detailErrors = {};
  final Set<String> _detailLoading = {};
  AdminReferralAnalyticsModel? _referrals;
  bool _analyticsLoading = false, _referralsLoading = false;
  String? _analyticsError, _referralsError;
  bool get isMockMode => _mockMode;
  bool get canManage =>
      _mockMode || (AuthState().isLoggedIn && AuthState().isSuperAdmin);
  bool get overviewLoaded => _overviewLoaded || _mockMode;
  bool get analyticsLoaded => _analyticsKey != null || _mockMode;
  bool get analyticsLoading => _analyticsLoading;
  bool get referralsLoading => _referralsLoading;
  String? get overviewError => _errorMessage;
  String? get analyticsError => _analyticsError;
  String? get referralsError => _referralsError;
  AdminReferralAnalyticsModel? get referralAnalytics => _referrals;
  bool isPending(String kind, String id) =>
      _pendingWrites.contains('$kind:$id');
  String? writeError(String kind, String id) => _writeErrors['$kind:$id'];
  AdminClinicModel? clinicDetail(String id) => _clinicDetails[id];
  String? clinicDetailError(String id) => _detailErrors[id];
  bool clinicDetailLoading(String id) => _detailLoading.contains(id);

  void _requireManager() {
    if (!canManage) {
      throw const ApiException(
        message: 'Super Admin access is required.',
        statusCode: 403,
      );
    }
  }

  Future<bool> _confirmedWrite(
    String key,
    Future<void> Function() action,
  ) async {
    _requireManager();
    if (!_pendingWrites.add(key)) return false;
    final epoch = _sessionEpoch;
    _writeErrors.remove(key);
    notifyListeners();
    try {
      await action();
      return epoch == _sessionEpoch;
    } catch (error) {
      if (epoch == _sessionEpoch) {
        _writeErrors[key] = error is ApiException
            ? error.message
            : 'Could not save changes. Please retry.';
      }
      return false;
    } finally {
      if (epoch == _sessionEpoch) {
        _pendingWrites.remove(key);
        notifyListeners();
      }
    }
  }

  void _commitCollection(String key, VoidCallback change) {
    final page = _pages[key];
    if (page == null) {
      change();
    } else {
      page.mutate((_) => change());
    }
  }

  void _rememberClinicMedia(
    String id,
    Map<String, dynamic> data, {
    String? logo,
    String? cover,
  }) {
    for (final (field, key, url) in [
      ('logo', LocalMediaCache.clinicLogo(id), logo),
      ('cover_image', LocalMediaCache.clinicCover(id), cover),
    ]) {
      if (!data.containsKey(field)) continue;
      final value = data[field];
      if (value == null || value == '') {
        LocalMediaCache().remove(key);
      } else if (value is String) {
        LocalMediaCache().remember(
          localPath: value,
          entityKey: key,
          remoteUrl: url,
        );
      }
    }
  }

  Future<void> loadClinicDetail(
    String id, {
    bool refresh = false,
    AdminClinicModel? initial,
  }) {
    if (_mockMode) {
      if (initial != null) _clinicDetails.putIfAbsent(id, () => initial);
      return Future.value();
    }
    if (!refresh && _clinicDetails.containsKey(id)) return Future.value();
    return _flights.run('clinic-detail:$id', () async {
      final epoch = _sessionEpoch;
      _detailLoading.add(id);
      _detailErrors.remove(id);
      notifyListeners();
      try {
        final detail = await _inSession(_repository.getClinicDetail(id), epoch);
        if (detail.id != id) {
          throw const ApiException(
            message: 'The clinic response could not be verified.',
          );
        }
        _clinicDetails[id] = detail;
      } catch (error) {
        if (epoch == _sessionEpoch) {
          _detailErrors[id] = error is ApiException
              ? error.message
              : 'Could not load clinic details.';
        }
      } finally {
        if (epoch == _sessionEpoch) {
          _detailLoading.remove(id);
          notifyListeners();
        }
      }
    });
  }

  @visibleForTesting
  void enableMockMode() {
    _mockMode = true;
    _replaceItems(_allProducts, List.from(MockDataService().products));
    _replaceItems(_allArticles, List.from(MockDataService().articles));
    _populateInitialSeedData();
    notifyListeners();
  }

  final Map<String, PagedCollection<dynamic>> _pages = {};
  final SingleFlight _flights = SingleFlight();
  bool _overviewLoaded = false;
  bool _overviewDirty = false;
  String? _analyticsKey;
  String? _analyticsRequestedKey;
  int _analyticsRevision = 0;
  Future<void>? _analyticsFlight;

  PagedCollection<dynamic> collection(String key) {
    final result = _pages.putIfAbsent(key, () {
      final PagedCollection<dynamic> page = switch (key) {
        'clinics' => PagedCollection<AdminClinicModel>(
          items: _clinics,
          loader: (page, q) => _repository.getClinics(
            page: page,
            status: q['status'] as String?,
            tier: q['tier'] as String?,
            search: q['search'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'leads' => PagedCollection<AdminLeadModel>(
          items: _allLeads,
          loader: (page, q) => _repository.getLeads(
            page: page,
            status: q['status'] as String?,
            clinicId: q['clinic'] as String?,
            search: q['search'] as String?,
            dateFrom: q['date_from'] as String?,
            dateTo: q['date_to'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'offers' => PagedCollection<OfferModel>(
          items: _allOffers,
          loader: (page, q) => _repository.getOffers(
            page: page,
            search: q['search'],
            status: q['status'] as String?,
            clinicId: q['clinic'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'products' => PagedCollection<ProductModel>(
          items: _allProducts,
          loader: (page, q) => _repository.getProducts(
            page: page,
            search: q['search'],
            status: q['status'] as String?,
            clinicId: q['clinic'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'articles' => PagedCollection<ArticleModel>(
          items: _allArticles,
          loader: (page, q) => _repository.getArticles(
            page: page,
            search: q['search'],
            status: q['status'] as String?,
            clinicId: q['clinic'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        _ => throw ArgumentError.value(key, 'key', 'Unknown collection'),
      };
      page.addListener(notifyListeners);
      return page;
    });
    if (_mockMode) {
      result.isLoaded = true;
      result.hasMore = false;
    }
    return result;
  }

  Future<void> loadCollection(
    String key, {
    bool refresh = false,
    Map<String, dynamic>? query,
  }) {
    if (_mockMode) return Future.value();
    return collection(key).refresh(query: query, force: refresh);
  }

  void searchCollection(String key, Map<String, dynamic> query) {
    if (!_mockMode) collection(key).search(query);
  }

  Future<void> loadMore(String key) =>
      _mockMode ? Future.value() : collection(key).loadMore();

  void _replaceItems<T>(List<T> target, Iterable<dynamic> values) {
    final snapshot = values.cast<T>().toList();
    target
      ..clear()
      ..addAll(snapshot);
  }

  int _sessionEpoch = 0;

  /// Discard all account-scoped state and invalidate outstanding requests.
  void clearSession({bool notify = true}) {
    _sessionEpoch++;
    for (final page in _pages.values) {
      page.clear();
    }
    _flights.clear();
    _overviewLoaded = false;
    _overviewDirty = false;
    _analyticsKey = null;
    _analyticsRequestedKey = null;
    _analyticsRevision++;
    _analyticsFlight = null;
    _mockMode = false;
    _isLoading = false;
    _errorMessage = null;
    _dashboard = const AdminDashboardModel();
    _replaceItems(_clinics, []);
    _replaceItems(_allLeads, []);
    _recentLeads.clear();
    _recentLeadsError = null;
    _recentLeadsLoading = false;
    _replaceItems(_allOffers, []);
    _replaceItems(_allProducts, []);
    _replaceItems(_allArticles, []);
    _analytics = const AdminAnalyticsModel();
    _suspendedOfferIds.clear();
    _pendingWrites.clear();
    _writeErrors.clear();
    _clinicDetails.clear();
    _detailErrors.clear();
    _detailLoading.clear();
    _referrals = null;
    _analyticsLoading = false;
    _referralsLoading = false;
    _analyticsError = null;
    _referralsError = null;
    if (notify) notifyListeners();
  }

  @visibleForTesting
  void resetTestingState() => clearSession(notify: false);

  Future<T> _inSession<T>(Future<T> future, int epoch) async {
    try {
      final result = await future;
      if (epoch != _sessionEpoch) throw const SessionChangedException();
      return result;
    } catch (_) {
      if (epoch != _sessionEpoch) throw const SessionChangedException();
      rethrow;
    }
  }

  bool get isLoading =>
      _isLoading || _pages.values.any((page) => page.isLoading);
  String? get errorMessage =>
      _errorMessage ??
      _pages.values.map((page) => page.error).whereType<String>().firstOrNull;

  AdminDashboardModel get dashboard => _dashboard;
  List<AdminClinicModel> get clinics => UnmodifiableListView(_clinics);
  List<AdminLeadModel> get allLeads => UnmodifiableListView(_allLeads);
  List<OfferModel> get allOffers => UnmodifiableListView(_allOffers);
  AdminAnalyticsModel get analytics => _analytics;
  Set<String> get suspendedOfferIds => Set.unmodifiable(_suspendedOfferIds);

  // Platform Dashboard & KPI Shortcuts (strictly real API, 0 if empty/null)
  int get totalAppOpens => _analytics.appOpens;
  int get activeUsersCount => _dashboard.totalPatients;
  int get activeClinicsCount => _mockMode
      ? _clinics.where((c) => c.isActive && !c.isSuspended).length
      : _dashboard.activeClinics;
  int get totalLeadsCount =>
      _mockMode ? _allLeads.length : _dashboard.totalLeads;
  int get contactedLeadsCount => _dashboard.contactedLeads;

  int get totalWhatsappTaps => _analytics.whatsappTaps;
  int get totalCallTaps => _analytics.callTaps;
  int get totalMapsTaps => _analytics.mapsTaps;
  int get totalLeadSubmissions => _analytics.leadSubmissions;
  int get totalEvents => _analytics.totalEvents;

  List<AdminClinicEngagementEntry> get analyticsTable =>
      UnmodifiableListView(_analytics.clinicEngagement);

  AdminClinicEngagementEntry? getMetricForClinic(String clinicId) {
    try {
      return _analytics.clinicEngagement.firstWhere(
        (e) => e.clinicId == clinicId,
      );
    } catch (_) {
      return null;
    }
  }

  bool isOfferSuspended(String offerId) {
    if (_suspendedOfferIds.contains(offerId)) return true;
    try {
      final o = _allOffers.firstWhere((off) => off.id == offerId);
      return o.status == 'suspended';
    } catch (_) {
      return false;
    }
  }

  final List<ProductModel> _allProducts = [];
  final List<ArticleModel> _allArticles = [];

  List<ProductModel> get allProducts => UnmodifiableListView(_allProducts);
  List<ArticleModel> get allArticles => UnmodifiableListView(_allArticles);

  Future<bool> toggleProductModeration(String id, {String notes = ''}) {
    final item = _allProducts.where((p) => p.id == id).firstOrNull;
    if (item == null || item.status == 'unknown') return Future.value(false);
    return setContentStatus(
      'product',
      id,
      item.status == 'active' ? 'suspended' : 'active',
      notes: notes,
    );
  }

  Future<bool> toggleArticleModeration(String id, {String notes = ''}) {
    final item = _allArticles.where((p) => p.id == id).firstOrNull;
    if (item == null || item.status == 'unknown') return Future.value(false);
    return setContentStatus(
      'article',
      id,
      item.status == 'active' ? 'suspended' : 'active',
      notes: notes,
    );
  }

  /// A real acknowledged target state; unknown legacy responses never become Active by default.
  Future<bool> setContentStatus(
    String kind,
    String id,
    String target, {
    String notes = '',
  }) {
    if (!['offer', 'product', 'article'].contains(kind) ||
        !['active', 'suspended'].contains(target)) {
      return Future.value(false);
    }
    final epoch = _sessionEpoch;
    return _confirmedWrite('$kind:$id', () async {
      final Map<String, dynamic> response;
      if (_mockMode) {
        response = {'new_status': target};
      } else {
        final future = switch ((kind, target)) {
          ('offer', 'active') => _repository.approveOffer(id, notes: notes),
          ('offer', _) => _repository.suspendOffer(id, notes: notes),
          ('product', 'active') => _repository.approveProduct(id, notes: notes),
          ('product', _) => _repository.suspendProduct(id, notes: notes),
          ('article', 'active') => _repository.approveArticle(id, notes: notes),
          _ => _repository.suspendArticle(id, notes: notes),
        };
        response = await _inSession(future, epoch);
      }
      if (response['new_status'] != target ||
          (response['id'] != null && '${response['id']}' != id)) {
        throw const ApiException(
          message:
              'The moderation result could not be verified. Refresh before retrying.',
        );
      }
      _commitCollection('${kind}s', () {
        if (kind == 'offer') {
          final i = _allOffers.indexWhere((p) => p.id == id);
          if (i >= 0) {
            _allOffers[i] = _allOffers[i].copyWith(
              status: target,
              isActive: target == 'active',
            );
          }
          if (target == 'suspended') {
            _suspendedOfferIds.add(id);
          } else {
            _suspendedOfferIds.remove(id);
          }
        } else if (kind == 'product') {
          final i = _allProducts.indexWhere((p) => p.id == id);
          if (i >= 0) {
            _allProducts[i] = _allProducts[i].copyWith(
              status: target,
              isPublishedByAdmin: target == 'active',
              isAvailable: target == 'active',
            );
          }
        } else {
          final i = _allArticles.indexWhere((p) => p.id == id);
          if (i >= 0) {
            _allArticles[i] = _allArticles[i].copyWith(
              status: target,
              isApprovedByAdmin: target == 'active',
            );
          }
        }
      });
      if (!_mockMode && _pages['${kind}s']?.query['status'] != null) {
        await loadCollection('${kind}s', refresh: true);
      }
    });
  }

  void _populateInitialSeedData() {
    _replaceItems(
      _clinics,
      MockDataService().clinics
          .map(
            (c) => AdminClinicModel(
              id: c.id,
              nameEn: c.nameEn,
              nameAr: c.nameAr,
              city: c.city,
              status: 'active',
              subscriptionTier: c.subscriptionTier,
              isActive: true,
              coverImage: c.coverImageUrl,
              leadsCount: 12,
            ),
          )
          .toList(),
    );

    final initialLeads = MockDataService().appointmentRequests
        .map(
          (r) => AdminLeadModel(
            id: r.id,
            referenceCode: r.referenceCode,
            status: r.status == AppointmentLeadStatus.contacted
                ? 'contacted'
                : (r.status == AppointmentLeadStatus.closed ? 'closed' : 'new'),
            leadType: 'consultation',
            serviceName: r.serviceNameAr,
            clinicId: r.clinicId,
            clinicNameEn: r.clinicNameEn ?? r.clinicNameAr,
            clinicNameAr: r.clinicNameAr,
            clinicCity: 'Dubai',
            patientName: r.patientFullName,
            patientPhone: r.patientPhone,
            patientEmail: '',
            preferredTimeWindow:
                r.preferredTimeWindow == PreferredTimeWindow.morning
                ? 'morning'
                : (r.preferredTimeWindow == PreferredTimeWindow.afternoon
                      ? 'afternoon'
                      : 'evening'),
            notes: r.notes ?? '',
            createdAt: r.createdAt,
          ),
        )
        .toList();

    while (initialLeads.length < 8 && _clinics.isNotEmpty) {
      final i = initialLeads.length;
      final clinic = _clinics[i % _clinics.length];
      initialLeads.add(
        AdminLeadModel(
          id: 'seed-lead-${i + 1}',
          referenceCode: 'AW-2026-${1000 + i}',
          status: i == 0 ? 'new' : (i % 2 == 0 ? 'contacted' : 'closed'),
          leadType: 'consultation',
          serviceName: i % 2 == 0 ? 'استشارة جلدية متقدمة' : 'جلسة نضارة وليزر',
          clinicId: clinic.id,
          clinicNameEn: clinic.nameEn,
          clinicNameAr: clinic.nameAr,
          clinicCity: clinic.city,
          patientName: 'مريض تجريبي ${i + 1}',
          patientPhone: '+97150${1000000 + i}',
          patientEmail: 'patient${i + 1}@example.com',
          preferredTimeWindow: i % 3 == 0
              ? 'morning'
              : (i % 3 == 1 ? 'afternoon' : 'evening'),
          notes: 'طلب استفسار ومتابعة من المنصة',
          createdAt: DateTime.now().subtract(Duration(hours: i * 4)),
        ),
      );
    }
    _replaceItems(_allLeads, initialLeads);

    final initialOffers = List<OfferModel>.from(MockDataService().offers);
    if (initialOffers.length < 5) {
      initialOffers.add(
        const OfferModel(
          id: 'adm-off-105',
          clinicId: 'kaya-jumeirah',
          clinicNameAr: 'عيادة كايا للبشرة',
          clinicNameEn: 'Kaya Skin Clinic',
          titleAr: 'باقة تنظيف وتقشير ألما الماسي',
          titleEn: 'Alma Diamond Glow Facial Package',
          originalPrice: 1200.0,
          offerPrice: 850.0,
          discountPercentage: 29,
          validUntilText: 'نهاية الشهر',
          validUntilTextEn: 'End of month',
          daysRemaining: 15,
          termsAr: 'تطبق الشروط والأحكام بالعيادة',
          imageUrl:
              'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=800',
          isActive: true,
        ),
      );
    }
    _replaceItems(_allOffers, initialOffers);

    _analytics = const AdminAnalyticsModel();
  }

  // -------------------------------------------------------------
  // DATA LOADING
  // -------------------------------------------------------------

  Future<void> loadAllData({bool refresh = false}) {
    if (_mockMode) return Future.value();
    return _flights.run(
      'all',
      () => Future.wait([
        loadOverview(refresh: refresh),
        for (final key in [
          'clinics',
          'leads',
          'offers',
          'products',
          'articles',
        ])
          loadCollection(key, refresh: refresh),
      ]).then((_) {}),
    );
  }

  Future<void> loadOverview({bool refresh = false}) {
    if (_mockMode || (_overviewLoaded && !_overviewDirty && !refresh)) {
      return Future.value();
    }
    return _flights.run('overview', () => _fetchOverview(refresh: refresh));
  }

  Future<void> _loadRecentLeads({bool refresh = false}) async {
    final epoch = _sessionEpoch;
    _recentLeadsLoading = true;
    _recentLeadsError = null;
    try {
      final query = _pages['leads']?.query ?? {};
      final unfiltered = query.values.every(
        (v) => v == null || v == '' || v == 'all',
      );
      final List<AdminLeadModel> rows;
      if (unfiltered) {
        await _inSession(loadCollection('leads', refresh: refresh), epoch);
        if (_pages['leads']?.error != null) {
          throw ApiException(message: _pages['leads']!.error!);
        }
        rows = _allLeads;
      } else {
        rows = await _inSession(_repository.getLeads(), epoch);
      }
      _recentLeads
        ..clear()
        ..addAll(rows.take(4));
    } catch (error) {
      if (epoch == _sessionEpoch) {
        _recentLeadsError = error is ApiException
            ? error.message
            : 'Could not load recent requests.';
      }
    } finally {
      if (epoch == _sessionEpoch) _recentLeadsLoading = false;
    }
  }

  Future<void> _fetchOverview({bool refresh = false}) async {
    final epoch = _sessionEpoch;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final values = await _inSession(
        Future.wait([
          _repository.getDashboard(),
          _loadRecentLeads(refresh: refresh),
        ]),
        epoch,
      );
      _dashboard = values[0] as AdminDashboardModel;
      _overviewLoaded = true;
      _overviewDirty = false;
    } catch (error) {
      if (epoch == _sessionEpoch) _errorMessage = error.toString();
    } finally {
      if (epoch == _sessionEpoch) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<List<OfferModel>> getClinicOffersPage(
    String clinicId,
    int page,
  ) async {
    if (_mockMode) {
      final values = _allOffers.where((o) => o.clinicId == clinicId).toList();
      return PageItems(
        values.skip((page - 1) * catalogPageSize).take(catalogPageSize),
        hasMore: page * catalogPageSize < values.length,
        total: values.length,
      );
    }
    return _inSession(
      _repository.getOffers(clinicId: clinicId, page: page),
      _sessionEpoch,
    );
  }

  Future<void> loadProducts({String? status, String? clinicId}) =>
      loadCollection(
        'products',
        refresh: true,
        query: {'status': status, 'clinic': clinicId},
      );

  Future<void> loadArticles({String? status, String? clinicId}) =>
      loadCollection(
        'articles',
        refresh: true,
        query: {'status': status, 'clinic': clinicId},
      );

  Future<AdminLeadModel> getLeadDetail(String id) =>
      _inSession(_repository.getLeadDetail(id), _sessionEpoch);

  Future<List<AdminClinicModel>> getClinicRecordsPage(int page, String search) {
    _requireManager();
    return _inSession(
      _repository.getClinics(page: page, search: search),
      _sessionEpoch,
    );
  }

  Future<List<AdminLeadModel>> getLeadRecordsPage(
    int page,
    Map<String, dynamic> query,
  ) {
    _requireManager();
    return _inSession(
      _repository.getLeads(
        page: page,
        clinicId: query['clinic'] as String?,
        status: query['status'] as String?,
        search: query['search'] as String?,
        dateFrom: query['date_from'] as String?,
        dateTo: query['date_to'] as String?,
      ),
      _sessionEpoch,
    );
  }

  Future<void> loadDashboard() async {
    final sessionEpoch = _sessionEpoch;
    try {
      _dashboard = await _inSession(_repository.getDashboard(), sessionEpoch);
      notifyListeners();
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadClinics({String? status, String? tier, String? search}) =>
      loadCollection(
        'clinics',
        refresh: true,
        query: {'status': status, 'tier': tier, 'search': search},
      );

  Future<void> loadLeads({String? status, String? clinicId, String? search}) =>
      loadCollection(
        'leads',
        refresh: true,
        query: {'status': status, 'clinic': clinicId, 'search': search},
      );

  Future<void> loadOffers({String? status, String? clinicId}) => loadCollection(
    'offers',
    refresh: true,
    query: {'status': status, 'clinic': clinicId},
  );

  Future<void> loadAnalytics({
    String? dateFrom,
    String? dateTo,
    bool refresh = false,
  }) {
    final key = '${dateFrom ?? ""}|${dateTo ?? ""}';
    if (_mockMode) return Future.value();
    if (_analyticsLoading && _analyticsRequestedKey == key) {
      return _analyticsFlight ?? Future.value();
    }
    if (!refresh && !_analyticsLoading && _analyticsKey == key) {
      return Future.value();
    }
    final revision = ++_analyticsRevision;
    final epoch = _sessionEpoch;
    _analyticsRequestedKey = key;
    _analyticsLoading = true;
    _analyticsError = null;
    notifyListeners();
    return _analyticsFlight = _fetchAnalytics(
      dateFrom,
      dateTo,
      revision,
      epoch,
      key,
    );
  }

  Future<void> _fetchAnalytics(
    String? from,
    String? to,
    int revision,
    int epoch,
    String key,
  ) async {
    bool current() => epoch == _sessionEpoch && revision == _analyticsRevision;
    try {
      final result = await _inSession(
        _repository.getAnalytics(dateFrom: from, dateTo: to),
        epoch,
      );
      if (!current()) return;
      _analytics = result;
      _analyticsKey = key;
    } catch (error) {
      if (current()) {
        _analyticsError = error is ApiException
            ? error.message
            : 'Could not load analytics.';
      }
    } finally {
      if (current()) {
        _analyticsLoading = false;
        _analyticsFlight = null;
        notifyListeners();
      }
    }
  }

  Future<void> loadReferralAnalytics({bool refresh = false}) {
    if (_mockMode || (!refresh && _referrals != null)) return Future.value();
    return _flights.run('referral-analytics', () async {
      final epoch = _sessionEpoch;
      _referralsLoading = true;
      _referralsError = null;
      notifyListeners();
      try {
        _referrals = await _inSession(
          _repository.getReferralAnalytics(),
          epoch,
        );
      } catch (error) {
        if (epoch == _sessionEpoch) {
          _referralsError = error is ApiException
              ? error.message
              : 'Could not load referral analytics.';
        }
      } finally {
        if (epoch == _sessionEpoch) {
          _referralsLoading = false;
          notifyListeners();
        }
      }
    });
  }

  // -------------------------------------------------------------
  // MUTATIONS (STATUS TOGGLES)
  // -------------------------------------------------------------

  Future<bool> toggleClinicStatus(String id, {String reason = ''}) {
    final clinic =
        _clinicDetails[id] ?? _clinics.where((c) => c.id == id).firstOrNull;
    if (clinic == null) return Future.value(false);
    final target = clinic.isActive && !clinic.isSuspended
        ? 'suspended'
        : 'active';
    final epoch = _sessionEpoch;
    return _confirmedWrite('clinic:$id', () async {
      final response = _mockMode
          ? {'new_status': target}
          : await _inSession(
              target == 'active'
                  ? _repository.activateClinic(id, reason: reason)
                  : _repository.suspendClinic(id, reason: reason),
              epoch,
            );
      if (response['new_status'] != target ||
          (response['clinic_id'] != null && '${response['clinic_id']}' != id)) {
        throw const ApiException(
          message:
              'The clinic status result could not be verified. Please refresh.',
        );
      }
      final updated = clinic.copyWith(
        status: target,
        isActive: target == 'active',
      );
      _clinicDetails[id] = updated;
      _commitCollection('clinics', () {
        final i = _clinics.indexWhere((c) => c.id == id);
        if (i >= 0) _clinics[i] = updated;
      });
      _overviewDirty = true;
      if (!_mockMode) await loadCollection('clinics', refresh: true);
    });
  }

  Future<bool> toggleOfferModeration(String id, {String notes = ''}) {
    final item = _allOffers.where((p) => p.id == id).firstOrNull;
    if (item == null || item.status == 'unknown') return Future.value(false);
    return setContentStatus(
      'offer',
      id,
      item.status == 'active' ? 'suspended' : 'active',
      notes: notes,
    );
  }

  /// Filter leads by clinic and status (locally or with pre-filtered list)
  List<AdminLeadModel> getFilteredLeads({String? clinicId, String? status}) {
    return _allLeads.where((l) {
      final matchesClinic =
          (clinicId == null || clinicId.isEmpty || clinicId == 'all')
          ? true
          : l.clinicId == clinicId;
      final matchesStatus =
          (status == null || status.isEmpty || status.toLowerCase() == 'all')
          ? true
          : l.status.toLowerCase() == status.toLowerCase();
      return matchesClinic && matchesStatus;
    }).toList();
  }

  /// Provision a new clinic and its administrator
  Future<Map<String, dynamic>> createClinic(Map<String, dynamic> data) async {
    _requireManager();
    if (!_pendingWrites.add('clinic:create')) {
      throw const ApiException(
        message: 'Clinic provisioning is already in progress.',
      );
    }
    final sessionEpoch = _sessionEpoch;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _inSession(
        _repository.createClinic(data),
        sessionEpoch,
      );
      final clinicData = res['clinic'];
      if (clinicData is! Map ||
          clinicData['id'] == null ||
          '${clinicData['id']}'.isEmpty) {
        throw const ApiException(
          message:
              'The server did not return the new clinic ID. Refresh the clinic list before retrying.',
        );
      }
      _rememberClinicMedia(
        '${clinicData['id']}',
        data,
        logo: clinicData['logo']?.toString(),
        cover: clinicData['cover_image']?.toString(),
      );
      _overviewDirty = true;
      await _inSession(loadCollection('clinics', refresh: true), sessionEpoch);
      return res;
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        rethrow;
      }
      _writeErrors['clinic:create'] = e is ApiException
          ? e.message
          : 'Could not save changes.';
      rethrow;
    } finally {
      if (sessionEpoch == _sessionEpoch) {
        _pendingWrites.remove('clinic:create');
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Reset temporary password for a clinic administrator
  Future<Map<String, dynamic>> resetClinicAdminPassword(
    String id, {
    String? customPassword,
  }) async {
    _requireManager();
    if (!_pendingWrites.add('password:$id')) {
      throw const ApiException(
        message: 'A password reset is already in progress.',
      );
    }
    final epoch = _sessionEpoch;
    notifyListeners();
    try {
      return await _inSession(
        _repository.resetClinicAdminPassword(
          id,
          customPassword: customPassword,
        ),
        epoch,
      );
    } finally {
      if (epoch == _sessionEpoch) {
        _pendingWrites.remove('password:$id');
        notifyListeners();
      }
    }
  }

  /// Archive / Soft-delete a clinic
  Future<void> archiveClinic(String clinicId) async {
    _requireManager();
    final sessionEpoch = _sessionEpoch;
    await _inSession(_repository.archiveClinic(clinicId), sessionEpoch);
    _clinics.removeWhere((c) => c.id == clinicId);
    notifyListeners();
  }

  /// Update an existing clinic's details, tier, or branding
  Future<AdminClinicModel> updateClinic(
    String id,
    Map<String, dynamic> data,
  ) async {
    _requireManager();
    if (!_pendingWrites.add('clinic:$id')) {
      throw const ApiException(
        message: 'This clinic is already being updated.',
      );
    }
    final sessionEpoch = _sessionEpoch;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _inSession(
        _repository.updateClinic(id, data),
        sessionEpoch,
      );
      if (updated.id != id) {
        throw const ApiException(
          message: 'The clinic response could not be verified. Please refresh.',
        );
      }
      _rememberClinicMedia(
        id,
        data,
        logo: updated.logo,
        cover: updated.coverImage,
      );
      _clinicDetails[id] = updated;
      _commitCollection('clinics', () {
        final idx = _clinics.indexWhere((c) => c.id == id);
        if (idx >= 0) _clinics[idx] = updated;
      });
      _overviewDirty = true;
      if (_pages['clinics']?.query.values.any(
            (v) => v != null && v != '' && v != 'all',
          ) ==
          true) {
        await _inSession(
          loadCollection('clinics', refresh: true),
          sessionEpoch,
        );
      }
      return updated;
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        rethrow;
      }
      _writeErrors['clinic:$id'] = e is ApiException
          ? e.message
          : 'Could not save changes.';
      rethrow;
    } finally {
      if (sessionEpoch == _sessionEpoch) {
        _pendingWrites.remove('clinic:$id');
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
