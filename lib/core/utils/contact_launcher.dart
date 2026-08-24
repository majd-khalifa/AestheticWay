import 'package:url_launcher/url_launcher.dart';

/// Direct Contact Launcher (Call & WhatsApp)
abstract class ContactLauncher {
  /// Initiates a direct phone call to clinic or practitioner
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Opens direct WhatsApp chat with clinic reception
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
}
