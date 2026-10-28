import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/services/local_media_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/portal_media_frame.dart';
import '../../../appointment_lead/models/appointment_request_model.dart';
import '../../../offers/models/offer_model.dart';
import '../../../practitioners/models/practitioner_model.dart';
import '../../../treatments/models/treatment_model.dart';

String _bilingual(String primary, String secondary) => [
  primary.trim(),
  secondary.trim(),
].where((s) => s.isNotEmpty).toSet().join(' • ');
String _date(DateTime? value) => value == null
    ? '—'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
Color portalDanger(BuildContext context) => AppColors.isDark(context)
    ? const Color(0xFFFDA4AF)
    : const Color(0xFF9F1239);

class ClinicStatusPill extends StatelessWidget {
  const ClinicStatusPill({
    super.key,
    required this.label,
    this.tone = 'neutral',
    this.icon,
  });
  final String label, tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    final color = switch (tone) {
      'success' => dark ? const Color(0xFF6EE7B7) : const Color(0xFF166534),
      'warning' => dark ? const Color(0xFFFDE68A) : const Color(0xFF854D0E),
      'danger' => portalDanger(context),
      _ => dark ? const Color(0xFFBFDBFE) : const Color(0xFF1E3A8A),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        border: Border.all(color: color.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (icon != null)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 5),
                  child: Icon(icon, size: 14, color: color),
                ),
              ),
            TextSpan(text: label),
          ],
        ),
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

class ClinicCatalogActions extends StatelessWidget {
  const ClinicCatalogActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.isDark(context)
                ? AppColors.silverPrimary
                : const Color(0xFF0F172A),
            side: BorderSide(color: AppColors.border(context)),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.edit_outlined, size: 17),
          label: Text(ar ? 'تعديل' : 'Edit'),
        ),
        OutlinedButton.icon(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: portalDanger(context),
            backgroundColor: AppColors.errorRed.withValues(alpha: .06),
            side: BorderSide(
              color: portalDanger(context).withValues(alpha: .30),
            ),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 17),
          label: Text(ar ? 'حذف' : 'Delete'),
        ),
      ],
    );
  }
}

class ClinicSectionHeader extends StatelessWidget {
  const ClinicSectionHeader({
    super.key,
    required this.title,
    required this.addLabel,
    required this.onAdd,
    this.onManage,
    this.manageLabel,
  });
  final String title, addLabel;
  final String? manageLabel;
  final VoidCallback onAdd;
  final VoidCallback? onManage;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: AppColors.text(context),
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          Tooltip(
            message: addLabel,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text(context),
                side: BorderSide(color: AppColors.border(context)),
              ),
            ),
          ),
          if (onManage != null)
            TextButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: Text(
                manageLabel ??
                    (LocaleService().isArabic ? 'إدارة الكل' : 'Manage All'),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.text(context),
              ),
            ),
        ],
      ),
    ],
  );
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.children,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Widget> children;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: LuxuryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...children,
          const SizedBox(height: 12),
          ClinicCatalogActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    ),
  );
}

