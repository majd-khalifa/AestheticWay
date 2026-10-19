import 'dart:collection';
import '../../../core/data/single_flight.dart';
import '../../../core/data/paged_collection.dart';
import '../../../core/auth/session_changed_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/treatments/models/category_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import '../data/clinic_leads_repository.dart';
import '../data/clinic_catalog_repository.dart';
import '../data/models/clinic_dashboard_model.dart';
import '../data/models/clinic_badge_counts_model.dart';
import '../data/models/clinic_setup_checklist_model.dart';

/// Clinic Portal Service managing State, Leads, and Catalog for the Logged-in Clinic Partner
class ClinicPortalService extends ChangeNotifier {
  static final ClinicPortalService _instance = ClinicPortalService._internal();
  factory ClinicPortalService() => _instance;
  ClinicPortalService._internal() {
    _initializeDefaultActiveClinic();
  }

  ClinicLeadsRepository _repository = ClinicLeadsRepository();
  ClinicCatalogRepository _catalogRepository = ClinicCatalogRepository();

  bool _mockMode = false;

  late ClinicModel _activeClinic;
  final List<AppointmentRequestModel> _clinicLeads = [];
  final Map<String, String> _internalNotes = {};
  ClinicDashboardModel? _dashboardData;
  ClinicBadgeCountsModel? _badgeCounts;
  bool _isLoading = false;
  String? _errorMessage;

  final List<OfferModel> _clinicOffers = [];
  final List<PractitionerModel> _clinicPractitioners = [];
  final List<TreatmentModel> _clinicTreatments = [];
  final List<CategoryModel> _categories = [];
  final List<ProductModel> _clinicProducts = [];
  final List<ArticleModel> _clinicArticles = [];
  final List<ClinicBranch> _clinicBranches = [];
  ClinicSetupChecklistModel? _setupChecklist;

  ClinicModel get activeClinic => _activeClinic;
  List<AppointmentRequestModel> get clinicLeads =>
      UnmodifiableListView(_clinicLeads);
  ClinicDashboardModel? get dashboardData => _dashboardData;
  ClinicBadgeCountsModel? get badgeCounts => _badgeCounts;
  ClinicSetupChecklistModel? get setupChecklist => _setupChecklist;
  bool get isLoading =>
      _isLoading || _pages.values.any((page) => page.isLoading);
  String? get errorMessage =>
      _errorMessage ??
      _pages.values.map((page) => page.error).whereType<String>().firstOrNull;

  List<OfferModel> get clinicOffers => UnmodifiableListView(_clinicOffers);
  List<PractitionerModel> get clinicPractitioners =>
      UnmodifiableListView(_clinicPractitioners);
  List<TreatmentModel> get clinicTreatments =>
      UnmodifiableListView(_clinicTreatments);
  List<CategoryModel> get categories => UnmodifiableListView(_categories);
  List<ProductModel> get clinicProducts =>
      UnmodifiableListView(_clinicProducts);
  List<ArticleModel> get clinicArticles =>
      UnmodifiableListView(_clinicArticles);
  List<ClinicBranch> get clinicBranches =>
      UnmodifiableListView(_clinicBranches);

  Future<List<CategoryModel>> getOrFetchCategories() async {
    await loadCollection('categories');
    return UnmodifiableListView(_categories);
  }

  void _initializeDefaultActiveClinic() {
    _activeClinic = const ClinicModel(
      id: '',
      nameAr: '',
      nameEn: '',
      descriptionAr: '',
      descriptionEn: '',
      coverImageUrl: '',
      galleryImages: [],
      logoUrl: '',
      rating: 0.0,
      reviewCount: 0,
      subscriptionTier: SubscriptionTier.basic,
      city: '',
      areaAr: '',
      areaEn: '',
      addressAr: '',
      addressEn: '',
    );
  }

  @visibleForTesting
  void enableMockMode({
    List<AppointmentRequestModel>? testLeads,
    ClinicDashboardModel? testDashboard,
    ClinicModel? testClinic,
    ClinicSetupChecklistModel? testChecklist,
  }) {
    _mockMode = true;
    if (_clinicLeads.isEmpty &&
        _clinicOffers.isEmpty &&
        _clinicPractitioners.isEmpty) {
      _initializeFallbackData();
    }
    if (testLeads != null) {
      _clinicLeads.clear();
      _clinicLeads.addAll(testLeads);
    }
    if (testDashboard != null) {
      _dashboardData = testDashboard;
    }
    if (testClinic != null) {
      _activeClinic = testClinic;
    }
    if (testChecklist != null) {
      _setupChecklist = testChecklist;
    }
    notifyListeners();
  }

  @visibleForTesting
  void setActiveClinicForTesting(ClinicModel clinic) {
    _activeClinic = clinic;
    notifyListeners();
  }

  @visibleForTesting
  void setRepositoryForTesting(ClinicLeadsRepository repository) {
    _repository = repository;
  }

  @visibleForTesting
  void setCatalogRepositoryForTesting(ClinicCatalogRepository repository) {
    _catalogRepository = repository;
  }

  final Map<String, PagedCollection<dynamic>> _pages = {};
  final SingleFlight _flights = SingleFlight();
  bool _overviewLoaded = false;
  final _noteDirectoryLeadIds = <String>{};

