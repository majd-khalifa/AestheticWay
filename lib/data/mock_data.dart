import 'package:flutter/material.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';

/// Central Mock Data & In-Memory Store for AESTHETIC WAY
class MockDataService extends ChangeNotifier {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal() {
    _initData();
  }

  late List<ClinicModel> _clinics;
  late List<PractitionerModel> _practitioners;
  late List<TreatmentModel> _treatments;
  late List<OfferModel> _offers;
  late List<ProductModel> _products;
  late List<ArticleModel> _articles;
  final List<AppointmentRequestModel> _appointmentRequests = [];

  List<ClinicModel> get clinics => _clinics;
  List<PractitionerModel> get practitioners => _practitioners;
  List<TreatmentModel> get treatments => _treatments;
  List<OfferModel> get offers => _offers;
  List<ProductModel> get products =>
      _products.where((p) => p.isPublishedByAdmin).toList();
  List<ProductModel> get allProductsForAdmin => _products;
  List<ArticleModel> get articles =>
      _articles.where((a) => a.isPublished && a.isApprovedByAdmin).toList();
  List<ArticleModel> get allArticlesForAdmin => _articles;
  List<AppointmentRequestModel> get appointmentRequests => _appointmentRequests;

  /// Filter Doctors (Medical Consultants & Specialists)
  List<PractitionerModel> get doctors =>
      _practitioners.where((p) => p.type == PractitionerType.doctor).toList();

  /// Filter Skin Experts (Nurses & Certified Dermal / Laser Specialists)
  List<PractitionerModel> get skinExperts => _practitioners.where((p) {
    return p.type == PractitionerType.nurse ||
        p.type == PractitionerType.licensedProfessional ||
        p.specialtyAr.contains('بشرة') ||
        p.specialtyAr.contains('ليزر') ||
        p.specialtyEn.toLowerCase().contains('skin') ||
        p.specialtyEn.toLowerCase().contains('laser');
  }).toList();

  /// Filter Plastic Surgery Treatments
  List<TreatmentModel> get plasticSurgeryTreatments => _treatments.where((t) {
    return t.categoryAr.contains('جراحة') ||
        t.categoryEn.toLowerCase().contains('surgery') ||
        t.nameAr.contains('شد') ||
        t.nameAr.contains('أنف') ||
        t.nameAr.contains('شفط');
  }).toList();

  /// Top Carousel Ads sorted strictly by B2B Subscription Priority:
  /// VIP Platinum Partner first (slots 1 & 2), followed by Featured Partner (slots 3+)
  List<ClinicModel> get topCarouselAds {
    final eligible = _clinics.where((c) => c.isEligibleForTopCarousel).toList();
    eligible.sort((a, b) {
      if (a.subscriptionTier == SubscriptionTier.vipPlatinum &&
          b.subscriptionTier != SubscriptionTier.vipPlatinum) {
        return -1;
      }
      if (b.subscriptionTier == SubscriptionTier.vipPlatinum &&
          a.subscriptionTier != SubscriptionTier.vipPlatinum) {
        return 1;
      }
      return 0;
    });
    return eligible;
  }

  /// Nearby Verified Clinics sorted by distance
  List<ClinicModel> get nearbyClinics {
    final list = List<ClinicModel>.from(_clinics);
    list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list;
  }

