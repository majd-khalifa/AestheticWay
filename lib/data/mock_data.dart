import 'package:flutter/material.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/appointment_lead/models/appointment_request_model.dart';

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
  final List<AppointmentRequestModel> _appointmentRequests = [];

  List<ClinicModel> get clinics => _clinics;
  List<PractitionerModel> get practitioners => _practitioners;
  List<TreatmentModel> get treatments => _treatments;
  List<OfferModel> get offers => _offers;
  List<AppointmentRequestModel> get appointmentRequests => _appointmentRequests;

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

  void addAppointmentRequest(AppointmentRequestModel request) {
    _appointmentRequests.insert(0, request);
    notifyListeners();
  }

  void _initData() {
    _clinics = [
      ClinicModel(
        id: 'kaya-jumeirah',
        nameAr: 'عيادة كايا للجلدية والتجميل',
        nameEn: 'Kaya Skin Clinic - Jumeirah',
        descriptionAr:
            'مركز رائد في علاجات البشرة والجلدية والتجميل الطبي في دبي مع كادر معتمد من هيئة الصحة بدبي وأحدث أجهزة الليزر العالمية.',
        descriptionEn:
            'Leading medical aesthetic and dermatology center in Dubai featuring DHA certified doctors and latest laser tech.',
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
        licenseAuthority: 'DHA',
        licenseNumber: 'DHA-FL-009824',
        city: 'Dubai',
        areaAr: 'جميرا 1',
        areaEn: 'Jumeirah 1',
        addressAr: 'شارع شاطئ جميرا، فيلا 24، دبي',
        addressEn: 'Jumeirah Beach Road, Villa 24, Dubai',
        distanceKm: 2.4,
        mainPhone: '+97143009988',
        receptionPhone: '+97143009900',
        whatsapp: '+971501112233',
        googlePlaceId: 'ChIJ55m5W_bCXz4R7X8H_3d8Jrk',
        latitude: 25.2144,
        longitude: 55.2588,
        workingHoursAr:
            'السبت - الخميس: 9:00 ص - 9:00 م | الجمعة: 1:00 م - 8:00 م',
        workingHoursEn: 'Sat - Thu: 9:00 AM - 9:00 PM | Fri: 1:00 PM - 8:00 PM',
        branches: const [
          ClinicBranch(
            id: 'kaya-jumeirah-b1',
            nameAr: 'فرع جميرا الرئيسي',
            nameEn: 'Jumeirah Main Flagship',
            areaAr: 'جميرا 1',
            areaEn: 'Jumeirah 1',
            addressAr: 'شارع شاطئ جميرا، فيلا 24',
            addressEn: 'Jumeirah Beach Road, Villa 24',
            phone: '+97143009988',
            distanceKm: 2.4,
            latitude: 25.2144,
            longitude: 55.2588,
            googlePlaceId: 'ChIJ55m5W_bCXz4R7X8H_3d8Jrk',
          ),
          ClinicBranch(
            id: 'kaya-dubai-marina-b2',
            nameAr: 'فرع دبي مارينا',
            nameEn: 'Dubai Marina Branch',
            areaAr: 'مارينا جيت',
            areaEn: 'Marina Gate',
            addressAr: 'برج مارينا جيت 1، الطابق الأرضي',
            addressEn: 'Marina Gate Tower 1, Ground Floor',
            phone: '+97143009922',
            distanceKm: 14.8,
            latitude: 25.0878,
            longitude: 55.1472,
          ),
        ],
        practitionerIds: ['dr-reem', 'nurse-nour'],
        treatmentIds: ['botox-full', 'hydrafacial-royal', 'laser-rejuv'],
        featuredOffers: ['offer-glow-summer'],
      ),
      ClinicModel(
        id: 'elegance-downtown',
        nameAr: 'مركز الأناقة الطبي للجلدية والتجميل',
        nameEn: 'Elegance Medical Aesthetic Center',
        descriptionAr:
            'وجهة فاخرة تجمع بين نخبة استشاريي الجلدية والتجميل وتقنيات الحقن الفرنسية وأحدث علاجات تجديد نضارة البشرة.',
        descriptionEn:
            'Premier luxury aesthetic clinic in Downtown Dubai offering French injection techniques and state of the art skincare.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
        galleryImages: [
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=800&q=80',
        ],
        logoUrl:
            'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=200&q=80',
        rating: 4.95,
        reviewCount: 240,
        subscriptionTier: SubscriptionTier.vipPlatinum,
        licenseAuthority: 'DHA',
        licenseNumber: 'DHA-FL-004412',
        city: 'Dubai',
        areaAr: 'داون تاون دبي',
        areaEn: 'Downtown Dubai',
        addressAr: 'بوليفارد الشيخ محمد بن راشد، برج بلازا، دبي',
        addressEn: 'Sheikh Mohammed bin Rashid Blvd, Plaza Tower, Dubai',
        distanceKm: 4.8,
        mainPhone: '+97144201100',
        receptionPhone: '+97144201122',
        whatsapp: '+971502223344',
        googlePlaceId: 'ChIJdeuKzV5tXz4R3GqT4eJ_7Qc',
        latitude: 25.1972,
        longitude: 55.2744,
        workingHoursAr: 'يومياً: 10:00 ص - 10:00 م',
        workingHoursEn: 'Daily: 10:00 AM - 10:00 PM',
        branches: const [
          ClinicBranch(
            id: 'elegance-downtown-b1',
            nameAr: 'فرع داون تاون الرئيسي',
            nameEn: 'Downtown Flagship',
            areaAr: 'داون تاون',
            areaEn: 'Downtown',
            addressAr: 'بوليفارد الشيخ محمد بن راشد، برج بلازا',
            addressEn: 'Sheikh Mohammed bin Rashid Blvd, Plaza Tower',
            phone: '+97144201100',
            distanceKm: 4.8,
            latitude: 25.1972,
            longitude: 55.2744,
          ),
        ],
        practitionerIds: ['dr-reem', 'spec-dina'],
        treatmentIds: ['botox-full', 'profhilo-lift'],
        featuredOffers: ['offer-botox-package'],
      ),
      ClinicModel(
        id: 'novomed-marina',
        nameAr: 'مجمع نوفوميد الطبي التجميلي',
        nameEn: 'Novomed Medical & Aesthetic Center',
        descriptionAr:
            'مركز متكامل لجراحات التجميل غير الجراحية والليزر المتقدم بإشراف أطباء واستشاريين عالميين.',
        descriptionEn:
            'Comprehensive non-invasive aesthetic and laser clinic supervised by internationally certified consultants.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
        galleryImages: [
          'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=800&q=80',
        ],
        logoUrl:
            'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=200&q=80',
        rating: 4.8,
        reviewCount: 95,
        subscriptionTier: SubscriptionTier.featured,
        licenseAuthority: 'DHA',
        licenseNumber: 'DHA-FL-008190',
        city: 'Dubai',
        areaAr: 'دبي مارينا',
        areaEn: 'Dubai Marina',
        addressAr: 'ممشى المارينا، برج المارينا بلازا، دبي',
        addressEn: 'Marina Walk, Marina Plaza Tower, Dubai',
        distanceKm: 16.2,
        mainPhone: '+97143887700',
        receptionPhone: '+97143887711',
        whatsapp: '+971503334455',
        googlePlaceId: 'ChIJS_zR_3VpXz4R3GqTX_4eJ',
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
        practitionerIds: ['nurse-nour', 'spec-dina'],
        treatmentIds: ['hydrafacial-royal', 'laser-rejuv'],
        featuredOffers: ['offer-glow-summer'],
      ),
      ClinicModel(
        id: 'bateen-derma-abudhabi',
        nameAr: 'عيادة البطين التخصصية للجلدية',
        nameEn: 'Al Bateen Specialized Derma Clinic',
        descriptionAr:
            'عيادة متخصصة مرخصة من دائرة الصحة بأبوظبي تقدم بروتوكولات علاجية مخصصة لصحة البشرة والتجميل غير الجراحي.',
        descriptionEn:
            'DOH licensed specialized aesthetic dermatology center in Abu Dhabi offering bespoke skincare treatments.',
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
        licenseAuthority: 'DOH',
        licenseNumber: 'DOH-MF-771203',
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
        practitionerIds: ['dr-mansoori', 'spec-dina'],
        treatmentIds: ['botox-full', 'laser-rejuv'],
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
        licenseAuthority: 'DHA',
        licenseNumber: 'DHA-FL-003310',
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
      ),
    ];

    _practitioners = [
      PractitionerModel(
        id: 'dr-reem',
        nameAr: 'د. ريم الخالد',
        nameEn: 'Dr. Reem Al Khaled',
        type: PractitionerType.doctor,
        specialtyAr: 'استشاري أمراض جلدية وطب تجميلي',
        specialtyEn: 'Consultant Dermatologist & Aesthetic Medicine',
        classificationAr: 'استشاري أول جلدية وتجميل',
        classificationEn: 'Senior Consultant Dermatologist',
        licenseAuthority: 'DHA',
        licenseNumber: 'DHA-P-004812',
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
            'Canadian Board certified consultant in dermatology and aesthetic medicine with 14 years of experience across top medical centers in Dubai and Canada.',
      ),
      PractitionerModel(
        id: 'dr-mansoori',
        nameAr: 'د. أحمد المنصوري',
        nameEn: 'Dr. Ahmed Al Mansoori',
        type: PractitionerType.doctor,
        specialtyAr: 'استشاري جراحة وتجميل غير جراحي',
        specialtyEn: 'Consultant Aesthetic Medicine & Surgery',
        classificationAr: 'استشاري طب تجميلي',
        classificationEn: 'Consultant Aesthetic Physician',
        licenseAuthority: 'DOH',
        licenseNumber: 'DOH-DOC-99214',
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
          'إزالة الندبات الجراحية',
        ],
        proceduresEn: const [
          'Non-surgical Facial Contouring',
          'Profhilo Bioremodeling',
          'Surgical Scar Correction',
        ],
        aboutAr:
            'استشاري تجميل معتمد من دائرة الصحة بأبوظبي وزميل الكلية الملكية للجراحين.',
        aboutEn:
            'DOH certified aesthetic consultant and Fellow of the Royal College of Surgeons.',
      ),
      PractitionerModel(
        id: 'nurse-nour',
        nameAr: 'أ. نور الهدى صالح',
        nameEn: 'Nour El Houda Saleh',
        type: PractitionerType.nurse,
        specialtyAr: 'ممرض مرخص - حقن وعناية تجميلية',
        specialtyEn: 'Senior Registered Aesthetic Nurse',
        classificationAr: 'ممرض تجميلي مرخص',
        classificationEn: 'Licensed Aesthetic Registered Nurse',
        licenseAuthority: 'MOHAP',
        licenseNumber: 'MOH-N-982410',
        avatarUrl:
            'https://images.unsplash.com/photo-1594824813579-24535316db13?auto=format&fit=crop&w=300&q=80',
        yearsOfExperience: 8,
        rating: 4.8,
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
          'Mesotherapy Skin Boost',
          'Post-Laser Skincare Care',
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
        licenseAuthority: 'DHA',
        licenseNumber: 'DHA-TC-33291',
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
            'أخصائية مرخصة من هيئة الصحة بدبي بخبرة واسعة في أحدث منصات الليزر والتفتيح.',
        aboutEn:
            'DHA licensed medical aesthetician with comprehensive experience in advanced laser and brightening platforms.',
      ),
    ];

    _treatments = [
      TreatmentModel(
        id: 'botox-full',
        nameAr: 'حقن البوتوكس الطبي للوجه',
        nameEn: 'Full Face Medical Botox',
        categoryAr: 'حقن وتجميل وجه',
        categoryEn: 'Injectables',
        descriptionAr:
            'علاج طبي دقيق للتخلص من التجاعيد التعبيرية في الجبهة وحول العينين ورفع الحواجب.',
        descriptionEn:
            'Precision clinical treatment to eliminate expression lines, crow feet, and achieve subtle brow lift.',
        durationText: '15 - 20 دقيقة',
        durationTextEn: '15 - 20 mins',
        downtimeText: 'لا يوجد وقت تعطل',
        downtimeTextEn: 'No downtime',
        targetAreaAr: 'الجبهة، حول العينين، بين الحاجبين',
        targetAreaEn: 'Forehead, crow feet, glabella',
        clinicsCount: 38,
        imageUrl:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80',
      ),
      TreatmentModel(
        id: 'hydrafacial-royal',
        nameAr: 'جلسة الهيدرافيسيال الملكي الطبي',
        nameEn: 'Royal Medical HydraFacial',
        categoryAr: 'علاجات التجديد',
        categoryEn: 'Rejuvenation',
        descriptionAr:
            'تنظيف عميق وتقشير وترطيب للبشرة باستخدام مضادات الأكسدة وحمض الهيالورونيك.',
        descriptionEn:
            'Deep medical cleansing, extraction, and intensive antioxidant hydration with hyaluronic serums.',
        durationText: '45 - 60 دقيقة',
        durationTextEn: '45 - 60 mins',
        downtimeText: 'نضارة فورية بدون احمرار',
        downtimeTextEn: 'Instant radiance, no redness',
        targetAreaAr: 'الوجه والرقبة',
        targetAreaEn: 'Face & Neck',
        clinicsCount: 42,
        imageUrl:
            'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80',
      ),
      TreatmentModel(
        id: 'profhilo-lift',
        nameAr: 'إبر النضارة وشد البشرة (بروفايلو)',
        nameEn: 'Profhilo Bioremodeling Lift',
        categoryAr: 'حقن وتجميل وجه',
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
      TreatmentModel(
        id: 'laser-rejuv',
        nameAr: 'جلسات ليزر تجديد البشرة والتصبغات',
        nameEn: 'Laser Skin Rejuvenation',
        categoryAr: 'ليزر وبشرة',
        categoryEn: 'Laser & Skin',
        descriptionAr:
            'تقنية ليزرية متقدمة لتوحيد لون البشرة وتضييق المسام وإزالة التصبغات السطحية.',
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
            'بإشراف استشاري جلدية مرخص من DHA، يشمل مراجعة وتعديل مجاني خلال أسبوعين.',
        termsEn:
            'Administered by DHA licensed dermatologist consultant. Includes free touch-up review within 2 weeks.',
        imageUrl:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80',
      ),
    ];

    // Initial sample appointment lead requests for out-of-the-box tracking
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
