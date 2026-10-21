import 'package:aesthetic_way/core/network/api_client.dart';
import 'package:aesthetic_way/core/network/api_config.dart';
import 'package:aesthetic_way/core/utils/contact_launcher.dart';

/// Platform Support Information Model
class SupportInfoModel {
  final String phone;
  final String phoneDisplay;
  final String whatsapp;
  final String email;
  final String workingHoursAr;
  final String workingHoursEn;

  const SupportInfoModel({
    required this.phone,
    required this.phoneDisplay,
    required this.whatsapp,
    required this.email,
    required this.workingHoursAr,
    required this.workingHoursEn,
  });

  factory SupportInfoModel.fallback() {
    return const SupportInfoModel(
      phone: ContactLauncher.platformSupportPhone,
      phoneDisplay: ContactLauncher.platformSupportPhoneDisplay,
      whatsapp: ContactLauncher.platformSupportPhone,
      email: 'support@aestheticway.ae',
      workingHoursAr: 'يومياً: 9:00 ص - 9:00 م',
      workingHoursEn: 'Daily: 9:00 AM - 9:00 PM',
    );
  }

  factory SupportInfoModel.fromJson(Map<String, dynamic> json) {
    final phone =
        json['phone']?.toString().trim() ??
        ContactLauncher.platformSupportPhone;
    final whatsapp = json['whatsapp']?.toString().trim() ?? phone;
    return SupportInfoModel(
      phone: phone.isNotEmpty ? phone : ContactLauncher.platformSupportPhone,
      phoneDisplay:
          (json['phone_display']?.toString().trim().isNotEmpty ?? false)
          ? json['phone_display']!.toString().trim()
          : ContactLauncher.platformSupportPhoneDisplay,
      whatsapp: whatsapp.isNotEmpty
          ? whatsapp
          : ContactLauncher.platformSupportPhone,
      email: json['email']?.toString().trim().isNotEmpty == true
          ? json['email']!.toString().trim()
          : 'support@aestheticway.ae',
      workingHoursAr:
          json['working_hours_ar']?.toString().trim().isNotEmpty == true
          ? json['working_hours_ar']!.toString().trim()
          : 'يومياً: 9:00 ص - 9:00 م',
      workingHoursEn:
          json['working_hours_en']?.toString().trim().isNotEmpty == true
          ? json['working_hours_en']!.toString().trim()
          : 'Daily: 9:00 AM - 9:00 PM',
    );
  }
}

/// Service for fetching and caching platform-wide customer support contact info
class SupportService {
  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;
  SupportService._internal();

  final ApiClient _api = ApiClient();
  SupportInfoModel _cached = SupportInfoModel.fallback();

  SupportInfoModel get info => _cached;

  Future<SupportInfoModel> fetchSupportInfo() async {
    try {
      final res = await _api.get(ApiConfig.supportInfo);
      if (res.data is Map<String, dynamic>) {
        _cached = SupportInfoModel.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback to static verified platform numbers
    }
    return _cached;
  }
}
