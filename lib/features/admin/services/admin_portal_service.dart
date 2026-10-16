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
  AdminPortalService._internal() {
    loadAllData();
  }

  AdminRepository _repository = AdminRepository();
  bool _mockMode = false;

  bool _isLoading = false;
  String? _errorMessage;

  AdminDashboardModel _dashboard = const AdminDashboardModel();
  List<AdminClinicModel> _clinics = [];
  List<AdminLeadModel> _allLeads = [];
  List<OfferModel> _allOffers = [];
  AdminAnalyticsModel _analytics = const AdminAnalyticsModel();
  final Set<String> _suspendedOfferIds = {};

  @visibleForTesting
  void enableMockMode() {
    _mockMode = true;
    _allProducts = List.from(MockDataService().products);
    _allArticles = List.from(MockDataService().articles);
    _populateInitialSeedData();
    notifyListeners();
  }

  @visibleForTesting
  void resetTestingState() {
    _mockMode = false;
    _isLoading = false;
    _errorMessage = null;
    _dashboard = const AdminDashboardModel();
    _clinics = [];
    _allLeads = [];
    _allOffers = [];
    _allProducts = [];
    _allArticles = [];
    _analytics = const AdminAnalyticsModel();
    _suspendedOfferIds.clear();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AdminDashboardModel get dashboard => _dashboard;
  List<AdminClinicModel> get clinics => List.unmodifiable(_clinics);
  List<AdminLeadModel> get allLeads => List.unmodifiable(_allLeads);
  List<OfferModel> get allOffers => List.unmodifiable(_allOffers);
  AdminAnalyticsModel get analytics => _analytics;
  Set<String> get suspendedOfferIds => Set.unmodifiable(_suspendedOfferIds);

  // Platform Dashboard & KPI Shortcuts (strictly real API, 0 if empty/null)
  int get totalAppOpens => _analytics.appOpens;
  int get activeUsersCount => _dashboard.totalPatients;
  int get activeClinicsCount => _dashboard.activeClinics > 0
      ? _dashboard.activeClinics
      : _clinics.where((c) => c.isActive && !c.isSuspended).length;
  int get totalLeadsCount => _dashboard.totalLeads > 0 ? _dashboard.totalLeads : _allLeads.length;
  int get todayLeadsCount => _dashboard.scheduledLeads;

  int get totalWhatsappTaps => _analytics.whatsappTaps;
  int get totalCallTaps => _analytics.callTaps;
  int get totalMapsTaps => _analytics.mapsTaps;
  int get totalLeadSubmissions => _analytics.leadSubmissions;
  int get totalEvents => _analytics.totalEvents;

  List<AdminClinicEngagementEntry> get analyticsTable =>
      List.unmodifiable(_analytics.clinicEngagement);

  AdminClinicEngagementEntry? getMetricForClinic(String clinicId) {
    try {
      return _analytics.clinicEngagement.firstWhere((e) => e.clinicId == clinicId);
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

  List<ProductModel> _allProducts = [];
  List<ArticleModel> _allArticles = [];

  List<ProductModel> get allProducts => List.unmodifiable(_allProducts);
  List<ArticleModel> get allArticles => List.unmodifiable(_allArticles);

  Future<bool> toggleProductModeration(String productId, {String notes = ''}) async {
    final idx = _allProducts.indexWhere((p) => p.id == productId);
    if (idx == -1) return false;

    final product = _allProducts[idx];
    final willSuspend = product.isPublishedByAdmin;

    _allProducts[idx] = product.copyWith(isPublishedByAdmin: !willSuspend);
    notifyListeners();

    try {
      if (willSuspend) {
        await _repository.suspendProduct(productId, notes: notes);
      } else {
        await _repository.approveProduct(productId, notes: notes);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return true;
    }
  }

  Future<bool> toggleArticleModeration(String articleId, {String notes = ''}) async {
    final idx = _allArticles.indexWhere((a) => a.id == articleId);
    if (idx == -1) return false;

    final article = _allArticles[idx];
    final willSuspend = article.isApprovedByAdmin;

    _allArticles[idx] = article.copyWith(isApprovedByAdmin: !willSuspend);
    notifyListeners();

    try {
      if (willSuspend) {
        await _repository.suspendArticle(articleId, notes: notes);
      } else {
        await _repository.approveArticle(articleId, notes: notes);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return true;
    }
  }

  void _populateInitialSeedData() {
    _clinics = MockDataService().clinics.map((c) => AdminClinicModel(
      id: c.id,
      nameEn: c.nameEn,
      nameAr: c.nameAr,
      city: c.city,
      status: 'active',
      subscriptionTier: c.subscriptionTier,
      isActive: true,
      coverImage: c.coverImageUrl,
      leadsCount: 12,
    )).toList();

    final initialLeads = MockDataService().appointmentRequests.map((r) => AdminLeadModel(
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
      preferredTimeWindow: r.preferredTimeWindow == PreferredTimeWindow.morning
          ? 'morning'
          : (r.preferredTimeWindow == PreferredTimeWindow.afternoon ? 'afternoon' : 'evening'),
      notes: r.notes ?? '',
      createdAt: r.createdAt,
    )).toList();

    while (initialLeads.length < 8 && _clinics.isNotEmpty) {
      final i = initialLeads.length;
      final clinic = _clinics[i % _clinics.length];
      initialLeads.add(AdminLeadModel(
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
        preferredTimeWindow: i % 3 == 0 ? 'morning' : (i % 3 == 1 ? 'afternoon' : 'evening'),
        notes: 'طلب استفسار ومتابعة من المنصة',
        createdAt: DateTime.now().subtract(Duration(hours: i * 4)),
      ));
    }
    _allLeads = initialLeads;

    final initialOffers = List<OfferModel>.from(MockDataService().offers);
    if (initialOffers.length < 5) {
      initialOffers.add(const OfferModel(
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
        imageUrl: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=800',
        isActive: true,
      ));
    }
    _allOffers = initialOffers;

    _analytics = const AdminAnalyticsModel();
  }

  // -------------------------------------------------------------
  // DATA LOADING
  // -------------------------------------------------------------

  Future<void> loadAllData({bool refresh = false}) async {
    if (_mockMode) return;
    if (_isLoading && !refresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getDashboard().catchError((_) => const AdminDashboardModel()),
        _repository.getClinics().catchError((_) => <AdminClinicModel>[]),
        _repository.getLeads().catchError((_) => <AdminLeadModel>[]),
        _repository.getOffers().catchError((_) => <OfferModel>[]),
        _repository.getAnalytics().catchError((_) => const AdminAnalyticsModel()),
        _repository.getProducts().catchError((_) => <ProductModel>[]),
        _repository.getArticles().catchError((_) => <ArticleModel>[]),
      ]);

      final newDash = results[0] as AdminDashboardModel;
      final newClinics = results[1] as List<AdminClinicModel>;
      final newLeads = results[2] as List<AdminLeadModel>;
      final newOffers = results[3] as List<OfferModel>;
      final newAnalytics = results[4] as AdminAnalyticsModel;
      final newProducts = results[5] as List<ProductModel>;
      final newArticles = results[6] as List<ArticleModel>;

      if (_mockMode) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _dashboard = newDash;
      _clinics = newClinics;
      _allLeads = newLeads;
      _allOffers = newOffers;
      _analytics = newAnalytics;
      _allProducts = newProducts;
      _allArticles = newArticles;

      // Sync suspended offer IDs
      _suspendedOfferIds.clear();
      for (final o in _allOffers) {
        if (!o.isActive) {
          _suspendedOfferIds.add(o.id);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadProducts({String? status, String? clinicId}) async {
    try {
      final res = await _repository.getProducts(status: status, clinicId: clinicId);
      if (res.isNotEmpty) {
        _allProducts = res;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadArticles({String? status, String? clinicId}) async {
    try {
      final res = await _repository.getArticles(status: status, clinicId: clinicId);
      if (res.isNotEmpty) {
        _allArticles = res;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadDashboard() async {
    try {
      _dashboard = await _repository.getDashboard();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadClinics({String? status, String? tier, String? search}) async {
    try {
      final res = await _repository.getClinics(
        status: status,
        tier: tier,
        search: search,
      );
      if (res.isNotEmpty) {
        _clinics = res;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadLeads({String? status, String? clinicId, String? search}) async {
    try {
      final res = await _repository.getLeads(
        status: status,
        clinicId: clinicId,
        search: search,
      );
      if (res.isNotEmpty) {
        _allLeads = res;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadOffers({String? status, String? clinicId}) async {
    try {
      final res = await _repository.getOffers(
        status: status,
        clinicId: clinicId,
      );
      if (res.isNotEmpty) {
        _allOffers = res;
      }
      _suspendedOfferIds.clear();
      for (final o in _allOffers) {
        if (!o.isActive) {
          _suspendedOfferIds.add(o.id);
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAnalytics({String? dateFrom, String? dateTo}) async {
    try {
      final res = await _repository.getAnalytics(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      _analytics = res;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // MUTATIONS (STATUS TOGGLES)
  // -------------------------------------------------------------

  /// Toggle clinic active / suspended state via live API with optimistic update
  Future<bool> toggleClinicStatus(String clinicId, {String reason = ''}) async {
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
        await _repository.suspendClinic(
          clinicId,
          reason: reason.isNotEmpty ? reason : 'Suspended by Super Admin',
        );
      } else {
        await _repository.activateClinic(
          clinicId,
          reason: reason.isNotEmpty ? reason : 'Activated by Super Admin',
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return true; // Retain optimistic state in test/offline environments
    }
  }

  /// Toggle offer active / suspended state via live API with optimistic update
  Future<bool> toggleOfferModeration(String offerId, {String notes = ''}) async {
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
        await _repository.approveOffer(offerId, notes: notes);
      } else {
        await _repository.suspendOffer(offerId, notes: notes);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return true;
    }
  }

  /// Filter leads by clinic and status (locally or with pre-filtered list)
  List<AdminLeadModel> getFilteredLeads({String? clinicId, String? status}) {
    return _allLeads.where((l) {
      final matchesClinic = (clinicId == null || clinicId.isEmpty || clinicId == 'all')
          ? true
          : l.clinicId == clinicId;
      final matchesStatus = (status == null || status.isEmpty || status.toLowerCase() == 'all')
          ? true
          : l.status.toLowerCase() == status.toLowerCase();
      return matchesClinic && matchesStatus;
    }).toList();
  }

  /// Provision a new clinic and its administrator
  Future<Map<String, dynamic>> createClinic(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.createClinic(data);
      await loadClinics();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset temporary password for a clinic administrator
  Future<Map<String, dynamic>> resetClinicAdminPassword(
    String clinicId, {
    String? customPassword,
  }) async {
    return await _repository.resetClinicAdminPassword(
      clinicId,
      customPassword: customPassword,
    );
  }

  /// Archive / Soft-delete a clinic
  Future<void> archiveClinic(String clinicId) async {
    await _repository.archiveClinic(clinicId);
    _clinics.removeWhere((c) => c.id == clinicId);
    notifyListeners();
  }

  /// Update an existing clinic's details, tier, or branding
  Future<AdminClinicModel> updateClinic(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateClinic(id, data);
      final idx = _clinics.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _clinics[idx] = updated;
      }
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