  PagedCollection<dynamic> collection(String key) {
    final result = _pages.putIfAbsent(key, () {
      final PagedCollection<dynamic> page = switch (key) {
        'leads' => PagedCollection<AppointmentRequestModel>(
          items: _clinicLeads,
          loader: (page, q) => _repository.getLeads(
            page: page,
            pageSize: 20,
            status: q['status'] as String?,
            search: q['search'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'practitioners' => PagedCollection<PractitionerModel>(
          items: _clinicPractitioners,
          loader: (page, q) => _catalogRepository.getPractitioners(
            page: page,
            search: q['search'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'treatments' => PagedCollection<TreatmentModel>(
          items: _clinicTreatments,
          loader: (page, q) => _catalogRepository.getTreatments(
            page: page,
            category: q['category'] as String?,
            search: q['search'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'offers' => PagedCollection<OfferModel>(
          items: _clinicOffers,
          loader: (page, q) => _catalogRepository.getOffers(
            page: page,
            search: q['search'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'products' => PagedCollection<ProductModel>(
          items: _clinicProducts,
          loader: (page, q) => _catalogRepository.getProducts(
            page: page,
            search: q['search'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'articles' => PagedCollection<ArticleModel>(
          items: _clinicArticles,
          loader: (page, q) => _catalogRepository.getArticles(
            page: page,
            search: q['search'] as String?,
          ),
          keyOf: (item) => item.id,
        ),
        'categories' => PagedCollection<CategoryModel>(
          items: _categories,
          loader: (page, q) => _catalogRepository.getCategories(page: page),
          keyOf: (item) => item.id,
        ),
        'branches' => PagedCollection<ClinicBranch>(
          items: _clinicBranches,
          loader: (page, q) => _catalogRepository.getBranches(page: page),
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

  final ValueNotifier<int> navigationBadge = ValueNotifier<int>(0);
  @override
  void notifyListeners() {
    if (navigationBadge.value != newLeadsCount) {
      navigationBadge.value = newLeadsCount;
    }
    super.notifyListeners();
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
    _noteDirectoryLeadIds.clear();
    _mockMode = false;
    _isLoading = false;
    _errorMessage = null;
    _internalNotes.clear();
    _dashboardData = null;
    _badgeCounts = null;
    _clinicLeads.clear();
    _clinicOffers.clear();
    _clinicPractitioners.clear();
    _clinicTreatments.clear();
    _categories.clear();
    _clinicProducts.clear();
    _clinicArticles.clear();
    _clinicBranches.clear();
    _setupChecklist = null;
    _initializeDefaultActiveClinic();
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

  int get newLeadsCount =>
      _badgeCounts?.unreadRequests ??
      _dashboardData?.newLeads ??
      _clinicLeads.where((l) => l.status == AppointmentLeadStatus.sent).length;

  int get contactedLeadsCount =>
      _badgeCounts?.contactedRequests ??
      _dashboardData?.contactedLeads ??
      _clinicLeads
          .where((l) => l.status == AppointmentLeadStatus.contacted)
          .length;

  int get closedLeadsCount =>
      _badgeCounts?.closedRequests ??
      _dashboardData?.closedLeads ??
      _clinicLeads
          .where((l) => l.status == AppointmentLeadStatus.closed)
          .length;

  int get totalLeadsCount =>
      _badgeCounts?.totalRequests ??
      _dashboardData?.totalLeads ??
      (_pages['leads']?.total ?? _clinicLeads.length);

  int get activeOffersCount =>
      (_mockMode ? null : _dashboardData?.activeOffersCount) ??
      _clinicOffers.where((o) => o.isActive && o.status == 'active').length;

  int get activePractitionersCount =>
      (_mockMode ? null : _dashboardData?.activePractitionersCount) ??
      _clinicPractitioners.where((p) => p.status == 'active').length;

  int get activeTreatmentsCount =>
      (_mockMode ? null : _dashboardData?.activeTreatmentsCount) ??
      _clinicTreatments.length;

  int get activeProductsCount =>
      (_mockMode ? null : _dashboardData?.activeProductsCount) ??
      _clinicProducts.where((p) => p.isAvailable).length;

  int get activeArticlesCount =>
      (_mockMode ? null : _dashboardData?.publishedArticlesCount) ??
      _clinicArticles.length;

  String getInternalNotes(String leadId) {
    if (_internalNotes.containsKey(leadId)) {
      return _internalNotes[leadId]!;
    }
    final lead = _clinicLeads.firstWhere(
      (l) => l.id == leadId,
      orElse: () => AppointmentRequestModel(
        id: '',
        referenceCode: '',
        clinicId: '',
        clinicNameAr: '',
        branchNameAr: '',
        serviceNameAr: '',
        preferredDate: DateTime.now(),
        preferredTimeWindow: PreferredTimeWindow.morning,
        patientFullName: '',
        patientPhone: '',
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now(),
      ),
    );
    if (lead.internalNotes.isNotEmpty) {
      return lead.internalNotes.first.note;
    }
    return '';
  }

  /// Fetch live leads and dashboard statistics from backend API
  Future<List<ClinicInternalNote>> getLeadNotesPage(
    AppointmentRequestModel lead,
    int page,
  ) async {
    if (_mockMode) {
      return PageItems(
        lead.internalNotes
            .skip((page - 1) * catalogPageSize)
            .take(catalogPageSize),
        hasMore: page * catalogPageSize < lead.internalNotes.length,
        total: lead.internalNotes.length,
      );
    }
    final epoch = _sessionEpoch;
    if (lead.hasNotesDirectory || _noteDirectoryLeadIds.contains(lead.id)) {
      return _inSession(_repository.getLeadNotes(lead.id, page: page), epoch);
    }
    final detail = await _inSession(_repository.getLeadDetail(lead.id), epoch);
    if (detail.hasNotesDirectory) {
      _noteDirectoryLeadIds.add(lead.id);
      return _inSession(_repository.getLeadNotes(lead.id, page: page), epoch);
    }
    final notes = detail.internalNotes;
    return PageItems(
      notes.skip((page - 1) * catalogPageSize).take(catalogPageSize),
      hasMore: page * catalogPageSize < notes.length,
      total: notes.length,
    );
  }

  Future<void> loadPortalData({
    bool refresh = false,
    String? status,
    String? search,
  }) {
    if (_mockMode) return Future.value();
    if (status != null || search != null) {
      return loadCollection(
        'leads',
        refresh: true,
        query: {'status': status, 'search': search},
      );
    }
    if (_overviewLoaded && !refresh) return Future.value();
    return _flights.run('overview', () => _fetchOverview(refresh));
  }

  Future<void> _fetchOverview(bool refresh) async {
    final epoch = _sessionEpoch;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final values = await _inSession(
        Future.wait([
          _repository.getDashboard(),
          loadCollection('leads', refresh: refresh),
          _catalogRepository.getClinicProfile(),
          loadSetupChecklist(),
        ]),
        epoch,
      );
      _dashboardData = values[0] as ClinicDashboardModel;
      _activeClinic = values[2] as ClinicModel;
      final dashboard = _dashboardData!;
      _badgeCounts = ClinicBadgeCountsModel(
        newRequests: dashboard.newLeads,
        unreadRequests: dashboard.newLeads,
        contactedRequests: dashboard.contactedLeads,
        closedRequests: dashboard.closedLeads,
        totalRequests: dashboard.totalLeads,
      );
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

  /// Refresh lightweight clinic unread badge counters without refetching all lead records
  Future<void> refreshBadgeCounts() async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) return;
    try {
      _badgeCounts = await _inSession(
        _repository.getBadgeCounts(),
        sessionEpoch,
      );
      notifyListeners();
    } catch (_) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
    }
  }

  /// Fetch live catalog data (practitioners, treatments, offers, categories, products, articles)
  Future<void> loadCatalogData({bool refresh = false}) {
    if (_mockMode) return Future.value();
    return _flights.run(
      'all',
      () => Future.wait([
        for (final key in [
          'practitioners',
          'treatments',
          'offers',
          'categories',
          'products',
          'articles',
        ])
          loadCollection(key, refresh: refresh),
      ]).then((_) {}),
    );
  }

  ArticleModel _enrichArticleAuthor(ArticleModel article) {
    if (article.authorDoctorId.isNotEmpty &&
        article.authorDoctorNameEn.isEmpty &&
        article.authorDoctorNameAr.isEmpty) {
      final idx = _clinicPractitioners.indexWhere(
        (p) => p.id == article.authorDoctorId,
      );
      if (idx != -1) {
        final doc = _clinicPractitioners[idx];
        return article.copyWith(
          authorDoctorNameAr: doc.nameAr,
          authorDoctorNameEn: doc.nameEn,
          authorDoctorSpecialtyAr: doc.specialtyAr,
          authorDoctorSpecialtyEn: doc.specialtyEn,
          authorDoctorAvatar: doc.avatarUrl,
        );
      }
    }
    return article;
  }

  /// Reload leads only (for search or tab filter changes)
  Future<void> filterLeads({String? status, String? search}) => loadCollection(
    'leads',
    refresh: true,
    query: {'status': status, 'search': search},
  );

  void _initializeFallbackData() {
    final mock = MockDataService();
    // Default active clinic placeholder
    _activeClinic = mock.clinics.firstWhere(
      (c) => c.id == 'kaya-jumeirah',
      orElse: () => mock.clinics.first,
    );

    // Initial fallback leads for offline preview & test safety
    _clinicLeads.clear();
    _clinicLeads.addAll([
      AppointmentRequestModel(
        id: 'cl-lead-101',
        referenceCode: '#REQ-99012',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Flagship',
        serviceNameAr: 'الهيدرافيسيال الملكي الطبي 7 مراحل',
        serviceNameEn: 'Royal HydraFacial',
        practitionerNameAr: 'د. سارة المنصوري',
        practitionerNameEn: 'Dr. Sara Al Mansoori',
        practitionerType: PractitionerType.doctor,
        preferredDate: DateTime.now().add(const Duration(days: 1)),
        preferredTimeWindow: PreferredTimeWindow.morning,
        patientFullName: 'مريم خليفة المهيري',
        patientPhone: '+971 50 123 4567',
        notes: 'بشرة حساسة ولدي استفسار عن نوع السيروم المستخدم.',
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      AppointmentRequestModel(
        id: 'cl-lead-102',
        referenceCode: '#REQ-99013',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Flagship',
        serviceNameAr: 'بوتوكس تجاعيد الجبهة ومحيط العين',
        serviceNameEn: 'Botox Anti-Aging Treatment',
        practitionerNameAr: 'د. أحمد الكعبي',
        practitionerNameEn: 'Dr. Ahmed Al Kaabi',
        practitionerType: PractitionerType.doctor,
        preferredDate: DateTime.now().add(const Duration(days: 2)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        patientFullName: 'فاطمة الهاشمي',
        patientPhone: '+971 55 987 6543',
        notes: 'الاستفسار عن عدد الوحدات المناسبة للجبهة.',
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      AppointmentRequestModel(
        id: 'cl-lead-103',
        referenceCode: '#REQ-99014',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Flagship',
        serviceNameAr: 'ليزر كانديلا لإزالة الشعر - جسم كامل',
        serviceNameEn: 'Candela GentleLase Full Body',
        practitionerNameAr: 'أ. ليلى حسن',
        practitionerNameEn: 'Layla Hassan',
        practitionerType: PractitionerType.nurse,
        preferredDate: DateTime.now().add(const Duration(days: 1)),
        preferredTimeWindow: PreferredTimeWindow.morning,
        patientFullName: 'عائشة الشامسي',
        patientPhone: '+971 52 445 6677',
        notes: 'يرجى التأكد من توفر جلسة تجريبية للبشرة.',
        consentAccepted: true,
        status: AppointmentLeadStatus.contacted,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppointmentRequestModel(
        id: 'cl-lead-104',
        referenceCode: '#REQ-99015',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Flagship',
        serviceNameAr: 'بروفايلو لشد ونضارة الوجه والرقبة',
        serviceNameEn: 'Profhilo Bio-Remodelling',
        practitionerNameAr: 'د. سارة المنصوري',
        practitionerNameEn: 'Dr. Sara Al Mansoori',
        practitionerType: PractitionerType.doctor,
        preferredDate: DateTime.now().add(const Duration(days: 3)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        patientFullName: 'شيخة المزروعي',
        patientPhone: '+971 54 332 1100',
        notes: 'موعد مسائي مناسب بعد الساعة الخامسة.',
        consentAccepted: true,
        status: AppointmentLeadStatus.contacted,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      ),
      AppointmentRequestModel(
        id: 'cl-lead-105',
        referenceCode: '#REQ-99016',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Flagship',
        serviceNameAr: 'فيلر الشفاه الروسي الطبيعي',
        serviceNameEn: 'Russian Lip Filler',
        practitionerNameAr: 'د. ريم الخالد',
        practitionerNameEn: 'Dr. Reem Al Khaled',
        practitionerType: PractitionerType.doctor,
        preferredDate: DateTime.now().add(const Duration(days: 5)),
        preferredTimeWindow: PreferredTimeWindow.morning,
        patientFullName: 'نورة القاسمي',
        patientPhone: '+971 56 778 9900',
        notes: 'تفضل التواصل عبر الواتساب أولاً.',
        consentAccepted: true,
        status: AppointmentLeadStatus.contacted,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      AppointmentRequestModel(
        id: 'cl-lead-106',
        referenceCode: '#REQ-88917',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Flagship',
        serviceNameAr: 'الهيدرافيسيال الملكي الطبي 7 مراحل',
        serviceNameEn: 'Royal HydraFacial',
        practitionerNameAr: 'أ. نور الهدى صالح',
        practitionerNameEn: 'Nour El Houda Saleh',
        practitionerType: PractitionerType.nurse,
        preferredDate: DateTime.now().subtract(const Duration(days: 3)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        patientFullName: 'ياسمين كمال',
        patientPhone: '+971 50 998 8776',
        notes: 'تمت الزيارة والاستشارة بنجاح.',
        consentAccepted: true,
        status: AppointmentLeadStatus.closed,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);

    _internalNotes['cl-lead-103'] =
        'تم الاتصال بالعميل وإرسال تفاصيل الجلسة عبر الواتساب.';
    _internalNotes['cl-lead-104'] =
        'تم التنسيق لتأكيد موعد استشارة يوم الخميس.';
    _internalNotes['cl-lead-106'] = 'تم حضور الاستشارة بنجاح في فرع جميرا.';

    // Populate catalog placeholders for offline fallback
    _clinicOffers.clear();
    _clinicOffers.addAll(
      mock.offers.where(
        (o) => o.clinicId == _activeClinic.id || o.clinicId == 'kaya-jumeirah',
      ),
    );
    if (_clinicOffers.isEmpty && mock.offers.isNotEmpty) {
      _clinicOffers.add(mock.offers.first);
    }

    _clinicPractitioners.clear();
    _clinicPractitioners.addAll(
      mock.getPractitionersForClinic(_activeClinic.id),
    );
    if (_clinicPractitioners.isEmpty && mock.practitioners.isNotEmpty) {
      _clinicPractitioners.addAll(mock.practitioners.take(2));
    }

    _clinicTreatments.clear();
    _clinicTreatments.addAll(
      mock.treatments.where((t) => _activeClinic.treatmentIds.contains(t.id)),
    );
    if (_clinicTreatments.isEmpty && mock.treatments.isNotEmpty) {
      _clinicTreatments.addAll(mock.treatments.take(4));
    }

    _clinicProducts.clear();
    _clinicProducts.addAll(mock.getProductsForClinic(_activeClinic.id));
    if (_clinicProducts.isEmpty && mock.products.isNotEmpty) {
      _clinicProducts.addAll(mock.products.take(2));
    }

    _clinicArticles.clear();
    _clinicArticles.addAll(mock.getArticlesForClinic(_activeClinic.id));
    if (_clinicArticles.isEmpty && mock.articles.isNotEmpty) {
      _clinicArticles.addAll(mock.articles.take(2));
    }

    _dashboardData = ClinicDashboardModel(
      clinicId: _activeClinic.id,
      clinicName: _activeClinic.nameAr,
      totalLeads: _clinicLeads.length,
      newLeads: _clinicLeads
          .where((l) => l.status == AppointmentLeadStatus.sent)
          .length,
      contactedLeads: _clinicLeads
          .where((l) => l.status == AppointmentLeadStatus.contacted)
          .length,
      closedLeads: _clinicLeads
          .where((l) => l.status == AppointmentLeadStatus.closed)
          .length,
      conversionRate: 25.0,
      whatsappTaps: 12,
      callTaps: 8,
      mapsTaps: 5,
      profileViews: 45,
      activePractitionersCount: _clinicPractitioners.length,
      activeTreatmentsCount: _clinicTreatments.length,
      activeOffersCount: _clinicOffers.length,
      activeProductsCount: _clinicProducts.length,
      publishedArticlesCount: _clinicArticles.length,
    );
  }

  /// Update the status of a consultation lead with live PATCH to backend API
  Future<void> updateLeadStatus(
    String leadId,
    AppointmentLeadStatus newStatus,
  ) async {
    final sessionEpoch = _sessionEpoch;
    final index = _clinicLeads.indexWhere((l) => l.id == leadId);
    if (index == -1) return;
    final old = _clinicLeads[index];

    // Optimistic UI update
    _clinicLeads[index] = old.copyWith(status: newStatus);
    notifyListeners();

    if (_mockMode) {
      return;
    }

    try {
      final updated = await _inSession(
        _repository.updateLeadStatus(leadId, newStatus, existingLead: old),
        sessionEpoch,
      );
      final currentIndex = _clinicLeads.indexWhere((lead) => lead.id == leadId);
      if (currentIndex == -1) return;
      _clinicLeads[currentIndex] = updated;

      // Silently refresh dashboard metrics in background
      _repository
          .getDashboard()
          .then((d) {
            if (sessionEpoch != _sessionEpoch) return;
            _dashboardData = d;
            notifyListeners();
          })
          .catchError((_) {});

      notifyListeners();
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      // Rollback on failure
      final currentIndex = _clinicLeads.indexWhere((lead) => lead.id == leadId);
      if (currentIndex != -1) _clinicLeads[currentIndex] = old;
      notifyListeners();
      rethrow;
    }
  }

  /// Save internal notes for a lead with live POST to backend API
  Future<void> saveInternalNotes(String leadId, String notes) async {
    final sessionEpoch = _sessionEpoch;
    _internalNotes[leadId] = notes;
    notifyListeners();

    if (_mockMode) {
      return;
    }

    try {
      final createdNote = await _inSession(
        _repository.addLeadNote(leadId, notes),
        sessionEpoch,
      );
      final index = _clinicLeads.indexWhere((l) => l.id == leadId);
      if (index != -1) {
        final lead = _clinicLeads[index];
        _clinicLeads[index] = lead.copyWith(
          internalNotes: [createdNote, ...lead.internalNotes],
        );
        notifyListeners();
      }
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      rethrow;
    }
  }

  // -------------------------------------------------------------
  // OFFERS CRUD (Live API)
  // -------------------------------------------------------------

  void addOffer(OfferModel offer) {
    _clinicOffers.insert(0, offer);
    notifyListeners();
  }

  Future<OfferModel> createOffer(Map<String, dynamic> data) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final o = OfferModel.fromJson(data);
      _clinicOffers.insert(0, o);
      notifyListeners();
      return o;
    }
    final created = await _inSession(
      _catalogRepository.createOffer(data),
      sessionEpoch,
    );
    _clinicOffers.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<OfferModel> updateOffer(String id, Map<String, dynamic> data) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final idx = _clinicOffers.indexWhere((o) => o.id == id);
      if (idx != -1) {
        final o = _clinicOffers[idx];
        final updated = o.copyWith(
          titleEn: data['title_en'],
          titleAr: data['title_ar'],
          originalPrice: double.tryParse(
            data['original_price']?.toString() ?? '',
          ),
          offerPrice: double.tryParse(data['offer_price']?.toString() ?? ''),
          status: data['status'],
          isActive: data['is_active'],
        );
        _clinicOffers[idx] = updated;
        notifyListeners();
        return updated;
      }
    }
    final updated = await _inSession(
      _catalogRepository.updateOffer(id, data),
      sessionEpoch,
    );
    final idx = _clinicOffers.indexWhere((o) => o.id == id);
    if (idx != -1) {
      _clinicOffers[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> toggleOfferStatus(String offerId) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _clinicOffers.indexWhere((o) => o.id == offerId);
    if (idx == -1) return;
    final current = _clinicOffers[idx];
    final nextStatus = current.status == 'active' ? 'suspended' : 'active';
    _clinicOffers[idx] = current.copyWith(
      status: nextStatus,
      isActive: nextStatus == 'active',
    );
    notifyListeners();

    if (_mockMode) return;

    try {
      final updated = await _inSession(
        _catalogRepository.updateOfferStatus(offerId, nextStatus),
        sessionEpoch,
      );
      _clinicOffers[idx] = updated;
      notifyListeners();
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      _clinicOffers[idx] = current;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteOffer(String offerId) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _clinicOffers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      final removed = _clinicOffers.removeAt(idx);
      notifyListeners();
      if (_mockMode) return;
      try {
        await _inSession(_catalogRepository.deleteOffer(offerId), sessionEpoch);
      } catch (e) {
        if (sessionEpoch != _sessionEpoch) {
          return;
        }
        _clinicOffers.insert(idx, removed);
        notifyListeners();
        rethrow;
      }
    }
  }

  // -------------------------------------------------------------
  // PRACTITIONERS CRUD (Live API)
  // -------------------------------------------------------------

  void addPractitioner(PractitionerModel practitioner) {
    _clinicPractitioners.add(practitioner);
    notifyListeners();
  }

  Future<PractitionerModel> createPractitioner(
    Map<String, dynamic> data,
  ) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final p = PractitionerModel.fromJson(data);
      _clinicPractitioners.add(p);
      notifyListeners();
      return p;
    }
    final created = await _inSession(
      _catalogRepository.createPractitioner(data),
      sessionEpoch,
    );
    _clinicPractitioners.add(created);
    notifyListeners();
    return created;
  }

  Future<PractitionerModel> updatePractitioner(
    String id,
    Map<String, dynamic> data,
  ) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final idx = _clinicPractitioners.indexWhere((p) => p.id == id);
      if (idx != -1) {
        final p = _clinicPractitioners[idx];
        final updated = p.copyWith(
          nameEn: data['name_en'],
          nameAr: data['name_ar'],
          specialtyEn: data['speciality_en'],
          specialtyAr: data['speciality_ar'],
          licenseAuthority: data['license_authority'],
          licenseNumber: data['license_number'],
          status: data['status'],
        );
        _clinicPractitioners[idx] = updated;
        notifyListeners();
        return updated;
      }
    }
    final updated = await _inSession(
      _catalogRepository.updatePractitioner(id, data),
      sessionEpoch,
    );
    final idx = _clinicPractitioners.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _clinicPractitioners[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> deletePractitioner(String id) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _clinicPractitioners.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final removed = _clinicPractitioners.removeAt(idx);
      notifyListeners();
      if (_mockMode) return;
      try {
        await _inSession(
          _catalogRepository.deletePractitioner(id),
          sessionEpoch,
        );
      } catch (e) {
        if (sessionEpoch != _sessionEpoch) {
          return;
        }
        _clinicPractitioners.insert(idx, removed);
        notifyListeners();
        rethrow;
      }
    }
  }

  // -------------------------------------------------------------
  // TREATMENTS CRUD (Live API)
  // -------------------------------------------------------------

  void addTreatment(TreatmentModel treatment) {
    _clinicTreatments.add(treatment);
    notifyListeners();
  }

  Future<TreatmentModel> createTreatment(Map<String, dynamic> data) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final t = TreatmentModel.fromJson(data);
      _clinicTreatments.add(t);
      notifyListeners();
      return t;
    }
    final created = await _inSession(
      _catalogRepository.createTreatment(data),
      sessionEpoch,
    );
    _clinicTreatments.add(created);
    notifyListeners();
    return created;
  }

  Future<TreatmentModel> updateTreatment(
    String id,
    Map<String, dynamic> data,
  ) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final idx = _clinicTreatments.indexWhere((t) => t.id == id);
      if (idx != -1) {
        final t = _clinicTreatments[idx];
        final updated = t.copyWith(
          nameEn: data['name_en'],
          nameAr: data['name_ar'],
          descriptionEn: data['description_en'],
          descriptionAr: data['description_ar'],
          price: double.tryParse(data['price']?.toString() ?? ''),
          status: data['status'],
          isActive: data['is_active'],
        );
        _clinicTreatments[idx] = updated;
        notifyListeners();
        return updated;
      }
    }
    final updated = await _inSession(
      _catalogRepository.updateTreatment(id, data),
      sessionEpoch,
    );
    final idx = _clinicTreatments.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _clinicTreatments[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> deleteTreatment(String id) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _clinicTreatments.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final removed = _clinicTreatments.removeAt(idx);
      notifyListeners();
      if (_mockMode) return;
      try {
        await _inSession(_catalogRepository.deleteTreatment(id), sessionEpoch);
      } catch (e) {
        if (sessionEpoch != _sessionEpoch) {
          return;
        }
        _clinicTreatments.insert(idx, removed);
        notifyListeners();
        rethrow;
      }
    }
  }

  // -------------------------------------------------------------
  // PRODUCTS CRUD (Live API)
  // -------------------------------------------------------------

  void addProduct(ProductModel product) {
    _clinicProducts.insert(0, product);
    notifyListeners();
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final p = ProductModel.fromJson(data);
      _clinicProducts.insert(0, p);
      notifyListeners();
      return p;
    }
    final created = await _inSession(
      _catalogRepository.createProduct(data),
      sessionEpoch,
    );
    _clinicProducts.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<ProductModel> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final idx = _clinicProducts.indexWhere((p) => p.id == id);
      if (idx != -1) {
        final p = _clinicProducts[idx];
        final updated = p.copyWith(
          nameEn: data['name_en'] as String? ?? p.nameEn,
          nameAr: data['name_ar'] as String? ?? p.nameAr,
          descriptionEn: data['description_en'] as String? ?? p.descriptionEn,
          descriptionAr: data['description_ar'] as String? ?? p.descriptionAr,
          price: data['price'] != null
              ? (double.tryParse(data['price'].toString()) ?? p.price)
              : p.price,
          imageUrl: data['image'] as String? ?? p.imageUrl,
          isAvailable: data['is_active'] as bool? ?? p.isAvailable,
          status: data['status'] as String? ?? p.status,
          brandNameEn: data['brand_name_en'] as String? ?? p.brandNameEn,
          brandNameAr: data['brand_name_ar'] as String? ?? p.brandNameAr,
          sponsorCompany:
              data['sponsor_company'] as String? ?? p.sponsorCompany,
        );
        _clinicProducts[idx] = updated;
        notifyListeners();
        return updated;
      }
    }
    final updated = await _inSession(
      _catalogRepository.updateProduct(id, data),
      sessionEpoch,
    );
    final idx = _clinicProducts.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _clinicProducts[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> toggleProductAvailability(String productId) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _clinicProducts.indexWhere((p) => p.id == productId);
    if (idx == -1) return;
    final current = _clinicProducts[idx];
    final nextActive = !current.isAvailable;
    _clinicProducts[idx] = current.copyWith(isAvailable: nextActive);
    notifyListeners();

    if (_mockMode || productId.startsWith('test-')) return;

    try {
      final updated = await _inSession(
        _catalogRepository.updateProduct(productId, {'is_active': nextActive}),
        sessionEpoch,
      );
      _clinicProducts[idx] = updated;
      notifyListeners();
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      _clinicProducts[idx] = current;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _clinicProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final removed = _clinicProducts.removeAt(idx);
      notifyListeners();
      if (_mockMode || productId.startsWith('test-')) return;
      try {
        await _inSession(
          _catalogRepository.deleteProduct(productId),
          sessionEpoch,
        );
      } catch (e) {
        if (sessionEpoch != _sessionEpoch) {
          return;
        }
        _clinicProducts.insert(idx, removed);
        notifyListeners();
        rethrow;
      }
    }
  }

  // -------------------------------------------------------------
  // ARTICLES CRUD (Live API)
  // -------------------------------------------------------------

  void addArticle(ArticleModel article) {
    _clinicArticles.insert(0, article);
    notifyListeners();
  }

  Future<ArticleModel> createArticle(Map<String, dynamic> data) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final a = _enrichArticleAuthor(ArticleModel.fromJson(data));
      _clinicArticles.insert(0, a);
      notifyListeners();
      return a;
    }
    final created = _enrichArticleAuthor(
      await _inSession(_catalogRepository.createArticle(data), sessionEpoch),
    );
    _clinicArticles.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<ArticleModel> updateArticle(
    String id,
    Map<String, dynamic> data,
  ) async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      final idx = _clinicArticles.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final a = _clinicArticles[idx];
        final updated = _enrichArticleAuthor(
          a.copyWith(
            titleEn: data['title_en'] as String? ?? a.titleEn,
            titleAr: data['title_ar'] as String? ?? a.titleAr,
            contentEn: data['content_en'] as String? ?? a.contentEn,
            contentAr: data['content_ar'] as String? ?? a.contentAr,
            authorDoctorId: data.containsKey('author_practitioner')
                ? (data['author_practitioner']?.toString() ?? '')
                : a.authorDoctorId,
            coverImageUrl: data['cover_image'] as String? ?? a.coverImageUrl,
            isPublished: data['is_published'] as bool? ?? a.isPublished,
            status: data['status'] as String? ?? a.status,
          ),
        );
        _clinicArticles[idx] = updated;
        notifyListeners();
        return updated;
      }
    }
    final updated = _enrichArticleAuthor(
      await _inSession(
        _catalogRepository.updateArticle(id, data),
        sessionEpoch,
      ),
    );
    final idx = _clinicArticles.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _clinicArticles[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> toggleArticlePublish(String articleId) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _clinicArticles.indexWhere((a) => a.id == articleId);
    if (idx == -1) return;
    final current = _clinicArticles[idx];
    final nextPublished = !current.isPublished;
    _clinicArticles[idx] = current.copyWith(isPublished: nextPublished);
    notifyListeners();

    if (_mockMode || articleId.startsWith('test-')) return;

    try {
      final updated = _enrichArticleAuthor(
        await _inSession(
          _catalogRepository.updateArticle(articleId, {
            'is_published': nextPublished,
          }),
          sessionEpoch,
        ),
      );
      _clinicArticles[idx] = updated;
      notifyListeners();
    } catch (e) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      _clinicArticles[idx] = current;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteArticle(String articleId) async {
    final sessionEpoch = _sessionEpoch;
    final idx = _clinicArticles.indexWhere((a) => a.id == articleId);
    if (idx != -1) {
      final removed = _clinicArticles.removeAt(idx);
      notifyListeners();
      if (_mockMode || articleId.startsWith('test-')) return;
      try {
        await _inSession(
          _catalogRepository.deleteArticle(articleId),
          sessionEpoch,
        );
      } catch (e) {
        if (sessionEpoch != _sessionEpoch) {
          return;
        }
        _clinicArticles.insert(idx, removed);
        notifyListeners();
        rethrow;
      }
    }
  }

  /// Update clinic details via live API (PATCH /api/v1/clinic-portal/profile/)
  Future<void> updateClinicProfile({
    required String nameAr,
    required String nameEn,
    required String descriptionAr,
    required String descriptionEn,
    required String phone,
    required String whatsapp,
    String? addressAr,
    String? addressEn,
    String? googleMapsUrl,
    String? city,
    String? emirate,
    double? latitude,
    double? longitude,
    String? logo,
    String? coverImage,
    bool clearLogo = false,
    bool clearCoverImage = false,
  }) async {
    final sessionEpoch = _sessionEpoch;
    final old = _activeClinic;
    final payload = <String, dynamic>{
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'phone': phone,
      'whatsapp': whatsapp,
      'address_ar': ?addressAr,
      'address_en': ?addressEn,
      'google_maps_url': ?googleMapsUrl,
      'city': ?city,
      'emirate': ?emirate,
      'latitude': ?latitude?.toStringAsFixed(7),
      'longitude': ?longitude?.toStringAsFixed(7),
      if (clearLogo || logo != null) 'logo': clearLogo ? null : logo,
      if (clearCoverImage || coverImage != null)
        'cover_image': clearCoverImage ? null : coverImage,
    };
    final updated = _mockMode
        ? old.copyWith(
            nameAr: nameAr,
            nameEn: nameEn,
            descriptionAr: descriptionAr,
            descriptionEn: descriptionEn,
            mainPhone: phone,
            receptionPhone: phone,
            whatsapp: whatsapp,
            addressAr: addressAr,
            addressEn: addressEn,
            googleMapsUrl: googleMapsUrl,
            city: city,
            latitude: latitude,
            longitude: longitude,
            logoUrl: clearLogo ? '' : logo,
            coverImageUrl: clearCoverImage ? '' : coverImage,
          )
        : await _inSession(
            _catalogRepository.updateClinicProfile(payload),
            sessionEpoch,
          );
    // Eviction leaves signed URLs byte-for-byte intact, even if the URL is reused.
    if ((logo != null || clearLogo) && old.logoUrl.isNotEmpty) {
      PaintingBinding.instance.imageCache.evict(NetworkImage(old.logoUrl));
    }
    if ((coverImage != null || clearCoverImage) &&
        old.coverImageUrl.isNotEmpty) {
      PaintingBinding.instance.imageCache.evict(
        NetworkImage(old.coverImageUrl),
      );
    }
    _activeClinic = updated;
    _calculateLocalChecklist();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // CLINIC BRANCHES & ONBOARDING CHECKLIST
  // -------------------------------------------------------------

  Future<void> loadBranches() async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      if (_clinicBranches.isEmpty && _activeClinic.branches.isNotEmpty) {
        _clinicBranches.addAll(_activeClinic.branches);
      }
      return;
    }
    try {
      final res = await _inSession(
        _catalogRepository.getBranches(),
        sessionEpoch,
      );
      _clinicBranches.clear();
      _clinicBranches.addAll(res);
      notifyListeners();
    } catch (_) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      if (_clinicBranches.isEmpty && _activeClinic.branches.isNotEmpty) {
        _clinicBranches.addAll(_activeClinic.branches);
        notifyListeners();
      }
    }
  }

  Future<ClinicBranch> createBranch(Map<String, dynamic> data) async {
    final sessionEpoch = _sessionEpoch;
    final branch = await _inSession(
      _catalogRepository.createBranch(data),
      sessionEpoch,
    );
    _clinicBranches.add(branch);
    _calculateLocalChecklist();
    notifyListeners();
    return branch;
  }

  Future<ClinicBranch> updateBranch(
    String id,
    Map<String, dynamic> data,
  ) async {
    final sessionEpoch = _sessionEpoch;
    final branch = await _inSession(
      _catalogRepository.updateBranch(id, data),
      sessionEpoch,
    );
    final idx = _clinicBranches.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _clinicBranches[idx] = branch;
    }
    notifyListeners();
    return branch;
  }

  Future<void> deleteBranch(String id) async {
    final sessionEpoch = _sessionEpoch;
    await _inSession(_catalogRepository.deleteBranch(id), sessionEpoch);
    _clinicBranches.removeWhere((b) => b.id == id);
    _calculateLocalChecklist();
    notifyListeners();
  }

  Future<void> loadSetupChecklist() async {
    final sessionEpoch = _sessionEpoch;
    if (_mockMode) {
      _calculateLocalChecklist();
      return;
    }
    try {
      _setupChecklist = await _inSession(
        _catalogRepository.getSetupChecklist(),
        sessionEpoch,
      );
      notifyListeners();
    } catch (_) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      _calculateLocalChecklist();
    }
  }

  void _calculateLocalChecklist() {
    final hasBranding =
        _activeClinic.logoUrl.isNotEmpty ||
        _activeClinic.coverImageUrl.isNotEmpty;
    final hasDetails =
        _activeClinic.descriptionAr.isNotEmpty ||
        _activeClinic.descriptionEn.isNotEmpty ||
        _activeClinic.nameEn.isNotEmpty;
    final hasBranch =
        _clinicBranches.isNotEmpty ||
        _activeClinic.branches.isNotEmpty ||
        _activeClinic.hasMapLocation;
    final hasPractitioner = _clinicPractitioners.isNotEmpty;
    final hasTreatment = _clinicTreatments.isNotEmpty;

    int completed = 0;
    if (hasBranding) completed++;
    if (hasDetails) completed++;
    if (hasBranch) completed++;
    if (hasPractitioner) completed++;
    if (hasTreatment) completed++;

    final progress = ((completed / 5) * 100).round();

    _setupChecklist = ClinicSetupChecklistModel(
      clinicId: _activeClinic.id,
      setupStatus: _activeClinic.setupStatus,
      progressPercentage: progress,
      isReadyForReview: completed == 5,
      items: [
        ClinicSetupChecklistItem(
          key: 'branding',
          titleEn: 'Clinic Branding (Logo & Cover)',
          titleAr: 'الهوية البصرية (الشعار وصورة الغلاف)',
          isCompleted: hasBranding,
          route: '/clinic/profile',
        ),
        ClinicSetupChecklistItem(
          key: 'details',
          titleEn: 'Bilingual Bio & Contact Details',
          titleAr: 'الوصف التعريفي باللغتين ومعلومات الاتصال',
          isCompleted: hasDetails,
          route: '/clinic/profile',
        ),
        ClinicSetupChecklistItem(
          key: 'branch',
          titleEn: 'Main Branch Location & Map',
          titleAr: 'الفرع الرئيسي وموقع الخريطة',
          isCompleted: hasBranch,
          route: '/clinic/branches',
        ),
        ClinicSetupChecklistItem(
          key: 'practitioners',
          titleEn: 'At least 1 Medical Practitioner',
          titleAr: 'طبيب أو ممارس مرخص واحد على الأقل',
          isCompleted: hasPractitioner,
          route: '/clinic/practitioners',
        ),
        ClinicSetupChecklistItem(
          key: 'treatments',
          titleEn: 'At least 1 Treatment Service',
          titleAr: 'خدمة أو علاج تجميلي واحد على الأقل',
          isCompleted: hasTreatment,
          route: '/clinic/treatments',
        ),
      ],
    );
    notifyListeners();
  }

  Future<void> submitProfileForReview() async {
    final sessionEpoch = _sessionEpoch;
    final res = await _inSession(
      _catalogRepository.submitProfileForReview(),
      sessionEpoch,
    );
    final newStatus = res['setup_status']?.toString() ?? 'submitted';
    _activeClinic = _activeClinic.copyWith(setupStatus: newStatus);
    try {
      _setupChecklist = await _inSession(
        _catalogRepository.getSetupChecklist(),
        sessionEpoch,
      );
    } catch (_) {
      if (sessionEpoch != _sessionEpoch) {
        return;
      }
      _calculateLocalChecklist();
    }
    notifyListeners();
  }
}
