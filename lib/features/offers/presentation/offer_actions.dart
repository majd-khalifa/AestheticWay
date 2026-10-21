import 'package:flutter/material.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/utils/entity_id.dart';
import '../../../core/widgets/async_action_button.dart';
import '../../../core/widgets/luxury_animations.dart';
import '../../clinics/data/clinics_repository.dart';
import '../../clinics/presentation/screens/clinic_profile_screen.dart';
import '../../appointment_lead/presentation/screens/appointment_request_screen.dart';
import '../models/offer_model.dart';

/// Only the prerequisite fetch is awaited, not the pushed route's lifetime.
Future<void> openOfferClinic(
  BuildContext context,
  OfferModel offer,
  AsyncActionScope action,
  ClinicsRepository repository, {
  bool inquire = false,
}) async {
  if (!isEntityUuid(offer.clinicId) || (inquire && !isEntityUuid(offer.id))) {
    throw StateError('Unavailable clinic or offer');
  }
  final loc = LocaleService();
  if (inquire) {
    final authenticated = await action.wait(
      GuestAuthGuard.requireAuth(
        context,
        reasonTitle: loc.tr('offer_claim'),
        reasonSubtitle: loc.isArabic
            ? 'سجّل دخولك للاستفسار عن العرض'
            : 'Sign in to inquire about this offer',
      ),
    );
    if (!authenticated) return;
  }
  final clinic = await action.wait(repository.getClinicDetail(offer.clinicId));
  if (!context.mounted) return;
  Navigator.push(
    context,
    LuxuryPageRoute(
      page: inquire
          ? AppointmentRequestScreen(
              clinic: clinic,
              selectedOfferId: offer.id,
              selectedOfferTitle: loc.isArabic ? offer.titleAr : offer.titleEn,
            )
          : ClinicProfileScreen(clinic: clinic),
    ),
  );
}