  ClinicModel? getClinicById(String id) {
    try {
      return _clinics.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  PractitionerModel? getPractitionerById(String id) {
    try {
      return _practitioners.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<PractitionerModel> getPractitionersForClinic(String clinicId) {
    return _practitioners.where((p) => p.clinicId == clinicId).toList();
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> getProductsForClinic(String clinicId) {
    return _products.where((p) => p.clinicId == clinicId).toList();
  }

  ArticleModel? getArticleById(String id) {
    try {
      return _articles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ArticleModel> getArticlesForClinic(String clinicId) {
    return _articles.where((a) => a.clinicId == clinicId).toList();
  }

  void addAppointmentRequest(AppointmentRequestModel request) {
    _appointmentRequests.insert(0, request);
    notifyListeners();
  }

  void addProduct(ProductModel product) {
    _products.insert(0, product);
    notifyListeners();
  }

  void toggleProductAvailability(String productId) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final p = _products[idx];
      _products[idx] = p.copyWith(isAvailable: !p.isAvailable);
      notifyListeners();
    }
  }

  void toggleProductAdminPublication(String productId) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final p = _products[idx];
      _products[idx] = p.copyWith(isPublishedByAdmin: !p.isPublishedByAdmin);
      notifyListeners();
    }
  }

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  void addArticle(ArticleModel article) {
    _articles.insert(0, article);
    notifyListeners();
  }

  void toggleArticlePublish(String articleId) {
    final idx = _articles.indexWhere((a) => a.id == articleId);
    if (idx != -1) {
      final a = _articles[idx];
      _articles[idx] = a.copyWith(isPublished: !a.isPublished);
      notifyListeners();
    }
  }

  void toggleArticleAdminApproval(String articleId) {
    final idx = _articles.indexWhere((a) => a.id == articleId);
    if (idx != -1) {
      final a = _articles[idx];
      _articles[idx] = a.copyWith(isApprovedByAdmin: !a.isApprovedByAdmin);
      notifyListeners();
    }
  }

  void deleteArticle(String articleId) {
    _articles.removeWhere((a) => a.id == articleId);
    notifyListeners();
  }

  void _initData() {
    _clinics = [
      ClinicModel(
        id: 'kaya-jumeirah',
        nameAr: 'عيادة كايا للجلدية والتجميل',
        nameEn: 'Kaya Skin Clinic - Jumeirah',
        descriptionAr:
            'مركز رائد في علاجات البشرة والجلدية والتجميل الطبي في دبي مع كادر طبي معتمد وأحدث أجهزة الليزر العالمية.',
        descriptionEn:
            'Leading medical aesthetic and dermatology center in Dubai featuring certified doctors and latest laser tech.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=800&q=80',
        galleryImages: [
          'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
        ],
        logoUrl:
            'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=200&q=80',
        rating: 4.9,
        reviewCount: 184,
        subscriptionTier: SubscriptionTier.vipPlatinum,
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-DB-884120',
        city: 'Dubai',
        areaAr: 'جميرا 1',
        areaEn: 'Jumeirah 1',
        addressAr: 'شارع شاطئ جميرا، فيلا 24A، دبي',
        addressEn: 'Jumeirah Beach Road, Villa 24A, Dubai',
        distanceKm: 2.1,
        mainPhone: '+97143499558',
        receptionPhone: '+97143499550',
        whatsapp: '+971501234567',
        googlePlaceId: 'ChIJN1t_tDeuEmsRUsoyG83frY4',
        latitude: 25.2154,
        longitude: 55.2536,
        workingHoursAr: 'السبت - الخميس: 9:00 ص - 9:00 م',
        workingHoursEn: 'Sat - Thu: 9:00 AM - 9:00 PM',
        branches: const [
          ClinicBranch(
            id: 'kaya-jumeirah-b1',
            nameAr: 'فرع جميرا الرئيسي',
            nameEn: 'Jumeirah Main Flagship',
            areaAr: 'جميرا 1',
            areaEn: 'Jumeirah 1',
            addressAr: 'شارع شاطئ جميرا، فيلا 24A',
            addressEn: 'Jumeirah Beach Road, Villa 24A',
            phone: '+97143499558',
            distanceKm: 2.1,
            latitude: 25.2154,
            longitude: 55.2536,
          ),
          ClinicBranch(
            id: 'kaya-jumeirah-b2',
            nameAr: 'فرع مول الإمارات',
            nameEn: 'Mall of the Emirates Branch',
            areaAr: 'البرشاء',
            areaEn: 'Al Barsha',
            addressAr: 'مجمع العيادات، الطابق الأول',
            addressEn: 'Clinic Complex, 1st Floor',
            phone: '+97143499559',
            distanceKm: 11.4,
            latitude: 25.1181,
            longitude: 55.2006,
          ),
        ],
        practitionerIds: ['dr-reem', 'nurse-nour', 'nurse-layla'],
        treatmentIds: [
          'botox-allergan',
          'hydrafacial-royal',
          'profhilo-lift',
          'morpehus8-glow',
        ],
        featuredOffers: ['offer-glow-summer'],
      ),
      ClinicModel(
        id: 'elegance-downtown',
        nameAr: 'مركز الأناقة الطبي للجلدية والتجميل',
        nameEn: 'Elegance Medical Aesthetic Center',
        descriptionAr:
            'مركز طبي معتمد للإجراءات التجميلية غير الجراحية، نحت الوجه بالفيلر والبوتوكس، واستشارات الجراحة التجميلية.',
        descriptionEn:
            'Certified medical center for non-surgical aesthetic enhancements, facial fillers, Botox and plastic surgery.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
        galleryImages: [
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=800&q=80',
        ],
        logoUrl:
            'https://images.unsplash.com/photo-1582750433449-648ed127bb54?auto=format&fit=crop&w=200&q=80',
        rating: 4.95,
        reviewCount: 220,
        subscriptionTier: SubscriptionTier.vipPlatinum,
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-DB-990142',
        city: 'Dubai',
        areaAr: 'وسط مدينة دبي',
        areaEn: 'Downtown Dubai',
        addressAr: 'بوليفارد الشيخ محمد بن راشد، برج الأناقة، الطابق 4',
        addressEn: 'Sheikh Mohammed bin Rashid Blvd, Elegance Tower, 4th Floor',
        distanceKm: 3.8,
        mainPhone: '+97142233445',
        receptionPhone: '+97142233440',
        whatsapp: '+971509988776',
        googlePlaceId: 'ChIJ21cbB31DXz4R8Z4jL4o0V0A',
        latitude: 25.1972,
        longitude: 55.2744,
        workingHoursAr: 'السبت - الخميس: 10:00 ص - 10:00 م',
        workingHoursEn: 'Sat - Thu: 10:00 AM - 10:00 PM',
        branches: const [
          ClinicBranch(
            id: 'elegance-downtown-b1',
            nameAr: 'فرع داون تاون الرئيسي',
            nameEn: 'Downtown Flagship',
            areaAr: 'وسط مدينة دبي',
            areaEn: 'Downtown Dubai',
            addressAr: 'بوليفارد الشيخ محمد بن راشد، برج الأناقة',
            addressEn: 'Sheikh Mohammed bin Rashid Blvd, Elegance Tower',
            phone: '+97142233445',
            distanceKm: 3.8,
            latitude: 25.1972,
            longitude: 55.2744,
          ),
        ],
        practitionerIds: ['dr-khalil', 'spec-dina', 'spec-sara'],
        treatmentIds: [
          'rhinoplasty-sculpt',
          'blepharoplasty-lift',
          'vaser-lipo',
          'profhilo-lift',
        ],
        featuredOffers: ['offer-botox-package'],
      ),
      ClinicModel(
        id: 'novomed-marina',
        nameAr: 'مستشفى نوفوميد لجراحة اليوم الواحد والتجميل',
        nameEn: 'Novomed Specialized Surgical Center',
        descriptionAr:
            'مستشفى متكامل للإجراءات الجراحية التجميلية الدقيقة، نحت القوام بالفيزر، وتجديد شباب البشرة.',
        descriptionEn:
            'Comprehensive hospital for precision plastic surgeries, Vaser body contouring and skin renewal.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
        galleryImages: [
          'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
        ],
        logoUrl:
            'https://images.unsplash.com/photo-1551076805-e1869033e561?auto=format&fit=crop&w=200&q=80',
        rating: 4.85,
        reviewCount: 96,
        subscriptionTier: SubscriptionTier.featured,
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-DH-440192',
        city: 'Dubai',
        areaAr: 'دبي مارينا',
        areaEn: 'Dubai Marina',
        addressAr: 'مارينا بلازا، مجمع العيادات الطبية، الطابق 12',
        addressEn: 'Marina Plaza, Medical Clinics Complex, 12th Floor',
        distanceKm: 16.2,
        mainPhone: '+97143887700',
        receptionPhone: '+97143887711',
        whatsapp: '+971501122334',
        googlePlaceId: 'ChIJF03U9T_qXz4R4f2F2hR4_f8',
        latitude: 25.0789,
        longitude: 55.1389,
        workingHoursAr: 'السبت - الخميس: 9:00 ص - 8:30 م',
        workingHoursEn: 'Sat - Thu: 9:00 AM - 8:30 PM',
        branches: const [
          ClinicBranch(
            id: 'novomed-marina-b1',
            nameAr: 'فرع مارينا بلازا',
            nameEn: 'Marina Plaza Branch',
            areaAr: 'دبي مارينا',
            areaEn: 'Dubai Marina',
            addressAr: 'برج المارينا بلازا، الطابق 12',
            addressEn: 'Marina Plaza Tower, 12th Floor',
            phone: '+97143887700',
            distanceKm: 16.2,
            latitude: 25.0789,
            longitude: 55.1389,
          ),
        ],
        practitionerIds: ['dr-khalil', 'nurse-nour', 'spec-dina'],
        treatmentIds: [
          'rhinoplasty-sculpt',
          'vaser-lipo',
          'facelift-mini',
          'hydrafacial-royal',
        ],
        featuredOffers: ['offer-glow-summer'],
      ),
      ClinicModel(
        id: 'bateen-derma-abudhabi',
        nameAr: 'عيادة البطين التخصصية للجلدية',
        nameEn: 'Al Bateen Specialized Derma Clinic',
        descriptionAr:
            'عيادة متخصصة معتمدة في أبوظبي تقدم بروتوكولات علاجية مخصصة لصحة البشرة والتجميل غير الجراحي.',
        descriptionEn:
            'Licensed specialized aesthetic dermatology center in Abu Dhabi offering bespoke skincare treatments.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
        galleryImages: [
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
        ],
        logoUrl:
            'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=200&q=80',
        rating: 4.88,
        reviewCount: 110,
        subscriptionTier: SubscriptionTier.featured,
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-MF-771203',
        city: 'Abu Dhabi',
        areaAr: 'البطين',
        areaEn: 'Al Bateen',
        addressAr: 'شارع الملك عبد الله بن عبد العزيز، البطين، أبوظبي',
        addressEn: 'King Abdullah bin Abdulaziz St, Al Bateen, Abu Dhabi',
        distanceKm: 132.0,
        mainPhone: '+97126601199',
        receptionPhone: '+97126601100',
        whatsapp: '+971504445566',
        googlePlaceId: 'ChIJj7bM558ZXz4RyQo_L48',
        latitude: 24.4539,
        longitude: 54.3411,
        workingHoursAr: 'السبت - الخميس: 10:00 ص - 9:00 م',
        workingHoursEn: 'Sat - Thu: 10:00 AM - 9:00 PM',
        branches: const [
          ClinicBranch(
            id: 'bateen-b1',
            nameAr: 'فرع البطين',
            nameEn: 'Al Bateen Branch',
            areaAr: 'البطين',
            areaEn: 'Al Bateen',
            addressAr: 'شارع الملك عبد الله بن عبد العزيز، فيلا 9',
            addressEn: 'King Abdullah bin Abdulaziz St, Villa 9',
            phone: '+97126601199',
            distanceKm: 132.0,
            latitude: 24.4539,
            longitude: 54.3411,
          ),
        ],
        practitionerIds: ['dr-mansoori', 'dr-elena', 'nurse-mariam'],
        treatmentIds: ['botox-allergan', 'laser-rejuv', 'pico-pigment'],
      ),
      ClinicModel(
        id: 'al-wasl-aesthetic',
        nameAr: 'مركز الوصل للطب التجميلي',
        nameEn: 'Al Wasl Aesthetic Medical Center',
        descriptionAr:
            'مركز طبي مرخص يقدم خدمات العناية بالبشرة والليزر واستشارات الجلدية العامة.',
        descriptionEn:
            'Licensed medical center offering skincare, laser, and general dermatology consultations.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=800&q=80',
        galleryImages: [],
        logoUrl:
            'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=200&q=80',
        rating: 4.6,
        reviewCount: 48,
        subscriptionTier: SubscriptionTier.basic,
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-FL-003310',
        city: 'Dubai',
        areaAr: 'شارع الوصل',
        areaEn: 'Al Wasl Road',
        addressAr: 'شارع الوصل، مجمع الصفا الطبي، دبي',
        addressEn: 'Al Wasl Rd, Al Safa Medical Complex, Dubai',
        distanceKm: 5.5,
        mainPhone: '+97143445566',
        receptionPhone: '+97143445577',
        whatsapp: '+971505556677',
        latitude: 25.1882,
        longitude: 55.2412,
        workingHoursAr: 'السبت - الخميس: 9:00 ص - 8:00 م',
        workingHoursEn: 'Sat - Thu: 9:00 AM - 8:00 PM',
        branches: const [],
        practitionerIds: ['dr-elena', 'spec-sara'],
        treatmentIds: ['hydrafacial-royal', 'laser-rejuv'],
      ),
    ];

    _practitioners = [
      // 1. Doctors & Consultants
      PractitionerModel(
        id: 'dr-reem',
        nameAr: 'د. ريم الخالد',
        nameEn: 'Dr. Reem Al Khaled',
        type: PractitionerType.doctor,
        specialtyAr: 'استشاري أمراض جلدية وطب تجميلي',
        specialtyEn: 'Consultant Dermatologist & Aesthetic Medicine',
        classificationAr: 'استشاري أول جلدية وتجميل',
        classificationEn: 'Senior Consultant Dermatologist',
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-P-004812',
        avatarUrl:
            'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 14,
        rating: 4.9,
        reviewCount: 142,
        languages: const ['العربية', 'English', 'Français'],
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية والتجميل',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        procedures: const [
          'حقن الفيلر التجميلي',
          'حقن البوتوكس للوجه',
          'شد الوجه بالخيوط',
          'بروتوكولات النضارة العميقة',
        ],
        proceduresEn: const [
          'Aesthetic Dermal Fillers',
          'Facial Botox Injections',
          'Thread Face Lift',
          'Deep Glow Protocols',
        ],
        aboutAr:
            'استشارية حاصلة على البورد الكندي في الأمراض الجلدية وطب التجميل مع خبرة 14 عاماً في أبرز المراكز الطبية في دبي وكندا.',
        aboutEn:
            'Canadian Board certified consultant in dermatology and aesthetic medicine with 14 years of experience across top medical centers.',
      ),
      PractitionerModel(
        id: 'dr-mansoori',
        nameAr: 'د. أحمد المنصوري',
        nameEn: 'Dr. Ahmed Al Mansoori',
        type: PractitionerType.doctor,
        specialtyAr: 'استشاري طب تجميلي ونحت وجه',
        specialtyEn: 'Consultant Aesthetic Medicine & Facial Sculpting',
        classificationAr: 'استشاري طب تجميلي',
        classificationEn: 'Consultant Aesthetic Physician',
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-DOC-99214',
        avatarUrl:
            'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 16,
        rating: 4.85,
        reviewCount: 88,
        languages: const ['العربية', 'English'],
        clinicId: 'bateen-derma-abudhabi',
        clinicNameAr: 'عيادة البطين التخصصية للجلدية',
        clinicNameEn: 'Al Bateen Specialized Derma Clinic',
        procedures: const [
          'نحت الوجه بدون جراحة',
          'علاجات التجديد بالبروفايلو',
          'إزالة الندبات والتصبغات',
        ],
        proceduresEn: const [
          'Non-surgical Facial Contouring',
          'Profhilo Bioremodeling',
          'Scar & Pigment Correction',
        ],
        aboutAr:
            'استشاري تجميل مرخص وزميل الكلية الملكية للأطباء، خبير في التناسق الطبيعي لملامح الوجه.',
        aboutEn:
            'Certified aesthetic consultant and Fellow of the Royal College, specialized in natural facial harmony.',
      ),
      PractitionerModel(
        id: 'dr-khalil',
        nameAr: 'د. طارق خليل',
        nameEn: 'Dr. Tariq Khalil',
        type: PractitionerType.doctor,
        specialtyAr: 'استشاري جراحة التجميل والترميم',
        specialtyEn: 'Consultant Plastic & Reconstructive Surgeon',
        classificationAr: 'استشاري جراحة تجميلية',
        classificationEn: 'Consultant Plastic Surgeon',
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-SURG-77120',
        avatarUrl:
            'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 18,
        rating: 4.95,
        reviewCount: 160,
        languages: const ['العربية', 'English'],
        clinicId: 'novomed-marina',
        clinicNameAr: 'مستشفى نوفوميد لجراحة اليوم الواحد والتجميل',
        clinicNameEn: 'Novomed Specialized Surgical Center',
        procedures: const [
          'جراحة تجميل الأنف الدقيقة',
          'شد الجفون والعيون',
          'شفط الدهون بالفيزر 4D',
          'شد الوجه المصغر',
        ],
        proceduresEn: const [
          'Precision Rhinoplasty',
          'Blepharoplasty Eyelid Lift',
          'Vaser 4D Liposuction',
          'Mini Face Lift',
        ],
        aboutAr:
            'جراح تجميل معتمد وزميل البورد الأوروبي لجراحة التجميل مع خبرة واسعة في جراحات الوجه ونحت القوام.',
        aboutEn:
            'Board-certified European Fellow in plastic surgery with extensive experience in facial aesthetics and body sculpting.',
      ),
      PractitionerModel(
        id: 'dr-elena',
        nameAr: 'د. إيلينا روستوفا',
        nameEn: 'Dr. Elena Rostova',
        type: PractitionerType.doctor,
        specialtyAr: 'أخصائي أمراض جلدية وعلاجات الليزر',
        specialtyEn: 'Specialist Dermatologist & Laser Therapy',
        classificationAr: 'أخصائي جلدية وتجميل',
        classificationEn: 'Specialist Dermatologist',
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-DERM-55310',
        avatarUrl:
            'https://images.unsplash.com/photo-1594824813579-24535316db13?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 11,
        rating: 4.88,
        reviewCount: 75,
        languages: const ['English', 'Russian', 'العربية'],
        clinicId: 'bateen-derma-abudhabi',
        clinicNameAr: 'عيادة البطين التخصصية للجلدية',
        clinicNameEn: 'Al Bateen Specialized Derma Clinic',
        procedures: const [
          'علاج التصبغات والمسام بالليزر',
          'جلسات المورفيوس 8 لشد الجلد',
          'حقن البوتوكس العلاجي والتجميلي',
        ],
        proceduresEn: const [
          'Pigmentation & Pore Laser Clearing',
          'Morpheus8 RF Microneedling',
          'Cosmetic & Therapeutic Botox',
        ],
        aboutAr:
            'أخصائية جلدية معتمدة متخصصة في أحدث منصات الليزر وتجديد خلايا البشرة.',
        aboutEn:
            'Certified dermatologist specialized in cutting-edge laser technologies and advanced skin rejuvenation.',
      ),

      // 2. Skin Experts & Aesthetic Therapists (4+ Certified Specialists)
      PractitionerModel(
        id: 'nurse-nour',
        nameAr: 'أ. نور الهدى صالح',
        nameEn: 'Nour El Houda Saleh',
        type: PractitionerType.nurse,
        specialtyAr: 'ممرض مرخص - حقن ونضارة البشرة',
        specialtyEn: 'Senior Registered Aesthetic Nurse',
        classificationAr: 'ممرض تجميلي مرخص',
        classificationEn: 'Licensed Aesthetic Registered Nurse',
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-N-982410',
        avatarUrl:
            'https://images.unsplash.com/photo-1594824813579-24535316db13?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 8,
        rating: 4.82,
        reviewCount: 65,
        languages: const ['العربية', 'English'],
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية والتجميل',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        procedures: const [
          'علاجات الهيدرافيسيال المتقدمة',
          'جلسات الميزوثيرابي',
          'العناية بالبشرة بعد الليزر',
        ],
        proceduresEn: const [
          'Advanced HydraFacial',
          'Mesotherapy Radiance Boost',
          'Post-Laser Skincare Protocols',
        ],
        aboutAr:
            'ممرضة تجميلية معتمدة ومتخصصة في بروتوكولات تحضير وعناية البشرة قبل وبعد الإجراءات الطبية.',
        aboutEn:
            'Licensed aesthetic nurse specialized in pre and post-procedure clinical skincare protocols.',
      ),
      PractitionerModel(
        id: 'spec-dina',
        nameAr: 'أ. دينا الشامي',
        nameEn: 'Dina Al Shami',
        type: PractitionerType.licensedProfessional,
        specialtyAr: 'أخصائي ليزر وعلاج بشرة مرخص',
        specialtyEn: 'Licensed Laser & Skin Specialist',
        classificationAr: 'أخصائي تجميل مرخص',
        classificationEn: 'Licensed Aesthetic Specialist',
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-TC-33291',
        avatarUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 9,
        rating: 4.9,
        reviewCount: 94,
        languages: const ['العربية', 'English'],
        clinicId: 'elegance-downtown',
        clinicNameAr: 'مركز الأناقة الطبي للجلدية والتجميل',
        clinicNameEn: 'Elegance Medical Aesthetic Center',
        procedures: const [
          'جلسات ليزر إزالة الشعر المتقدمة',
          'تقشير الكربون والبيكو',
          'علاج التصبغات والمسام',
        ],
        proceduresEn: const [
          'Advanced Laser Hair Removal',
          'Carbon & Pico Peels',
          'Pigmentation & Pore Refining',
        ],
        aboutAr:
            'أخصائية مرخصة بخبرة واسعة في أحدث منصات الليزر والتفتيح وعلاجات النضارة.',
        aboutEn:
            'Licensed medical aesthetician with comprehensive experience in advanced laser and brightening platforms.',
      ),
      PractitionerModel(
        id: 'nurse-layla',
        nameAr: 'أ. ليلى المنصور',
        nameEn: 'Layla Al Mansoor',
        type: PractitionerType.nurse,
        specialtyAr: 'أخصائية عناية طبية بالبشرة والهيدرافيسيال',
        specialtyEn: 'Certified Clinical Dermal Therapist',
        classificationAr: 'أخصائي علاج بشرة معتمد',
        classificationEn: 'Certified Clinical Skin Therapist',
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-SK-88120',
        avatarUrl:
            'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 7,
        rating: 4.87,
        reviewCount: 52,
        languages: const ['العربية', 'English'],
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية والتجميل',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        procedures: const [
          'بروتوكولات الهيدرافيسيال البلاتيني',
          'العلاج بالإنزيمات والترطيب العميق',
          'مساج تصريف السوائل اللمفاوي للوجه',
        ],
        proceduresEn: const [
          'Platinum HydraFacial Protocols',
          'Enzyme Treatment & Deep Hydration',
          'Facial Lymphatic Drainage Massage',
        ],
        aboutAr:
            'أخصائية بشرة مرخصة ذات خبرة عالية في تنظيف وترميم حاجز البشرة والتخلص من الإجهاد الجلدي.',
        aboutEn:
            'Certified clinical dermal therapist specialized in skin barrier restoration and deep revitalizing treatments.',
      ),
      PractitionerModel(
        id: 'spec-sara',
        nameAr: 'أ. سارة بن علي',
        nameEn: 'Sara Benali',
        type: PractitionerType.licensedProfessional,
        specialtyAr: 'أخصائية تقشير كيميائي وعلاجات التجديد',
        specialtyEn: 'Licensed Chemical Peel & Skin Renewal Specialist',
        classificationAr: 'أخصائي تجميل مرخص',
        classificationEn: 'Licensed Dermal Specialist',
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-CP-44019',
        avatarUrl:
            'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 10,
        rating: 4.92,
        reviewCount: 81,
        languages: const ['العربية', 'Français', 'English'],
        clinicId: 'elegance-downtown',
        clinicNameAr: 'مركز الأناقة الطبي للجلدية والتجميل',
        clinicNameEn: 'Elegance Medical Aesthetic Center',
        procedures: const [
          'جلسات التقشير الكيميائي الطبي',
          'علاج آثار حب الشباب بالديرمابن',
          'توحيد لون البشرة والرقبة',
        ],
        proceduresEn: const [
          'Medical Chemical Peels',
          'Microneedling Acne Scar Correction',
          'Neck & Decollete Tone Unification',
        ],
        aboutAr:
            'أخصائية فرنسية معتمدة متمرسة في حلول تجديد خلايا البشرة والتقشير الطبي الآمن.',
        aboutEn:
            'French-certified dermal specialist with mastery in safe medical peels and cellular renewal therapies.',
      ),
      PractitionerModel(
        id: 'nurse-mariam',
        nameAr: 'أ. مريم الكعبي',
        nameEn: 'Mariam Al Kaabi',
        type: PractitionerType.nurse,
        specialtyAr: 'ممرض مرخص - رعاية واستشارات ما بعد التجميل',
        specialtyEn: 'Registered Aesthetic & Post-Care Nurse',
        classificationAr: 'ممرض تجميلي مرخص',
        classificationEn: 'Licensed Aesthetic Nurse',
        licenseAuthority: 'Medical Board',
        licenseNumber: 'LIC-N-66109',
        avatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 6,
        rating: 4.8,
        reviewCount: 39,
        languages: const ['العربية', 'English'],
        clinicId: 'bateen-derma-abudhabi',
        clinicNameAr: 'عيادة البطين التخصصية للجلدية',
        clinicNameEn: 'Al Bateen Specialized Derma Clinic',
        procedures: const [
          'العناية الطبية بحاجز البشرة',
          'جلسات الترطيب المكثف بالفيتامينات',
          'المتابعة السريرية بعد الإجراءات',
        ],
        proceduresEn: const [
          'Skin Barrier Clinical Care',
          'Vitamin Infusion Intensive Sessions',
          'Post-procedure Clinical Follow-up',
        ],
        aboutAr:
            'ممرضة متخصصة في تقديم الاستشارات الدقيقة للعناية بالبشرة وضمان أفضل نتائج علاجية مستدامة.',
        aboutEn:
            'Specialized aesthetic nurse dedicated to post-procedure skin health and lasting clinical outcomes.',
      ),
    ];

    _treatments = [
      // 1. Plastic Surgery (الجراحة التجميلية)
      TreatmentModel(
        id: 'rhinoplasty-sculpt',
        nameAr: 'جراحة تجميل ونحت الأنف الدقيقة',
        nameEn: 'Precision Aesthetic Rhinoplasty',
        categoryAr: 'جراحة تجميلية',
        categoryEn: 'Plastic Surgery',
        descriptionAr:
            'إجراء جراحي دقيق لتصحيح وتنسيق شكل الأنف وتحسين التنفس وتناسق ملامح الوجه بإشراف استشاري جراحة معتمد.',
        descriptionEn:
            'Precision surgical procedure to refine nasal contours and harmonize facial proportions by consultant surgeons.',
        durationText: '2 - 3 ساعات',
        durationTextEn: '2 - 3 hours',
        downtimeText: '7 - 10 أيام للتعافي الأولي',
        downtimeTextEn: '7 - 10 days initial recovery',
        targetAreaAr: 'الأنف ومحيط الوجه',
        targetAreaEn: 'Nose & Central Face',
        clinicsCount: 14,
        imageUrl:
            'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=800&q=80',
      ),
      TreatmentModel(
        id: 'blepharoplasty-lift',
        nameAr: 'شد وتجميل الجفون العلوية والسفلية',
        nameEn: 'Eyelid Blepharoplasty & Eye Refresh',
        categoryAr: 'جراحة تجميلية',
        categoryEn: 'Plastic Surgery',
        descriptionAr:
            'إزالة الجلد الزائد والانتفاخات الدهنية حول العينين لإطلالة شابة ومنتعشة والتخلص من مظهر الإرهاق.',
        descriptionEn:
            'Removal of excess skin and under-eye fat bags to restore a youthful, energetic, and open eye appearance.',
        durationText: '45 - 60 دقيقة',
        durationTextEn: '45 - 60 mins',
        downtimeText: '5 - 7 أيام',
        downtimeTextEn: '5 - 7 days',
        targetAreaAr: 'الجفون ومحيط العينين',
        targetAreaEn: 'Upper & Lower Eyelids',
        clinicsCount: 18,
        imageUrl:
            'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
      ),
      TreatmentModel(
        id: 'vaser-lipo',
        nameAr: 'شفط الدهون ونحت القوام بالفيزر 4D',
        nameEn: 'Vaser 4D High-Definition Liposuction',
        categoryAr: 'جراحة تجميلية',
        categoryEn: 'Plastic Surgery',
        descriptionAr:
            'تقنية الموجات فوق الصوتية المتقدمة لإذابة الدهون بدقة عالية ونحت عضلات البطن والخصر والذراعين.',
        descriptionEn:
            'Advanced ultrasound-assisted body sculpting to dissolve targeted fat and highlight athletic muscle definition.',
        durationText: '1.5 - 2.5 ساعة',
        durationTextEn: '1.5 - 2.5 hours',
        downtimeText: '4 - 7 أيام مع ارتداء المشد',
        downtimeTextEn: '4 - 7 days with compression garment',
        targetAreaAr: 'البطن، الخصر، الذراعين، الفخذين',
        targetAreaEn: 'Abdomen, Flanks, Arms, Thighs',
        clinicsCount: 16,
        imageUrl:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
      ),
      TreatmentModel(
        id: 'facelift-mini',
        nameAr: 'شد الوجه المصغر والرقبة الجراحي',
        nameEn: 'Mini Surgical Facelift & Neck Contouring',
        categoryAr: 'جراحة تجميلية',
        categoryEn: 'Plastic Surgery',
        descriptionAr:
            'شد الأنسجة العميقة والجلد المترهل في منتصف وأسفل الوجه والرقبة عبر شقوق دقيقة غير ظاهرة خلف الأذن.',
        descriptionEn:
            'Tightening deep SMAS tissues and sagging jawline skin through discreet incisions for natural rejuvenation.',
        durationText: '2 - 3 ساعات',
        durationTextEn: '2 - 3 hours',
        downtimeText: '10 - 14 يوماً',
        downtimeTextEn: '10 - 14 days',
        targetAreaAr: 'أسفل الوجه، خط الفك، الرقبة',
        targetAreaEn: 'Lower Face, Jawline, Neck',
        clinicsCount: 12,
        imageUrl:
            'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
      ),

      // 2. Injectables & Fillers (الحقن التجميلي)
      TreatmentModel(
        id: 'botox-allergan',
        nameAr: 'حقن البوتوكس للوجه (Allergan)',
        nameEn: 'Facial Botox Injections (Allergan)',
        categoryAr: 'علاجات الحقن',
        categoryEn: 'Injectables',
        descriptionAr:
            'إجراء طبي لتنعيم تجاعيد الجبهة وحول العينين وخطوط الابتسامة باستخدام أجود أنواع البوتوكس المعتمد عالمياً.',
        descriptionEn:
            'Medical procedure to smooth forehead wrinkles, crow\'s feet and smile lines using world-class certified Botox.',
        durationText: '15 - 20 دقيقة',
        durationTextEn: '15 - 20 mins',
        downtimeText: 'بدون فترة تعافي (مباشر)',
        downtimeTextEn: 'Zero Downtime',
        targetAreaAr: 'الجبهة وحول العين والأنف',
        targetAreaEn: 'Forehead, Crow\'s feet & Nose',
        clinicsCount: 38,
        imageUrl:
            'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
      ),
      TreatmentModel(
        id: 'profhilo-lift',
        nameAr: 'إبر النضارة وشد البشرة (بروفايلو)',
        nameEn: 'Profhilo Bioremodeling Lift',
        categoryAr: 'علاجات الحقن',
        categoryEn: 'Injectables',
        descriptionAr:
            'علاج حيوي لتجديد خلايا البشرة وتحفيز الإيلاستين والكولاجين بتركيز نقي لحمض الهيالورونيك.',
        descriptionEn:
            'Ultra-pure hyaluronic acid bio-remodeling to stimulate collagen and elastin for visible firmness.',
        durationText: '20 - 30 دقيقة',
        durationTextEn: '20 - 30 mins',
        downtimeText: '24 ساعة كحد أقصى',
        downtimeTextEn: '24 hours max',
        targetAreaAr: 'الوجه، الرقبة، اليدين',
        targetAreaEn: 'Face, Neck, Hands',
        clinicsCount: 29,
        imageUrl:
            'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=600&q=80',
      ),

      // 3. Skincare & Lasers (عناية بالبشرة والليزر)
      TreatmentModel(
        id: 'hydrafacial-royal',
        nameAr: 'الهيدرافيسيال الملكي الطبي 7 مراحل',
        nameEn: 'Royal 7-Step Medical HydraFacial',
        categoryAr: 'عناية بالبشرة',
        categoryEn: 'Skincare',
        descriptionAr:
            'تنظيف عميق، تقشير لطيف، استخلاص الشوائب وترطيب مكثف بمضادات الأكسدة والببتيدات لنضارة فورية.',
        descriptionEn:
            'Deep clinical cleansing, gentle exfoliation, painless extraction and antioxidant infusion for immediate radiance.',
        durationText: '45 دقيقة',
        durationTextEn: '45 mins',
        downtimeText: 'نضارة فورية بدون احمرار',
        downtimeTextEn: 'Instant Glow',
        targetAreaAr: 'الوجه والرقبة',
        targetAreaEn: 'Full Face & Neck',
        clinicsCount: 42,
        imageUrl:
            'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=800&q=80',
      ),
      TreatmentModel(
        id: 'laser-rejuv',
        nameAr: 'جلسات ليزر تجديد البشرة والتصبغات',
        nameEn: 'Laser Skin Rejuvenation',
        categoryAr: 'ليزر وبشرة',
        categoryEn: 'Laser & Skin',
        descriptionAr:
            'تقنية ليزرية متقدمة لتوحيد لون البشرة وتضييق المسام وإزالة التصبغات السطحية وتحفيز الكولاجين.',
        descriptionEn:
            'Advanced fractional laser therapy to unify skin tone, refine enlarged pores, and clear hyperpigmentation.',
        durationText: '30 - 45 دقيقة',
        durationTextEn: '30 - 45 mins',
        downtimeText: '1 - 2 يوم احمرار خفيف',
        downtimeTextEn: '1 - 2 days mild redness',
        targetAreaAr: 'الوجه بالكامل',
        targetAreaEn: 'Full Face',
        clinicsCount: 35,
        imageUrl:
            'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=80',
      ),
      TreatmentModel(
        id: 'morpehus8-glow',
        nameAr: 'جلسات المورفيوس 8 لشد الجلد والمسام (Morpheus8)',
        nameEn: 'Morpheus8 RF Fractional Remodeling',
        categoryAr: 'ليزر وبشرة',
        categoryEn: 'Laser & Skin',
        descriptionAr:
            'دمج تقنية الوخز المجهري مع ترددات الراديو لاختراق الطبقات العميقة وشد الترهلات وتحسين ملمس الجلد.',
        descriptionEn:
            'Combining microneedling with radiofrequency to remodel subdermal adipose tissue and tighten contours.',
        durationText: '45 - 60 دقيقة',
        durationTextEn: '45 - 60 mins',
        downtimeText: '2 - 3 أيام',
        downtimeTextEn: '2 - 3 days',
        targetAreaAr: 'الوجه، خط الفك، الرقبة',
        targetAreaEn: 'Full Face, Jawline, Neck',
        clinicsCount: 26,
        imageUrl:
            'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80',
      ),
      TreatmentModel(
        id: 'pico-pigment',
        nameAr: 'ليزر البيكوشور لتفتيح التصبغات والكلف',
        nameEn: 'PicoSure Laser Melasma & Pigment Clearing',
        categoryAr: 'ليزر وبشرة',
        categoryEn: 'Laser & Skin',
        descriptionAr:
            'نبضات بيكوثانية فائقة السرعة لتفتيت جزيئات التصبغات العنيدة بدون تسخين حراري مؤلم للبشرة.',
        descriptionEn:
            'Ultra-short picosecond pulses to shatter stubborn pigment without damaging surrounding tissue.',
        durationText: '30 دقيقة',
        durationTextEn: '30 mins',
        downtimeText: 'ساعات قليلة',
        downtimeTextEn: 'Few hours',
        targetAreaAr: 'الوجه واليدين',
        targetAreaEn: 'Face & Hands',
        clinicsCount: 22,
        imageUrl:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80',
      ),
    ];

    _offers = [
      OfferModel(
        id: 'offer-glow-summer',
        titleAr: 'باكج نضارة البشرة الصيفي المتكامل',
        titleEn: 'Summer Glow Medical Package',
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية - جميرا',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        originalPrice: 1800,
        offerPrice: 1250,
        discountPercentage: 30,
        validUntilText: 'صالح حتى 31 أغسطس 2026',
        validUntilTextEn: 'Valid until 31 Aug 2026',
        daysRemaining: 4,
        termsAr:
            'العرض يشمل استشارة طبية مجانية وجلسة هيدرافيسيال ملكي + جلسة ميزوثيرابي نضارة. ينطبق في فرع جميرا.',
        termsEn:
            'Package includes complimentary medical consultation, Royal HydraFacial, and mesotherapy radiance session.',
        imageUrl:
            'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80',
      ),
      OfferModel(
        id: 'offer-botox-package',
        titleAr: 'عرض البوتوكس الطبي لمنطقتين',
        titleEn: 'Dual Area Medical Botox Offer',
        clinicId: 'elegance-downtown',
        clinicNameAr: 'مركز الأناقة الطبي - داون تاون',
        clinicNameEn: 'Elegance Medical Center - Downtown',
        originalPrice: 2200,
        offerPrice: 1650,
        discountPercentage: 25,
        validUntilText: 'صالح حتى 15 سبتمبر 2026',
        validUntilTextEn: 'Valid until 15 Sep 2026',
        daysRemaining: 18,
        termsAr:
            'بإشراف استشاري جلدية مرخص، يشمل مراجعة وتعديل مجاني خلال أسبوعين.',
        termsEn:
            'Administered by licensed dermatologist consultant. Includes free touch-up review within 2 weeks.',
        imageUrl:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80',
      ),
      OfferModel(
        id: 'offer-profhilo-glow',
        titleAr: 'جلسة البروفايلو الحيوية لشد الرقبة والوجه',
        titleEn: 'Profhilo Bio-Lift Face & Neck Session',
        clinicId: 'novomed-marina',
        clinicNameAr: 'مستشفى نوفوميد لجراحة اليوم الواحد والتجميل',
        clinicNameEn: 'Novomed Specialized Surgical Center',
        originalPrice: 2500,
        offerPrice: 1850,
        discountPercentage: 26,
        validUntilText: 'صالح حتى 20 سبتمبر 2026',
        validUntilTextEn: 'Valid until 20 Sep 2026',
        daysRemaining: 23,
        termsAr:
            'يشمل استشارة سريرية ومخطط علاج مخصص لحمض الهيالورونيك عالي النقاء.',
        termsEn:
            'Includes clinical consultation and bespoke high-purity hyaluronic acid treatment mapping.',
        imageUrl:
            'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=600&q=80',
      ),
      OfferModel(
        id: 'offer-pico-clear',
        titleAr: 'باكج 3 جلسات ليزر بيكو لعلاج التصبغات',
        titleEn: '3-Session Pico Laser Pigment Clearing',
        clinicId: 'bateen-derma-abudhabi',
        clinicNameAr: 'عيادة البطين التخصصية للجلدية',
        clinicNameEn: 'Al Bateen Specialized Derma Clinic',
        originalPrice: 3600,
        offerPrice: 2700,
        discountPercentage: 25,
        validUntilText: 'صالح حتى 30 سبتمبر 2026',
        validUntilTextEn: 'Valid until 30 Sep 2026',
        daysRemaining: 33,
        termsAr:
            'جلسات متتابعة بفاصل شهر لتوحيد لون البشرة بإشراف أخصائي الجلدية.',
        termsEn:
            'Monthly spaced sessions for complete pigment clearance by certified dermatologists.',
        imageUrl:
            'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=80',
      ),
    ];

    // Products (Medical Skincare, Cosmeceuticals & Beauty Devices)
    _products = [
      ProductModel(
        id: 'prod-skinceuticals-ce',
        nameAr: 'سيروم فيتامين سي C E Ferulic الطبي',
        nameEn: 'SkinCeuticals C E Ferulic Antioxidant Serum',
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية والتجميل',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        descriptionAr:
            'سيروم مضاد أكسدة طبي ثلاثي حائز على جوائز عالمية، يحمي البشرة من العوامل البيئية ويمنحها إشراقة متألقة.',
        descriptionEn:
            'Triple antioxidant clinical serum with 15% pure Vitamin C, protecting against environmental aging and boosting radiance.',
        price: 680,
        originalPrice: 750,
        imageUrl:
            'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=600&q=80',
        categoryAr: 'مستحضرات علاجية',
        categoryEn: 'Cosmeceuticals',
        isAvailable: true,
      ),
      ProductModel(
        id: 'prod-zo-growth',
        nameAr: 'سيروم محفز النمو والنضارة ZO Skin Health',
        nameEn: 'ZO Skin Health Growth Factor Serum',
        clinicId: 'elegance-downtown',
        clinicNameAr: 'مركز الأناقة الطبي للجلدية والتجميل',
        clinicNameEn: 'Elegance Medical Aesthetic Center',
        descriptionAr:
            'تركيبة طبية متطورة من عوامل النمو المشتقة من النبات والإنزيمات لتحسين مرونة وامتلاء الخطوط الدقيقة.',
        descriptionEn:
            'Formulated with plant- and enzymatically derived growth factors to improve overall skin firmness and density.',
        price: 720,
        originalPrice: 800,
        imageUrl:
            'https://images.unsplash.com/photo-1608248597359-00994f85e492?auto=format&fit=crop&w=600&q=80',
        categoryAr: 'عناية بالبشرة',
        categoryEn: 'Skincare',
        isAvailable: true,
      ),
      ProductModel(
        id: 'prod-heliocare-sun',
        nameAr: 'واقي شمس طبي معدني SPF 50+ Heliocare 360',
        nameEn: 'Heliocare 360 Mineral Tolerance Fluid SPF 50+',
        clinicId: 'bateen-derma-abudhabi',
        clinicNameAr: 'عيادة البطين التخصصية للجلدية',
        clinicNameEn: 'Al Bateen Specialized Derma Clinic',
        descriptionAr:
            'حماية شاملة فائقة للبشرة الحساسة وما بعد جلسات الليزر ضد الأشعة فوق البنفسجية والأشعة المرئية والأشعة تحت الحمراء.',
        descriptionEn:
            '100% mineral sunscreen fluid ideal for sensitive and post-procedure skin, shielding against UVA/UVB and HEVL.',
        price: 210,
        originalPrice: 240,
        imageUrl:
            'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=600&q=80',
        categoryAr: 'واقيات شمس ومكملات',
        categoryEn: 'Sun Care & Supplements',
        isAvailable: true,
      ),
      ProductModel(
        id: 'prod-nuface-device',
        nameAr: 'جهاز تحفيز وشد عضلات الوجه NuFACE Trinity',
        nameEn: 'NuFACE Trinity Microcurrent Facial Toning Device',
        clinicId: 'novomed-marina',
        clinicNameAr: 'مستشفى نوفوميد لجراحة اليوم الواحد والتجميل',
        clinicNameEn: 'Novomed Specialized Surgical Center',
        descriptionAr:
            'جهاز منزلي معتمد بتقنية التيارات المجهرية (Microcurrent) لشد عضلات الوجه وخط الفك وتنشيط الدورة الدموية.',
        descriptionEn:
            'Advanced at-home microcurrent device designed to tone facial contours, improve jawline definition and stimulate skin vitality.',
        price: 1450,
        originalPrice: 1650,
        imageUrl:
            'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=600&q=80',
        categoryAr: 'أجهزة منزلية',
        categoryEn: 'Home Devices',
        isAvailable: true,
      ),
      ProductModel(
        id: 'prod-led-mask',
        nameAr: 'قناع العلاج الضوئي LED المنزلي لنضارة البشرة',
        nameEn: 'Clinical LED Light Therapy Face Mask',
        clinicId: 'elegance-downtown',
        clinicNameAr: 'مركز الأناقة الطبي للجلدية والتجميل',
        clinicNameEn: 'Elegance Medical Aesthetic Center',
        descriptionAr:
            'قناع سيليكون طبي مرن يدمج الضوء الأحمر والأشعة تحت الحمراء القريبة لتحفيز الكولاجين وتهدئة الالتهابات.',
        descriptionEn:
            'Flexible medical-grade silicone LED mask delivering dual red and near-infrared wavelengths for collagen synthesis.',
        price: 1850,
        originalPrice: 2100,
        imageUrl:
            'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80',
        categoryAr: 'أجهزة منزلية',
        categoryEn: 'Home Devices',
        isAvailable: true,
      ),
      ProductModel(
        id: 'prod-obagi-clarify',
        nameAr: 'سيروم توحيد وتفتيح البشرة Obagi Nu-Derm Clear',
        nameEn: 'Obagi Medical Nu-Derm Skin Brightening Serum',
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية والتجميل',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        descriptionAr:
            'تركيبة طبية متخصصة لتقليل التصبغات العميقة وبقع الشمس وتوحيد لون البشرة بإشراف الأطباء.',
        descriptionEn:
            'Medical-grade brightening lotion formulated to correct hyperpigmentation and reveal a clear, even complexion.',
        price: 540,
        imageUrl:
            'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?auto=format&fit=crop&w=600&q=80',
        categoryAr: 'مستحضرات علاجية',
        categoryEn: 'Cosmeceuticals',
        isAvailable: true,
      ),
    ];

    // Articles (Medical Aesthetic Guides & Articles)
    _articles = [
      ArticleModel(
        id: 'art-botox-vs-filler',
        titleAr:
            'الفروقات الطبية الدقيقة بين البوتوكس والفيلر: كيف تختارين الإجراء الأنسب لملامحك؟',
        titleEn:
            'Botox vs Dermal Fillers: Clinical Differences & Choosing the Right Treatment for You',
        coverImageUrl:
            'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
        summaryAr:
            'دليل طبي مفصل يوضح آلية عمل كل من توكسين البوتولينوم وحمض الهيالورونيك، ومناطق الحقن الأنسب لكل منهما لتحقيق نتائج طبيعية متناسقة.',
        summaryEn:
            'A comprehensive medical guide on how botulinum toxin and hyaluronic acid work, ideal target areas, and achieving natural harmony.',
        contentAr: '''
يقع الكثير في خلط شائع بين حقن البوتوكس والفيلر، رغم اختلافهما الجذري في المادة الفعالة وآلية التأثير:

1. البوتوكس (Botox):
يعمل البوتوكس على إرخاء العضلات التعبيرية المسببة للتجاعيد الحركية مثل خطوط الجبهة، ما بين الحاجبين (خطوط الغضب)، وحول العينين. لا يمنح البوتوكس حجماً إضافياً، بل يمنع انقباض العضلة لتبدو البشرة ناعمة ومرتاحة.

2. الفيلر (Dermal Fillers):
يتكون الفيلر بشكل أساسي من حمض الهيالورونيك الطبيعي، ويهدف إلى استعادة الحجم المفقود ونحت الملامح مثل تعبئة الوجنتين، الشفاه، خط الفك، أو ملء التجاعيد الثابتة (مثل خطوط الابتسامة).

نصيحة الاستشاري:
الجمع بين الإجرائين بتوازن دقيق وفق خطة علاجية مخصصة هو المفتاح السحري لإطلالة متجددة وطبيعية بدون أي مبالغة.
''',
        contentEn: '''
A common question in clinical dermatology is the precise difference between Botox and Dermal Fillers:

1. Botox (Neuromodulators):
Relaxes expressive muscles that cause dynamic wrinkles such as forehead lines, frown lines, and crow's feet. It does not add volume; it smooths motion-induced creases.

2. Dermal Fillers:
Formulated primarily with biocompatible hyaluronic acid, fillers restore lost volume and sculpt facial contours—such as cheeks, lips, and jawlines.

Consultant Tip:
Harmonious integration of both modalities tailored to your facial anatomy yields the most authentic and refreshed results.
''',
        authorDoctorId: 'dr-reem',
        authorDoctorNameAr: 'د. ريم الخالد',
        authorDoctorNameEn: 'Dr. Reem Al Khaled',
        authorDoctorSpecialtyAr: 'استشاري أمراض جلدية وطب تجميلي',
        authorDoctorSpecialtyEn:
            'Consultant Dermatologist & Aesthetic Medicine',
        authorDoctorAvatar:
            'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=300&q=80',
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية والتجميل',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        categoryAr: 'الفيلر والبوتوكس',
        categoryEn: 'Fillers & Botox',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ArticleModel(
        id: 'art-laser-care',
        titleAr:
            'بروتوكول العناية بالبشرة بعد جلسات الليزر: نصائح لتجنب التصبغات وتسريع التعافي',
        titleEn:
            'Post-Laser Clinical Skincare Protocol: Preventing Hyperpigmentation & Optimizing Healing',
        coverImageUrl:
            'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=800&q=80',
        summaryAr:
            'أهم الخطوات السريرية الموصى بها طبياً لترطيب وحماية البشرة بعد جلسات الليزر والتقشير في طقس الإمارات الحار.',
        summaryEn:
            'Essential clinical steps to soothe, hydrate, and shield skin after laser and peeling procedures in warm climates.',
        contentAr: '''
تعتبر فترة ما بعد جلسة الليزر مرحلة حاسمة تحدد 50% من نجاح النتيجة النهائية:

1. الترطيب المكثف بحمض الهيالورونيك والبانثينول:
تكون البشرة في حالة جفاف مؤقت بعد التعرض للحرارة، لذا يجب استخدام كريمات ترميمية خالية من العطور والكحول.

2. الحماية الصارمة من الشمس:
تجنب التعرض المباشر لأشعة الشمس، وتطبيق واقي شمس معدني واسع الطيف (SPF 50+) كل ساعتين عند الخروج.

3. تجنب المقشرات والريتينول:
يجب إيقاف استخدام أحماض الفواكه وفيتامين أ لمدة 5 إلى 7 أيام بعد الجلسة لتجنب تحسس الجلد أو ظهور تصبغات ما بعد الالتهاب.
''',
        contentEn: '''
Post-laser care determines up to 50% of the overall clinical outcome:

1. Intensive Hydration & Barrier Repair:
Use fragrance-free, panthenol and hyaluronic-infused restorative creams.

2. Non-Negotiable Broad-Spectrum Sunscreen:
Apply mineral SPF 50+ every 2 hours when outdoors to prevent post-inflammatory hyperpigmentation.

3. Pause Retinoids & Actives:
Avoid AHA/BHA and retinoids for 5 to 7 days post-treatment.
''',
        authorDoctorId: 'dr-elena',
        authorDoctorNameAr: 'د. إيلينا روستوفا',
        authorDoctorNameEn: 'Dr. Elena Rostova',
        authorDoctorSpecialtyAr: 'أخصائي أمراض جلدية وعلاجات الليزر',
        authorDoctorSpecialtyEn: 'Specialist Dermatologist & Laser Therapy',
        authorDoctorAvatar:
            'https://images.unsplash.com/photo-1594824813579-24535316db13?auto=format&fit=crop&w=300&q=80',
        clinicId: 'bateen-derma-abudhabi',
        clinicNameAr: 'عيادة البطين التخصصية للجلدية',
        clinicNameEn: 'Al Bateen Specialized Derma Clinic',
        categoryAr: 'علاجات الليزر',
        categoryEn: 'Laser Treatments',
        publishedAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      ArticleModel(
        id: 'art-skin-boosters',
        titleAr:
            'إبر النضارة والبروفايلو: الثورة الجديدة لترطيب الجلد العميق بدون زيادة في الحجم',
        titleEn:
            'Profhilo & Skin Boosters: The New Era of Deep Hydration Without Unnatural Volume',
        coverImageUrl:
            'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=800&q=80',
        summaryAr:
            'كيف تعمل محفزات الكولاجين وحمض الهيالورونيك عالي النقاء على تحسين مرونة وملمس الجلد واستعادة النضارة الطبيعية.',
        summaryEn:
            'How pure hyaluronic acid bioremodeling stimulates collagen synthesis to restore firmness and natural hydration.',
        contentAr: '''
تعد تقنية البروفايلو (Profhilo) وإبر النضارة الذكية خياراً مثالياً لمن يبحث عن ترطيب عميق وإشراقة صحية دون تغيير في ملامح الوجه أو زيادة في الحجم:

- انتشار متجانس: يتدفق حمض الهيالورونيك النقي عبر طبقات الجلد ليغذي الخلايا ويعيد بناء الكولاجين والإيلاستين.
- نتائج سريعة: يبدأ التحسن الملموس في نعومة ومرونة البشرة خلال أسبوعين من الجلسة الأولى.
- تناسب مختلف الأعمار: ممتازة للوقاية المبكرة من علامات التقدم بالسن وعلاج إرهاق البشرة.
''',
        contentEn: '''
Profhilo bioremodeling represents an innovative approach for deep dermal hydration without altering facial shape or adding volume:

- High-Purity Diffusion: Hyaluronic acid spreads smoothly beneath the dermis to stimulate collagen.
- Natural Radiance: Enhanced elasticity and firm glow visible within 2 weeks.
- Ideal Prevention: Excellent for counteracting climate stress and early aging signs.
''',
        authorDoctorId: 'dr-mansoori',
        authorDoctorNameAr: 'د. أحمد المنصوري',
        authorDoctorNameEn: 'Dr. Ahmed Al Mansoori',
        authorDoctorSpecialtyAr: 'استشاري طب تجميلي ونحت وجه',
        authorDoctorSpecialtyEn:
            'Consultant Aesthetic Medicine & Facial Sculpting',
        authorDoctorAvatar:
            'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=300&q=80',
        clinicId: 'bateen-derma-abudhabi',
        clinicNameAr: 'عيادة البطين التخصصية للجلدية',
        clinicNameEn: 'Al Bateen Specialized Derma Clinic',
        categoryAr: 'نضارة وتجديد البشرة',
        categoryEn: 'Skin Glow & Renewal',
        publishedAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
      ArticleModel(
        id: 'art-plastic-rhino',
        titleAr:
            'جراحة تجميل الأنف الحديثة: كيف تحققين نتائج طبيعية ومتناسقة مع ملامح الوجه؟',
        titleEn:
            'Modern Aesthetic Rhinoplasty: Achieving Natural Balance & Optimal Nasal Harmony',
        coverImageUrl:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
        summaryAr:
            'معايير التخطيط الجراحي الحديث لتجميل الأنف مع مراعاة الوظيفة التنفسية والخصوصية التشريحية لكل مريض.',
        summaryEn:
            'Surgical planning principles in contemporary rhinoplasty balancing functional airway dynamics with aesthetic proportions.',
        contentAr: '''
تطورت جراحة تجميل الأنف (Rhinoplasty) من مجرد تصغير الهيكل العظمي إلى نحت دقيق يحترم خصوصية الملامح والوظيفة التنفسية:

1. فلسفة النتائج الطبيعية:
الهدف ليس نسخ أنف مثالي لشخص آخر، بل نحت أنف ينسجم تماماً مع زوايا الجبهة والشفاه والذقن.

2. تقنيات النحت بالموجات الدقيقة (Piezo):
تسمح بنحت العظام الدقيقة دون إحداث رضوض أو كدمات شديدة، مما يسرع فترة التعافي ويعطي دقة متناهية.

3. الفحص السريري والاستشارة:
الاستشارة المباشرة مع الجراح ومناقشة التوقعات الواقعية هي الركيزة الأولى لنجاح العملية.
''',
        contentEn: '''
Contemporary rhinoplasty focuses on structural preservation and customized harmony rather than generic reductions:

1. Personalized Proportions: Aligning nasal angles seamlessly with chin and forehead profiles.
2. Ultrasonic Piezo Technology: Precise bone contouring minimizing soft tissue bruising.
3. In-depth Clinical Consultation: Aligning aesthetic goals with realistic anatomical potential.
''',
        authorDoctorId: 'dr-khalil',
        authorDoctorNameAr: 'د. طارق خليل',
        authorDoctorNameEn: 'Dr. Tariq Khalil',
        authorDoctorSpecialtyAr: 'استشاري جراحة التجميل والترميم',
        authorDoctorSpecialtyEn: 'Consultant Plastic & Reconstructive Surgeon',
        authorDoctorAvatar:
            'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=300&q=80',
        clinicId: 'novomed-marina',
        clinicNameAr: 'مستشفى نوفوميد لجراحة اليوم الواحد والتجميل',
        clinicNameEn: 'Novomed Specialized Surgical Center',
        categoryAr: 'الجراحة التجميلية',
        categoryEn: 'Plastic Surgery',
        publishedAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];

    // Initial sample appointment lead requests
    _appointmentRequests.addAll([
      AppointmentRequestModel(
        id: 'req-1',
        referenceCode: '#REQ-98421',
        clinicId: 'kaya-jumeirah',
        clinicNameAr: 'عيادة كايا للجلدية والتجميل',
        clinicNameEn: 'Kaya Skin Clinic - Jumeirah',
        branchNameAr: 'فرع جميرا الرئيسي',
        branchNameEn: 'Jumeirah Main Flagship',
        serviceNameAr: 'جلسة الهيدرافيسيال الملكي الطبي',
        serviceNameEn: 'Royal Medical HydraFacial',
        practitionerId: 'dr-reem',
        practitionerNameAr: 'د. ريم الخالد',
        practitionerNameEn: 'Dr. Reem Al Khaled',
        practitionerType: PractitionerType.doctor,
        preferredDate: DateTime.now().add(const Duration(days: 2)),
        preferredTimeWindow: PreferredTimeWindow.evening,
        patientFullName: 'مجد سامر خليفة',
        patientPhone: '+971 50 123 4567',
        notes: 'يرجى التنسيق للفترة المسائية بعد الساعة 5',
        consentAccepted: true,
        status: AppointmentLeadStatus.sent,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      AppointmentRequestModel(
        id: 'req-2',
        referenceCode: '#REQ-83190',
        clinicId: 'elegance-downtown',
        clinicNameAr: 'مركز الأناقة الطبي للجلدية والتجميل',
        clinicNameEn: 'Elegance Medical Aesthetic Center',
        branchNameAr: 'فرع داون تاون الرئيسي',
        branchNameEn: 'Downtown Flagship',
        serviceNameAr: 'حقن البوتوكس الطبي للوجه',
        serviceNameEn: 'Full Face Medical Botox',
        practitionerId: 'dr-reem',
        practitionerNameAr: 'د. ريم الخالد',
        practitionerNameEn: 'Dr. Reem Al Khaled',
        practitionerType: PractitionerType.doctor,
        preferredDate: DateTime.now().subtract(const Duration(days: 1)),
        preferredTimeWindow: PreferredTimeWindow.afternoon,
        patientFullName: 'مجد سامر خليفة',
        patientPhone: '+971 50 123 4567',
        consentAccepted: true,
        status: AppointmentLeadStatus.contacted,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }
}