class ClinicPractitionerCard extends StatelessWidget {
  const ClinicPractitionerCard({
    super.key,
    required this.practitioner,
    required this.onEdit,
    required this.onDelete,
    this.clinicLogoUrl,
    this.compact = false,
  });
  final PractitionerModel practitioner;
  final VoidCallback onEdit, onDelete;
  final String? clinicLogoUrl;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final p = practitioner, ar = LocaleService().isArabic;
    final title = ar ? p.classificationAr : (p.classificationEn ?? '');
    final specialty = ar ? p.specialtyAr : p.specialtyEn;
    final bio = ar ? p.aboutAr : (p.aboutEn ?? '');
    return _CardShell(
      onEdit: onEdit,
      onDelete: onDelete,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: AppColors.goldText(context).withValues(alpha: .55),
                ),
              ),
              child: PortalMediaFrame(
                imageUrl: p.avatarUrl,
                mediaCacheKey: LocalMediaCache.entity('practitioner', p.id),
                width: 68,
                height: 85,
                radius: 16,
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar ? p.nameAr : p.nameEn,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClinicStatusPill(label: ar ? p.type.labelAr : p.type.labelEn),
                ],
              ),
            ),
          ],
        ),
        if (p.nameEn.trim().isNotEmpty && p.nameAr.trim().isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(
            _bilingual(p.nameEn, p.nameAr),
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
        if (title.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
        if (specialty.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          ClinicStatusPill(
            label: specialty,
            tone: 'warning',
            icon: Icons.verified_user_outlined,
          ),
        ],
        if (bio.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class ClinicTreatmentCard extends StatelessWidget {
  const ClinicTreatmentCard({
    super.key,
    required this.treatment,
    required this.onEdit,
    required this.onDelete,
    this.practitioners = const [],
  });
  final TreatmentModel treatment;
  final VoidCallback onEdit, onDelete;
  final List<PractitionerModel> practitioners;
  @override
  Widget build(BuildContext context) {
    final t = treatment, ar = LocaleService().isArabic;
    final description = ar ? t.descriptionAr : (t.descriptionEn ?? '');
    final assigned = practitioners
        .where((p) => t.practitionerIds.contains(p.id))
        .take(3);
    return _CardShell(
      onEdit: onEdit,
      onDelete: onDelete,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ClinicStatusPill(label: ar ? t.categoryAr : t.categoryEn),
            if (t.price != null)
              ClinicStatusPill(
                label: '${t.price!.toStringAsFixed(0)} AED',
                tone: 'warning',
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          ar ? t.nameAr : t.nameEn,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        if (t.nameEn.isNotEmpty && t.nameAr.isNotEmpty)
          Text(
            ar ? t.nameEn : t.nameAr,
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ClinicStatusPill(
              label: ar
                  ? 'الممارسون: ${t.practitionerIds.length}'
                  : 'Practitioners: ${t.practitionerIds.length}',
              icon: Icons.groups_outlined,
            ),
            for (final p in assigned)
              ClinicStatusPill(label: ar ? p.nameAr : p.nameEn),
          ],
        ),
      ],
    );
  }
}

class ClinicOfferCard extends StatelessWidget {
  const ClinicOfferCard({
    super.key,
    required this.offer,
    required this.onEdit,
    required this.onDelete,
  });
  final OfferModel offer;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) {
    final o = offer, ar = LocaleService().isArabic;
    final labels = ar
        ? {
            'active': 'نشط',
            'pending': 'قيد المراجعة',
            'suspended': 'موقوف',
            'rejected': 'مرفوض',
          }
        : {
            'active': 'Active',
            'pending': 'Pending',
            'suspended': 'Suspended',
            'rejected': 'Rejected',
          };
    final discount = o.originalPrice > 0
        ? ((1 - o.offerPrice / o.originalPrice) * 100).round().clamp(0, 100)
        : 0;
    return _CardShell(
      onEdit: onEdit,
      onDelete: onDelete,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PortalMediaFrame(
              imageUrl: o.imageUrl,
              mediaCacheKey: LocalMediaCache.entity('offer', o.id),
              width: 80,
              height: 76,
              radius: 14,
              icon: Icons.local_offer_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar ? o.titleAr : o.titleEn,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  if (o.titleAr.isNotEmpty && o.titleEn.isNotEmpty)
                    Text(
                      ar ? o.titleEn : o.titleAr,
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${o.originalPrice.toStringAsFixed(0)} AED',
              style: TextStyle(
                color: AppColors.mutedText(context),
                decoration: TextDecoration.lineThrough,
                fontSize: 12,
              ),
            ),
            ClinicStatusPill(
              label: '${o.offerPrice.toStringAsFixed(0)} AED',
              tone: 'warning',
            ),
            if (discount > 0)
              ClinicStatusPill(
                label: ar ? 'خصم $discount٪' : '$discount% OFF',
                tone: 'success',
              ),
            ClinicStatusPill(
              label: labels[o.status] ?? o.status,
              tone: o.status == 'active' ? 'success' : 'warning',
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          '${_date(o.startsAt)} – ${_date(o.endsAt)}',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: AppColors.mutedText(context),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ClinicLeadContactActions extends StatelessWidget {
  const ClinicLeadContactActions({
    super.key,
    required this.phone,
    this.callLabel,
    this.whatsappLabel,
  });
  final String phone;
  final String? callLabel, whatsappLabel;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: phone.trim().isEmpty
              ? null
              : () => ContactLauncher.makePhoneCall(phone),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text(context),
          ),
          icon: const Icon(Icons.phone_outlined, size: 18),
          label: Text(callLabel ?? (ar ? 'اتصال' : 'Call')),
        ),
        OutlinedButton.icon(
          onPressed: phone.trim().isEmpty
              ? null
              : () => ContactLauncher.openWhatsApp(phoneNumber: phone),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.isDark(context)
                ? const Color(0xFF6EE7B7)
                : const Color(0xFF166534),
            side: const BorderSide(color: Color(0xFF2D6A4F)),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text(whatsappLabel ?? 'WhatsApp'),
        ),
      ],
    );
  }
}

class ClinicLeadSummaryCard extends StatelessWidget {
  const ClinicLeadSummaryCard({
    super.key,
    required this.lead,
    required this.onTap,
  });
  final AppointmentRequestModel lead;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ar = LocaleService().isArabic;
    final (label, tone) = switch (lead.status) {
      AppointmentLeadStatus.sent => (ar ? 'جديد' : 'New', 'warning'),
      AppointmentLeadStatus.contacted => (
        ar ? 'تم التواصل' : 'Contacted',
        'neutral',
      ),
      AppointmentLeadStatus.closed => (ar ? 'مغلق' : 'Closed', 'success'),
    };
    return LuxuryCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lead.patientFullName,
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClinicStatusPill(label: label, tone: tone),
          const SizedBox(height: 7),
          Text(
            lead.patientPhone,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            lead.referenceCode,
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 11.5,
            ),
          ),
          const Divider(height: 20),
          Text(
            ar
                ? lead.serviceNameAr
                : (lead.serviceNameEn ?? lead.serviceNameAr),
            style: TextStyle(
              color: AppColors.text(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            [
              _date(lead.createdAt),
              ar ? lead.branchNameAr : (lead.branchNameEn ?? lead.branchNameAr),
            ].where((v) => v.trim().isNotEmpty).join(' • '),
            style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClinicLeadContactActions(phone: lead.patientPhone),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: Text(ar ? 'عرض التفاصيل' : 'View Details'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }
}
