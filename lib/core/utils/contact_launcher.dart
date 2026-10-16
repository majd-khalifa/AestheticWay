import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:url_launcher/url_launcher.dart';

/// Direct Contact Launcher (Call & WhatsApp)
abstract class ContactLauncher {
  /// Approved Platform Customer Support phone & WhatsApp number (+971581989252)
  static const String platformSupportPhone = '+971581989252';
  static const String platformSupportPhoneDisplay = '+971 58 198 9252';

  /// Normalizes a phone string into E.164 UAE dialable format (`+971...`).
  static String normalizePhoneForDial(String rawPhone) {
    final trimmed = rawPhone.trim();
    if (trimmed.isEmpty) return '';
    final digitsAndPlus = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digitsAndPlus.isEmpty) return '';
    if (digitsAndPlus.startsWith('+')) {
      return digitsAndPlus;
    }
    if (digitsAndPlus.startsWith('00')) {
      return '+${digitsAndPlus.substring(2)}';
    }
    if (digitsAndPlus.startsWith('971')) {
      return '+$digitsAndPlus';
    }
    if (digitsAndPlus.startsWith('0') && digitsAndPlus.length >= 9) {
      return '+971${digitsAndPlus.substring(1)}';
    }
    return '+971$digitsAndPlus';
  }

  /// Normalizes a phone string for `https://wa.me/971XXXXXXXXX` (digits only after country code).
  static String normalizePhoneForWhatsApp(String rawPhone) {
    final dialed = normalizePhoneForDial(rawPhone);
    return dialed.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Initiates a direct phone call to clinic, practitioner or platform support
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanPhone = normalizePhoneForDial(phoneNumber);
    if (cleanPhone.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[ContactLauncher.makePhoneCall] Failed: phone field is empty (raw="$phoneNumber").',
        );
      }
      return false;
    }
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return await launchUrl(uri);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ContactLauncher.makePhoneCall] Failed to launch $uri: $e',
        );
      }
      return false;
    }
  }

  /// Opens direct WhatsApp chat with clinic reception or recipient
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    String message =
        'مرحباً، أود الاستفسار عن الخدمات والعيادة عبر تطبيق AESTHETIC WAY.',
  }) async {
    final cleanPhone = normalizePhoneForWhatsApp(phoneNumber);
    if (cleanPhone.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[ContactLauncher.openWhatsApp] Failed: whatsapp/phone field is empty (raw="$phoneNumber").',
        );
      }
      return false;
    }
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$cleanPhone?text=$encodedMessage';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ContactLauncher.openWhatsApp] Failed to launch $uri: $e',
        );
      }
      return false;
    }
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
