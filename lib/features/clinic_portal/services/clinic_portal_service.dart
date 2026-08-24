import 'package:flutter/foundation.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';

/// Clinic Portal Service managing State & Mock Data for the Logged-in Clinic Partner
class ClinicPortalService extends ChangeNotifier {
  static final ClinicPortalService _instance = ClinicPortalService._internal();
  factory ClinicPortalService() => _instance;
  ClinicPortalService._internal() {
    _initializeMockData();
  }

  late ClinicModel _activeClinic;
  final List<AppointmentRequestModel> _clinicLeads = [];
  final Map<String, String> _internalNotes = {};
  final List<OfferModel> _clinicOffers = [];
  final List<PractitionerModel> _clinicPractitioners = [];
  final List<TreatmentModel> _clinicTreatments = [];

  ClinicModel get activeClinic => _activeClinic;
  List<AppointmentRequestModel> get clinicLeads => List.unmodifiable(_clinicLeads);
  List<OfferModel> get clinicOffers => List.unmodifiable(_clinicOffers);
  List<PractitionerModel> get clinicPractitioners => List.unmodifiable(_clinicPractitioners);
  List<TreatmentModel> get clinicTreatments => List.unmodifiable(_clinicTreatments);

  int get newLeadsCount => _clinicLeads.where((l) => l.status == AppointmentLeadStatus.sent).length;
  int get contactedLeadsCount => _clinicLeads.where((l) => l.status == AppointmentLeadStatus.contacted).length;
  int get closedLeadsCount => _clinicLeads.where((l) => l.status == AppointmentLeadStatus.closed).length;
  int get totalLeadsCount => _clinicLeads.length;
  int get activeOffersCount => _clinicOffers.length;

  String getInternalNotes(String leadId) => _internalNotes[leadId] ?? '';

