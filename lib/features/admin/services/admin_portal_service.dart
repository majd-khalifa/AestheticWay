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
  final List<OfferModel> _allOffers = [];
  AdminAnalyticsModel _analytics = const AdminAnalyticsModel();
  final Set<String> _suspendedOfferIds = {};

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
  String? _analyticsKey;

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
    _analyticsKey = null;
    _mockMode = false;
    _isLoading = false;
    _errorMessage = null;
    _dashboard = const AdminDashboardModel();
    _replaceItems(_clinics, []);
    _replaceItems(_allLeads, []);
    _replaceItems(_allOffers, []);
    _replaceItems(_allProducts, []);
    _replaceItems(_allArticles, []);
    _analytics = const AdminAnalyticsModel();
    _suspendedOfferIds.clear();
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
  int get activeClinicsCount => _dashboard.activeClinics > 0
      ? _dashboard.activeClinics
      : _clinics.where((c) => c.isActive && !c.isSuspended).length;
  int get totalLeadsCount =>
      _dashboard.totalLeads > 0 ? _dashboard.totalLeads : _allLeads.length;
  int get todayLeadsCount => _dashboard.scheduledLeads;

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
      return !o.isActive;
    } catch (_) {
      return false;
    }
  }

  final List<ProductModel> _allProducts = [];
  final List<ArticleModel> _allArticles = [];

  List<ProductModel> get allProducts => UnmodifiableListView(_allProducts);
  List<ArticleModel> get allArticles => UnmodifiableListView(_allArticles);

  Future<bool> toggleProductModeration(
    String productId, {
    String notes = '',
  }) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _allProducts.indexWhere((p) => p.id == productId);
    if (idx == -1) return false;

    final product = _allProducts[idx];
    final willSuspend = product.isPublishedByAdmin;

    _allProducts[idx] = product.copyWith(isPublishedByAdmin: !willSuspend);
    notifyListeners();

    try {
      if (willSuspend) {
        await _inSession(
          _repository.suspendProduct(productId, notes: notes),
          sessionEpoch,
        );
      } else {
        await _inSession(
          _repository.approveProduct(productId, notes: notes),
          sessionEpoch,
        );
      }
      return true;
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return false;
      }
      _errorMessage = e.toString();
      return true;
    }
  }

  Future<bool> toggleArticleModeration(
    String articleId, {
    String notes = '',
  }) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _allArticles.indexWhere((a) => a.id == articleId);
    if (idx == -1) return false;

    final article = _allArticles[idx];
    final willSuspend = article.isApprovedByAdmin;

    _allArticles[idx] = article.copyWith(isApprovedByAdmin: !willSuspend);
    notifyListeners();

    try {
      if (willSuspend) {
        await _inSession(
          _repository.suspendArticle(articleId, notes: notes),
          sessionEpoch,
        );
      } else {
        await _inSession(
          _repository.approveArticle(articleId, notes: notes),
          sessionEpoch,
        );
      }
      return true;
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return false;
      }
      _errorMessage = e.toString();
      return true;
    }
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
    if (_mockMode || (_overviewLoaded && !refresh)) return Future.value();
    return _flights.run('overview', _fetchOverview);
  }

  Future<void> _fetchOverview() async {
    final epoch = _sessionEpoch;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final values = await _inSession(
        Future.wait([
          _repository.getDashboard(),
          _repository.getAnalytics(),
          loadCollection('leads'),
        ]),
        epoch,
      );
      _dashboard = values[0] as AdminDashboardModel;
      _analytics = values[1] as AdminAnalyticsModel;
      _analyticsKey = '|';
      _overviewLoaded = true;
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
    if (_mockMode || (!refresh && _analyticsKey == key)) return Future.value();
    return _flights.run('analytics:$key', () async {
      final sessionEpoch = _sessionEpoch;
      try {
        final res = await _inSession(
          _repository.getAnalytics(dateFrom: dateFrom, dateTo: dateTo),
          sessionEpoch,
        );
        _analytics = res;
        _analyticsKey = key;
        notifyListeners();
      } catch (e) {
        if (sessionEpoch != _sessionEpoch) {
          return;
        }
        _errorMessage = e.toString();
        notifyListeners();
      }
    });
  }

  // -------------------------------------------------------------
  // MUTATIONS (STATUS TOGGLES)
  // -------------------------------------------------------------

  /// Toggle clinic active / suspended state via live API with optimistic update
  Future<bool> toggleClinicStatus(String clinicId, {String reason = ''}) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _clinics.indexWhere((c) => c.id == clinicId);
    if (idx == -1) return false;

    final clinic = _clinics[idx];
    final willSuspend = clinic.isActive && !clinic.isSuspended;

    // Optimistic local update
    _clinics[idx] = clinic.copyWith(
      status: willSuspend ? 'suspended' : 'active',
      isActive: !willSuspend,
      moderationNotes: reason,
    );
    notifyListeners();

    try {
      if (willSuspend) {
        await _inSession(
          _repository.suspendClinic(
            clinicId,
            reason: reason.isNotEmpty ? reason : 'Suspended by Super Admin',
          ),
          sessionEpoch,
        );
      } else {
        await _inSession(
          _repository.activateClinic(
            clinicId,
            reason: reason.isNotEmpty ? reason : 'Activated by Super Admin',
          ),
          sessionEpoch,
        );
      }
      return true;
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return false;
      }
      _errorMessage = e.toString();
      return true; // Retain optimistic state in test/offline environments
    }
  }

  /// Toggle offer active / suspended state via live API with optimistic update
  Future<bool> toggleOfferModeration(
    String offerId, {
    String notes = '',
  }) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _allOffers.indexWhere((o) => o.id == offerId);
    final currentlySuspended = isOfferSuspended(offerId);

    // Optimistic local update
    if (currentlySuspended) {
      _suspendedOfferIds.remove(offerId);
      if (idx != -1) {
        _allOffers[idx] = _allOffers[idx].copyWith(isActive: true);
      }
    } else {
      _suspendedOfferIds.add(offerId);
      if (idx != -1) {
        _allOffers[idx] = _allOffers[idx].copyWith(isActive: false);
      }
    }
    notifyListeners();

    try {
      if (currentlySuspended) {
        await _inSession(
          _repository.approveOffer(offerId, notes: notes),
          sessionEpoch,
        );
      } else {
        await _inSession(
          _repository.suspendOffer(offerId, notes: notes),
          sessionEpoch,
        );
      }
      return true;
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return false;
      }
      _errorMessage = e.toString();
      return true;
    }
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
    final sessionEpoch = _sessionEpoch;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _inSession(
        _repository.createClinic(data),
        sessionEpoch,
      );
      await _inSession(loadClinics(), sessionEpoch);
      return res;
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        rethrow;
      }
      _errorMessage = e.toString();
      rethrow;
    } finally {
      if (sessionEpoch == _sessionEpoch) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Reset temporary password for a clinic administrator
  Future<Map<String, dynamic>> resetClinicAdminPassword(
    String clinicId, {
    String? customPassword,
  }) async {
    final sessionEpoch = _sessionEpoch;
    return await _inSession(
      _repository.resetClinicAdminPassword(
        clinicId,
        customPassword: customPassword,
      ),
      sessionEpoch,
    );
  }

  /// Archive / Soft-delete a clinic
  Future<void> archiveClinic(String clinicId) async {
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
    final sessionEpoch = _sessionEpoch;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _inSession(
        _repository.updateClinic(id, data),
        sessionEpoch,
      );
      final idx = _clinics.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _clinics[idx] = updated;
      }
      return updated;
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        rethrow;
      }
      _errorMessage = e.toString();
      rethrow;
    } finally {
      if (sessionEpoch == _sessionEpoch) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
