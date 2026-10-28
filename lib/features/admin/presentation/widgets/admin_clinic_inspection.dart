import 'package:flutter/material.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/portal_media_frame.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../models/admin_clinic_model.dart';
import 'admin_components.dart';

/// Uses only the authorized detail projection. No public practitioner lookups
/// or foreign asset traversal. Reveal supplied records in bounded batches.
class AdminClinicInspection extends StatefulWidget {
  const AdminClinicInspection({
    super.key,
    required this.clinic,
    this.gallery = true,
    this.content = true,
  });
  final AdminClinicModel clinic;
  final bool gallery, content;
  @override
  State<AdminClinicInspection> createState() => _AdminClinicInspectionState();
}

class _AdminClinicInspectionState extends State<AdminClinicInspection> {
  final _session = SessionSnapshot();
  int _photos = 6, _staff = 6, _treatments = 6;
  @override
  void initState() {
    super.initState();
    AuthState().addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AuthState().removeListener(_changed);
    super.dispose();
  }

  String clean(String text) => ApiException.sanitizeRegulatoryCompliance(text);
  Widget more(bool show, VoidCallback action) => show
      ? TextButton(
          onPressed: action,
          child: Text(
            adminText(
              'Show more supplied records',
              'عرض المزيد من السجلات المتاحة',
            ),
          ),
        )
      : const SizedBox.shrink();
  @override
  Widget build(BuildContext context) {
    if (!_session.isCurrent ||
        !AuthState().isLoggedIn ||
        !AuthState().isSuperAdmin) {
      return const SizedBox.shrink();
    }
    final c = widget.clinic, ar = LocaleService().isArabic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.gallery) ...[
          AdminSectionTitle(
            adminText('Saved clinic gallery', 'معرض صور العيادة المحفوظ'),
          ),
          if (!c.hasGalleryProjection)
            Text(
              adminText(
                'The server did not supply a review gallery.',
                'لم يرسل الخادم معرض المراجعة.',
              ),
            )
          else if (c.galleryAssets.isEmpty)
            Text(
              adminText(
                'No gallery images supplied.',
                'لا توجد صور معرض متاحة.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, box) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: c.galleryAssets.take(_photos).length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: box.maxWidth >= 520
                      ? 3
                      : box.maxWidth >= 330
                      ? 2
                      : 1,
                  childAspectRatio: 16 / 9,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (_, i) => PortalMediaFrame(
                  imageUrl: c.galleryAssets[i].url,
                  expandable: true,
                  radius: 16,
                  label: adminText(
                    'Clinic gallery image',
                    'صورة من معرض العيادة',
                  ),
                ),
              ),
            ),
          more(
            c.galleryAssets.length > _photos,
            () => setState(() => _photos += 6),
          ),
        ],
        if (widget.content) ...[
          if (!c.hasContentProjection)
            Text(
              adminText(
                'Complete staff and treatment records were not supplied.',
                'لم يرسل الخادم سجلات الفريق والعلاجات الكاملة.',
              ),
            ),
          AdminSectionTitle(adminText('Medical staff', 'الفريق الطبي')),
          if (c.hasContentProjection && c.practitioners.isEmpty)
            Text(
              adminText(
                'No practitioners supplied.',
                'لا يوجد ممارسون متاحون.',
              ),
            ),
          for (final p in c.practitioners.take(_staff))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LuxuryCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PortalMediaFrame(
                      imageUrl: p.avatar,
                      width: 64,
                      height: 80,
                      expandable: true,
                      radius: 14,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clean(adminName(p.nameEn, p.nameAr)),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (p.nameEn.isNotEmpty && p.nameAr.isNotEmpty)
                            Text(clean(ar ? p.nameEn : p.nameAr)),
                          if (adminName(p.titleEn, p.titleAr).isNotEmpty)
                            Text(clean(adminName(p.titleEn, p.titleAr))),
                          if (adminName(
                            p.specialityEn,
                            p.specialityAr,
                          ).isNotEmpty)
                            Text(
                              clean(adminName(p.specialityEn, p.specialityAr)),
                            ),
                          Text(switch (p.type) {
                            'doctor' => adminText('Doctor', 'طبيب'),
                            'nurse' => adminText('Nurse', 'ممرض'),
                            'licensed_professional' => adminText(
                              'Licensed Professional',
                              'أخصائي مرخص',
                            ),
                            _ => adminText('Professional', 'ممارس'),
                          }),
                          AdminStatusBadge(status: p.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          more(
            c.practitioners.length > _staff,
            () => setState(() => _staff += 6),
          ),
          AdminSectionTitle(adminText('Treatments', 'العلاجات')),
          if (c.hasContentProjection && c.treatments.isEmpty)
            Text(adminText('No treatments supplied.', 'لا توجد علاجات متاحة.')),
          for (final t in c.treatments.take(_treatments))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LuxuryCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      clean(adminName(t.nameEn, t.nameAr)),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (t.nameEn.isNotEmpty && t.nameAr.isNotEmpty)
                      Text(clean(ar ? t.nameEn : t.nameAr)),
                    if (t.categoryName.isNotEmpty) Text(clean(t.categoryName)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        AdminStatusBadge(status: t.status),
                        Text(
                          t.isActive
                              ? adminText('Active', 'نشط')
                              : adminText('Inactive', 'غير نشط'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          more(
            c.treatments.length > _treatments,
            () => setState(() => _treatments += 6),
          ),
        ],
      ],
    );
  }
}
