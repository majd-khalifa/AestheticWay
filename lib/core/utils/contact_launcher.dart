import 'package:url_launcher/url_launcher.dart';

/// Direct Contact Launcher (Call & WhatsApp)
abstract class ContactLauncher {
  /// Approved Platform Customer Support phone & WhatsApp number (+971581989252)
  static const String platformSupportPhone = '+971581989252';
  static const String platformSupportPhoneDisplay = '+971 58 198 9252';

  /// Initiates a direct phone call to clinic, practitioner or platform support
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Opens direct WhatsApp chat with clinic reception or recipient
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    String message = 'مرحباً، أود الاستفسار عن الخدمات والعيادة عبر تطبيق AESTHETIC WAY.',
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$cleanPhone?text=$encodedMessage';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens direct WhatsApp chat with Aesthetic Way Platform Support (+971581989252)
  static Future<bool> openPlatformSupportWhatsApp({
    String message = 'مرحباً، أود التواصل مع خدمة عملاء منصة AESTHETIC WAY.',
  }) async {
    return openWhatsApp(phoneNumber: platformSupportPhone, message: message);
  }

  /// Initiates direct phone call to Aesthetic Way Platform Support (+971581989252)
  static Future<bool> callPlatformSupport() async {
    return makePhoneCall(platformSupportPhone);
  }
}
