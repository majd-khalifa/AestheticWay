import 'package:flutter/foundation.dart';
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
  bool _hasLoadedFromApi = false;
  bool _hasLoadedCatalogFromApi = false;

  late ClinicModel _activeClinic;
  final List<AppointmentRequestModel> _clinicLeads = [];
  final Map<String, String> _internalNotes = {};
  ClinicDashboardModel? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  final List<OfferModel> _clinicOffers = [];
  final List<PractitionerModel> _clinicPractitioners = [];
  final List<TreatmentModel> _clinicTreatments = [];
  final List<CategoryModel> _categories = [];
  final List<ProductModel> _clinicProducts = [];
  final List<ArticleModel> _clinicArticles = [];

  ClinicModel get activeClinic => _activeClinic;
  List<AppointmentRequestModel> get clinicLeads => List.unmodifiable(_clinicLeads);
  ClinicDashboardModel? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<OfferModel> get clinicOffers => List.unmodifiable(_clinicOffers);
  List<PractitionerModel> get clinicPractitioners => List.unmodifiable(_clinicPractitioners);
  List<TreatmentModel> get clinicTreatments => List.unmodifiable(_clinicTreatments);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<ProductModel> get clinicProducts => List.unmodifiable(_clinicProducts);
  List<ArticleModel> get clinicArticles => List.unmodifiable(_clinicArticles);

  void _initializeDefaultActiveClinic() {
    _activeClinic = const ClinicModel(
      id: 'clinic-active',
      nameAr: 'عيادة شريكة معتمدة',
      nameEn: 'Accredited Partner Clinic',
      descriptionAr: '',
      descriptionEn: '',
      coverImageUrl: '',
      galleryImages: [],
      logoUrl: '',
      rating: 5.0,
      reviewCount: 0,
      subscriptionTier: SubscriptionTier.basic,
      city: 'Dubai',
      areaAr: 'دبي',
      areaEn: 'Dubai',
      addressAr: 'دبي، الإمارات العربية المتحدة',
      addressEn: 'Dubai, UAE',
    );
  }

  @visibleForTesting
  void enableMockMode({
    List<AppointmentRequestModel>? testLeads,
    ClinicDashboardModel? testDashboard,
  }) {
    _mockMode = true;
    if (_clinicLeads.isEmpty && _clinicOffers.isEmpty && _clinicPractitioners.isEmpty) {
      _initializeFallbackData();
    }
    if (testLeads != null) {
      _clinicLeads.clear();
      _clinicLeads.addAll(testLeads);
    }
    if (testDashboard != null) {
      _dashboardData = testDashboard;
    }
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

  @visibleForTesting
  void resetTestingState() {
    _mockMode = false;
    _hasLoadedFromApi = false;
    _hasLoadedCatalogFromApi = false;
    _isLoading = false;
    _errorMessage = null;
    _internalNotes.clear();
    _clinicLeads.clear();
    _clinicOffers.clear();
    _clinicPractitioners.clear();
    _clinicTreatments.clear();
    _categories.clear();
    _clinicProducts.clear();
    _clinicArticles.clear();
    _initializeDefaultActiveClinic();
  }

  int get newLeadsCount =>
      _dashboardData?.newLeads ??
      _clinicLeads.where((l) => l.status == AppointmentLeadStatus.sent).length;

  int get contactedLeadsCount =>
      _dashboardData?.contactedLeads ??
      _clinicLeads.where((l) => l.status == AppointmentLeadStatus.contacted).length;

  int get closedLeadsCount =>
      _dashboardData?.closedLeads ??
      _clinicLeads.where((l) => l.status == AppointmentLeadStatus.closed).length;

  int get totalLeadsCount =>
      _dashboardData?.totalLeads ?? _clinicLeads.length;

  int get activeOffersCount =>
      _clinicOffers.where((o) => o.status == 'active' && o.isActive).length;

  int get activePractitionersCount =>
      _clinicPractitioners.where((p) => p.status == 'active').length;

  int get activeTreatmentsCount =>
      _clinicTreatments.where((t) => t.status == 'active' && t.isActive).length;

  int get activeProductsCount => _clinicProducts.length;

  int get activeArticlesCount => _clinicArticles.length;

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
  Future<void> loadPortalData({
    bool refresh = false,
    String? status,
    String? search,
  }) async {
    if (_mockMode) {
      return;
    }
    if (!refresh && _hasLoadedFromApi) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getLeads(status: status, search: search),
        _repository.getDashboard(),
      ]);

      _clinicLeads.clear();
      _clinicLeads.addAll(results[0] as List<AppointmentRequestModel>);
      _dashboardData = results[1] as ClinicDashboardModel;

      try {
        _activeClinic = await _catalogRepository.getClinicProfile();
      } catch (_) {}

      _hasLoadedFromApi = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch live catalog data (practitioners, treatments, offers, categories, products, articles)
  Future<void> loadCatalogData({bool refresh = false}) async {
    if (_mockMode) {
      return;
    }
    if (!refresh && _hasLoadedCatalogFromApi) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _catalogRepository.getPractitioners(),
        _catalogRepository.getTreatments(),
        _catalogRepository.getOffers(),
        _catalogRepository.getCategories(),
        _catalogRepository.getProducts(),
        _catalogRepository.getArticles(),
      ]);

      _clinicPractitioners.clear();
      _clinicPractitioners.addAll(results[0] as List<PractitionerModel>);

      _clinicTreatments.clear();
      _clinicTreatments.addAll(results[1] as List<TreatmentModel>);

      _clinicOffers.clear();
      _clinicOffers.addAll(results[2] as List<OfferModel>);

      _categories.clear();
      _categories.addAll(results[3] as List<CategoryModel>);

      _clinicProducts.clear();
      _clinicProducts.addAll(results[4] as List<ProductModel>);

      _clinicArticles.clear();
      final rawArticles = results[5] as List<ArticleModel>;
      _clinicArticles.addAll(rawArticles.map(_enrichArticleAuthor));

      _hasLoadedCatalogFromApi = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ArticleModel _enrichArticleAuthor(ArticleModel article) {
    if (article.authorDoctorId.isNotEmpty &&
        article.authorDoctorNameEn.isEmpty &&
        article.authorDoctorNameAr.isEmpty) {
      final idx = _clinicPractitioners.indexWhere((p) => p.id == article.authorDoctorId);
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
  Future<void> filterLeads({String? status, String? search}) async {
    if (_mockMode) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final leads = await _repository.getLeads(status: status, search: search);
      _clinicLeads.clear();
      _clinicLeads.addAll(leads);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

    _internalNotes['cl-lead-103'] = 'تم الاتصال بالعميل وإرسال تفاصيل الجلسة عبر الواتساب.';
    _internalNotes['cl-lead-104'] = 'تم التنسيق لتأكيد موعد استشارة يوم الخميس.';
    _internalNotes['cl-lead-106'] = 'تم حضور الاستشارة بنجاح في فرع جميرا.';

    // Populate catalog placeholders for offline fallback
    _clinicOffers.clear();
    _clinicOffers.addAll(mock.offers.where((o) => o.clinicId == _activeClinic.id || o.clinicId == 'kaya-jumeirah'));
    if (_clinicOffers.isEmpty && mock.offers.isNotEmpty) {
      _clinicOffers.add(mock.offers.first);
    }

    _clinicPractitioners.clear();
    _clinicPractitioners.addAll(mock.getPractitionersForClinic(_activeClinic.id));
    if (_clinicPractitioners.isEmpty && mock.practitioners.isNotEmpty) {
      _clinicPractitioners.addAll(mock.practitioners.take(2));
    }

    _clinicTreatments.clear();
    _clinicTreatments.addAll(mock.treatments.where((t) => _activeClinic.treatmentIds.contains(t.id)));
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
      newLeads: _clinicLeads.where((l) => l.status == AppointmentLeadStatus.sent).length,
      contactedLeads: _clinicLeads.where((l) => l.status == AppointmentLeadStatus.contacted).length,
      closedLeads: _clinicLeads.where((l) => l.status == AppointmentLeadStatus.closed).length,
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
  Future<void> updateLeadStatus(String leadId, AppointmentLeadStatus newStatus) async {
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
      final updated = await _repository.updateLeadStatus(leadId, newStatus);
      _clinicLeads[index] = updated;

      // Silently refresh dashboard metrics in background
      _repository.getDashboard().then((d) {
        _dashboardData = d;
        notifyListeners();
      }).catchError((_) {});

      notifyListeners();
    } catch (e) {
      // Rollback on failure
      _clinicLeads[index] = old;
      notifyListeners();
      rethrow;
    }
  }

  /// Save internal notes for a lead with live POST to backend API
  Future<void> saveInternalNotes(String leadId, String notes) async {
    _internalNotes[leadId] = notes;
    notifyListeners();

    if (_mockMode) {
      return;
    }

    try {
      final createdNote = await _repository.addLeadNote(leadId, notes);
      final index = _clinicLeads.indexWhere((l) => l.id == leadId);
      if (index != -1) {
        final lead = _clinicLeads[index];
        _clinicLeads[index] = lead.copyWith(
          internalNotes: [createdNote, ...lead.internalNotes],
        );
        notifyListeners();
      }
    } catch (e) {
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
    if (_mockMode) {
      final o = OfferModel.fromJson(data);
      _clinicOffers.insert(0, o);
      notifyListeners();
      return o;
    }
    final created = await _catalogRepository.createOffer(data);
    _clinicOffers.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<OfferModel> updateOffer(String id, Map<String, dynamic> data) async {
    if (_mockMode) {
      final idx = _clinicOffers.indexWhere((o) => o.id == id);
      if (idx != -1) {
        final o = _clinicOffers[idx];
        final updated = o.copyWith(
          titleEn: data['title_en'],
          titleAr: data['title_ar'],
          originalPrice: double.tryParse(data['original_price']?.toString() ?? ''),
          offerPrice: double.tryParse(data['offer_price']?.toString() ?? ''),
          status: data['status'],
          isActive: data['is_active'],
        );
        _clinicOffers[idx] = updated;
        notifyListeners();
        return updated;
      }
    }
    final updated = await _catalogRepository.updateOffer(id, data);
    final idx = _clinicOffers.indexWhere((o) => o.id == id);
    if (idx != -1) {
      _clinicOffers[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> toggleOfferStatus(String offerId) async {
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
      final updated = await _catalogRepository.updateOfferStatus(offerId, nextStatus);
      _clinicOffers[idx] = updated;
      notifyListeners();
    } catch (e) {
      _clinicOffers[idx] = current;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteOffer(String offerId) async {
    final idx = _clinicOffers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      final removed = _clinicOffers.removeAt(idx);
      notifyListeners();
      if (_mockMode) return;
      try {
        await _catalogRepository.deleteOffer(offerId);
      } catch (e) {
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

  Future<PractitionerModel> createPractitioner(Map<String, dynamic> data) async {
    if (_mockMode) {
      final p = PractitionerModel.fromJson(data);
      _clinicPractitioners.add(p);
      notifyListeners();
      return p;
    }
    final created = await _catalogRepository.createPractitioner(data);
    _clinicPractitioners.add(created);
    notifyListeners();
    return created;
  }

  Future<PractitionerModel> updatePractitioner(String id, Map<String, dynamic> data) async {
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
    final updated = await _catalogRepository.updatePractitioner(id, data);
    final idx = _clinicPractitioners.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _clinicPractitioners[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> deletePractitioner(String id) async {
    final idx = _clinicPractitioners.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final removed = _clinicPractitioners.removeAt(idx);
      notifyListeners();
      if (_mockMode) return;
      try {
        await _catalogRepository.deletePractitioner(id);
      } catch (e) {
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
    if (_mockMode) {
      final t = TreatmentModel.fromJson(data);
      _clinicTreatments.add(t);
      notifyListeners();
      return t;
    }
    final created = await _catalogRepository.createTreatment(data);
    _clinicTreatments.add(created);
    notifyListeners();
    return created;
  }

  Future<TreatmentModel> updateTreatment(String id, Map<String, dynamic> data) async {
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
    final updated = await _catalogRepository.updateTreatment(id, data);
    final idx = _clinicTreatments.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _clinicTreatments[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> deleteTreatment(String id) async {
    final idx = _clinicTreatments.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final removed = _clinicTreatments.removeAt(idx);
      notifyListeners();
      if (_mockMode) return;
      try {
        await _catalogRepository.deleteTreatment(id);
      } catch (e) {
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
    if (_mockMode) {
      final p = ProductModel.fromJson(data);
      _clinicProducts.insert(0, p);
      notifyListeners();
      return p;
    }
    final created = await _catalogRepository.createProduct(data);
    _clinicProducts.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
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
        );
        _clinicProducts[idx] = updated;
        notifyListeners();
        return updated;
      }
    }
    final updated = await _catalogRepository.updateProduct(id, data);
    final idx = _clinicProducts.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _clinicProducts[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> toggleProductAvailability(String productId) async {
    final idx = _clinicProducts.indexWhere((p) => p.id == productId);
    if (idx == -1) return;
    final current = _clinicProducts[idx];
    final nextActive = !current.isAvailable;
    _clinicProducts[idx] = current.copyWith(isAvailable: nextActive);
    notifyListeners();

    if (_mockMode || productId.startsWith('test-')) return;

    try {
      final updated = await _catalogRepository.updateProduct(
        productId,
        {'is_active': nextActive},
      );
      _clinicProducts[idx] = updated;
      notifyListeners();
    } catch (e) {
      _clinicProducts[idx] = current;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final idx = _clinicProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final removed = _clinicProducts.removeAt(idx);
      notifyListeners();
      if (_mockMode || productId.startsWith('test-')) return;
      try {
        await _catalogRepository.deleteProduct(productId);
      } catch (e) {
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
    if (_mockMode) {
      final a = _enrichArticleAuthor(ArticleModel.fromJson(data));
      _clinicArticles.insert(0, a);
      notifyListeners();
      return a;
    }
    final created = _enrichArticleAuthor(await _catalogRepository.createArticle(data));
    _clinicArticles.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<ArticleModel> updateArticle(String id, Map<String, dynamic> data) async {
    if (_mockMode) {
      final idx = _clinicArticles.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final a = _clinicArticles[idx];
        final updated = _enrichArticleAuthor(a.copyWith(
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
        ));
        _clinicArticles[idx] = updated;
        notifyListeners();
        return updated;
      }
    }
    final updated = _enrichArticleAuthor(await _catalogRepository.updateArticle(id, data));
    final idx = _clinicArticles.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _clinicArticles[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<void> toggleArticlePublish(String articleId) async {
    final idx = _clinicArticles.indexWhere((a) => a.id == articleId);
    if (idx == -1) return;
    final current = _clinicArticles[idx];
    final nextPublished = !current.isPublished;
    _clinicArticles[idx] = current.copyWith(isPublished: nextPublished);
    notifyListeners();

    if (_mockMode || articleId.startsWith('test-')) return;

    try {
      final updated = _enrichArticleAuthor(await _catalogRepository.updateArticle(
        articleId,
        {'is_published': nextPublished},
      ));
      _clinicArticles[idx] = updated;
      notifyListeners();
    } catch (e) {
      _clinicArticles[idx] = current;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteArticle(String articleId) async {
    final idx = _clinicArticles.indexWhere((a) => a.id == articleId);
    if (idx != -1) {
      final removed = _clinicArticles.removeAt(idx);
      notifyListeners();
      if (_mockMode || articleId.startsWith('test-')) return;
      try {
        await _catalogRepository.deleteArticle(articleId);
      } catch (e) {
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
  }) async {
    _activeClinic = ClinicModel(
      id: _activeClinic.id,
      nameAr: nameAr,
      nameEn: nameEn,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      coverImageUrl: _activeClinic.coverImageUrl,
      galleryImages: _activeClinic.galleryImages,
      logoUrl: _activeClinic.logoUrl,
      rating: _activeClinic.rating,
      reviewCount: _activeClinic.reviewCount,
      subscriptionTier: _activeClinic.subscriptionTier,
      licenseAuthority: _activeClinic.licenseAuthority,
      licenseNumber: _activeClinic.licenseNumber,
      city: _activeClinic.city,
      areaAr: addressAr ?? _activeClinic.areaAr,
      areaEn: addressEn ?? _activeClinic.areaEn,
      addressAr: addressAr ?? _activeClinic.addressAr,
      addressEn: addressEn ?? _activeClinic.addressEn,
      distanceKm: _activeClinic.distanceKm,
      mainPhone: phone,
      receptionPhone: phone,
      whatsapp: whatsapp,
      googlePlaceId: _activeClinic.googlePlaceId,
      googleMapsUrl: googleMapsUrl ?? _activeClinic.googleMapsUrl,
      latitude: _activeClinic.latitude,
      longitude: _activeClinic.longitude,
      workingHoursAr: _activeClinic.workingHoursAr,
      workingHoursEn: _activeClinic.workingHoursEn,
      branches: _activeClinic.branches,
      practitionerIds: _activeClinic.practitionerIds,
      treatmentIds: _activeClinic.treatmentIds,
      featuredOffers: _activeClinic.featuredOffers,
    );
    notifyListeners();

    if (_mockMode) return;

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
    };

    final updated = await _catalogRepository.updateClinicProfile(payload);
    _activeClinic = updated;
    notifyListeners();
  }
}