  void _initializeMockData() {
    final mock = MockDataService();
    // Default active clinic: Kaya Skin Clinic - Jumeirah
    _activeClinic = mock.clinics.firstWhere(
      (c) => c.id == 'kaya-jumeirah',
      orElse: () => mock.clinics.first,
    );

    // Initial 7 realistic mock leads for clinic partner
    _clinicLeads.clear();
    _clinicLeads.addAll([
      AppointmentRequestModel(
        id: 'cl-lead-101',
        referenceCode: '#REQ-88912',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Flagship',
        serviceNameAr: 'الهيدرافيسيال الملكي الطبي 7 مراحل',
        serviceNameEn: 'Royal 7-Step Medical HydraFacial',
        practitionerNameAr: 'د. ريم الخالد',
        practitionerNameEn: 'Dr. Reem Al Khaled',
        practitionerType: PractitionerType.doctor,
        preferredDate: DateTime.now().add(const Duration(days: 1)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        patientFullName: 'مريم أحمد المنصوري',
        patientPhone: '+971 50 123 4567',
        notes: 'مهتمة بالباقة الصيفية والعناية قبل مناسبة قريبة.',
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
      ),
      AppointmentRequestModel(
        id: 'cl-lead-102',
        referenceCode: '#REQ-88913',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Flagship',
        serviceNameAr: 'حقن البوتوكس للوجه (Allergan)',
        serviceNameEn: 'Facial Botox Injections',
        practitionerNameAr: 'د. ريم الخالد',
        practitionerNameEn: 'Dr. Reem Al Khaled',
        practitionerType: PractitionerType.doctor,
        preferredDate: DateTime.now().add(const Duration(days: 2)),
        preferredTimeWindow: PreferredTimeWindow.morning,
        patientFullName: 'فاطمة المزروعي',
        patientPhone: '+971 55 987 6543',
        notes: 'استشارة تجاعيد الجبهة وخطوط الابتسامة.',
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      ),
      AppointmentRequestModel(
        id: 'cl-lead-103',
        referenceCode: '#REQ-88914',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع دبي مول',
        branchNameEn: 'Dubai Mall Branch',
        serviceNameAr: 'حقن البروفايلو لشد النضارة الحيوية',
        serviceNameEn: 'Profhilo Bioremodeling Lift',
        practitionerNameAr: 'أ. نور الهدى صالح',
        practitionerNameEn: 'Nour El Houda Saleh',
        practitionerType: PractitionerType.nurse,
        preferredDate: DateTime.now().add(const Duration(days: 3)),
        preferredTimeWindow: PreferredTimeWindow.afternoon,
        patientFullName: 'عبدالله الشامسي',
        patientPhone: '+971 52 443 2190',
        notes: 'استفسار عن عدد الجلسات الموصى بها.',
        consentAccepted: true,
        status: AppointmentLeadStatus.contacted,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      AppointmentRequestModel(
        id: 'cl-lead-104',
        referenceCode: '#REQ-88915',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Flagship',
        serviceNameAr: 'تقشير الليزر الكربوني (هوليوود بيل)',
        serviceNameEn: 'Carbon Laser Peel',
        practitionerNameAr: 'أ. دينا الشامي',
        practitionerNameEn: 'Dina Al Shami',
        practitionerType: PractitionerType.licensedProfessional,
        preferredDate: DateTime.now().add(const Duration(days: 4)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        patientFullName: 'سارة المنصوري',
        patientPhone: '+971 50 332 1199',
        notes: '',
        consentAccepted: true,
        status: AppointmentLeadStatus.contacted,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppointmentRequestModel(
        id: 'cl-lead-105',
        referenceCode: '#REQ-88916',
        clinicId: _activeClinic.id,
        clinicNameAr: _activeClinic.nameAr,
        clinicNameEn: _activeClinic.nameEn,
        branchNameAr: 'فرع دبي هيلز',
        branchNameEn: 'Dubai Hills Branch',
        serviceNameAr: 'توريد وتحديد الشفاه بالفيلر الروسي',
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

    // Populate offers
    _clinicOffers.clear();
    _clinicOffers.addAll(mock.offers.where((o) => o.clinicId == _activeClinic.id || o.clinicId == 'kaya-jumeirah'));
    if (_clinicOffers.isEmpty && mock.offers.isNotEmpty) {
      _clinicOffers.add(mock.offers.first);
    }

    // Populate practitioners
    _clinicPractitioners.clear();
    _clinicPractitioners.addAll(mock.getPractitionersForClinic(_activeClinic.id));
    if (_clinicPractitioners.isEmpty && mock.practitioners.isNotEmpty) {
      _clinicPractitioners.addAll(mock.practitioners.take(2));
    }

    // Populate treatments
    _clinicTreatments.clear();
    _clinicTreatments.addAll(mock.treatments.where((t) => _activeClinic.treatmentIds.contains(t.id)));
    if (_clinicTreatments.isEmpty && mock.treatments.isNotEmpty) {
      _clinicTreatments.addAll(mock.treatments.take(4));
    }
  }

  /// Update the status of a consultation lead
  void updateLeadStatus(String leadId, AppointmentLeadStatus newStatus) {
    final index = _clinicLeads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      final old = _clinicLeads[index];
      _clinicLeads[index] = AppointmentRequestModel(
        id: old.id,
        referenceCode: old.referenceCode,
        clinicId: old.clinicId,
        clinicNameAr: old.clinicNameAr,
        clinicNameEn: old.clinicNameEn,
        branchNameAr: old.branchNameAr,
        branchNameEn: old.branchNameEn,
        serviceNameAr: old.serviceNameAr,
        serviceNameEn: old.serviceNameEn,
        practitionerId: old.practitionerId,
        practitionerNameAr: old.practitionerNameAr,
        practitionerNameEn: old.practitionerNameEn,
        practitionerType: old.practitionerType,
        preferredDate: old.preferredDate,
        preferredTimeWindow: old.preferredTimeWindow,
        patientFullName: old.patientFullName,
        patientPhone: old.patientPhone,
        notes: old.notes,
        consentAccepted: old.consentAccepted,
        status: newStatus,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }

  /// Save internal notes for a lead
  void saveInternalNotes(String leadId, String notes) {
    _internalNotes[leadId] = notes;
    notifyListeners();
  }

  /// Add a new offer
  void addOffer(OfferModel offer) {
    _clinicOffers.insert(0, offer);
    notifyListeners();
  }

  /// Remove an offer
  void deleteOffer(String offerId) {
    _clinicOffers.removeWhere((o) => o.id == offerId);
    notifyListeners();
  }

  /// Add a new medical practitioner
  void addPractitioner(PractitionerModel practitioner) {
    _clinicPractitioners.add(practitioner);
    notifyListeners();
  }

  /// Add a new treatment / service
  void addTreatment(TreatmentModel treatment) {
    _clinicTreatments.add(treatment);
    notifyListeners();
  }

  /// Update clinic details
  void updateClinicProfile({
    required String nameAr,
    required String nameEn,
    required String descriptionAr,
    required String descriptionEn,
    required String phone,
    required String whatsapp,
  }) {
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
      areaAr: _activeClinic.areaAr,
      areaEn: _activeClinic.areaEn,
      addressAr: _activeClinic.addressAr,
      addressEn: _activeClinic.addressEn,
      distanceKm: _activeClinic.distanceKm,
      mainPhone: phone,
      receptionPhone: phone,
      whatsapp: whatsapp,
      googlePlaceId: _activeClinic.googlePlaceId,
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
  }
}
