import '../widgets/admin_clinic_inspection.dart';
import '../../../../core/widgets/portal_media_frame.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/remote_catalog_preview.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/tier_badge.dart';
import '../../../offers/models/offer_model.dart';
import '../../models/admin_clinic_model.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';
import '../widgets/admin_clinic_editor.dart';
import '../widgets/admin_password_reset_dialog.dart';

class AdminClinicDetailSheet extends StatefulWidget {
  const AdminClinicDetailSheet({super.key, required this.clinic});
  final AdminClinicModel clinic;
  @override
  State<AdminClinicDetailSheet> createState() => _AdminClinicDetailSheetState();
}

class _AdminClinicDetailSheetState extends State<AdminClinicDetailSheet> {
  final _service = AdminPortalService();
  String? _error;
  final _scroll = ScrollController();
  final _offersAnchor = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _showOffers() {
    final target = _offersAnchor.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
        alignment: 0,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _service.loadClinicDetail(widget.clinic.id, initial: widget.clinic);
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_service, LocaleService()]),
    builder: (context, _) {
      final c =
          _service.clinicDetail(widget.clinic.id) ??
          _service.clinics.where((c) => c.id == widget.clinic.id).firstOrNull ??
          widget.clinic;
      final busy = _service.isPending('clinic', c.id);
      return Material(
        color: AppColors.surface(context),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .9,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          adminText('Clinic details', 'تفاصيل العيادة'),
                          style: TextStyle(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: adminText('Close', 'إغلاق'),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextButton.icon(
                      key: const ValueKey('admin-clinic-view-offers'),
                      onPressed: _showOffers,
                      icon: const Icon(Icons.local_offer_outlined),
                      label: Text(
                        adminText('View clinic offers', 'عرض عروض العيادة'),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Scrollbar(
                    controller: _scroll,
                    child: SingleChildScrollView(
                      key: const ValueKey('admin-clinic-detail-scroll'),
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          if (_service.clinicDetailLoading(c.id))
                            const LinearProgressIndicator(),
                          if (_service.clinicDetailError(c.id) != null)
                            AdminNotice(
                              message: _service.clinicDetailError(c.id)!,
                              error: true,
                              onRetry: () => _service.loadClinicDetail(
                                c.id,
                                refresh: true,
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdminEntityImage(
                                url: c.logo,
                                logo: c.coverImage,
                                isLogo: true,
                                size: 72,
                                mediaKey: clinicLogoCacheKey(c.id),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.localizedName(
                                        arabic: LocaleService().isArabic,
                                      ),
                                      style: TextStyle(
                                        color: AppColors.text(context),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      c.locationLabel(
                                        arabic: LocaleService().isArabic,
                                      ),
                                      style: TextStyle(
                                        color: AppColors.mutedText(context),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (c.coverImage.isNotEmpty) ...[
                            PortalMediaFrame(
                              imageUrl: c.coverImage,
                              expandable: true,
                              label: adminText('Clinic cover', 'غلاف العيادة'),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TierBadge(
                                tier: c.subscriptionTier,
                                showBasic: true,
                              ),
                              AdminStatusBadge(status: c.status),
                              if (c.isFeatured)
                                Text(
                                  adminText(
                                    'Home placement enabled',
                                    'الظهور في الرئيسية مفعّل',
                                  ),
                                  style: TextStyle(
                                    color: AppColors.goldText(context),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          AdminSectionTitle(
                            adminText('Clinic management', 'إدارة العيادة'),
                          ),
                          if (_error != null)
                            AdminNotice(message: _error!, error: true),
                          LuxuryCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LocaleService().tr(
                                          'admin_toggle_clinic_status',
                                        ),
                                        style: TextStyle(
                                          color: AppColors.text(context),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      AdminStatusBadge(status: c.status),
                                    ],
                                  ),
                                ),
                                if (busy)
                                  const SizedBox.square(
                                    dimension: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Switch.adaptive(
                                    value: c.isActive,
                                    onChanged: !_service.canManage
                                        ? null
                                        : (_) async {
                                            if (c.isActive &&
                                                !await confirmClinicSuspension(
                                                  context,
                                                )) {
                                              return;
                                            }
                                            if (!mounted) return;
                                            setState(() => _error = null);
                                            final ok = await _service
                                                .toggleClinicStatus(c.id);
                                            if (mounted && !ok) {
                                              setState(
                                                () => _error =
                                                    _service.writeError(
                                                      'clinic',
                                                      c.id,
                                                    ) ??
                                                    adminText(
                                                      'Could not update clinic.',
                                                      'تعذر تحديث العيادة.',
                                                    ),
                                              );
                                            }
                                          },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const ValueKey('admin-edit-clinic'),
                            onPressed:
                                !_service.canManage ||
                                    busy ||
                                    _service.clinicDetailLoading(c.id)
                                ? null
                                : () => showModalBottomSheet<bool>(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    isDismissible: false,
                                    enableDrag: false,
                                    backgroundColor: AppColors.surface(context),
                                    builder: (ctx) => SizedBox(
                                      height:
                                          MediaQuery.sizeOf(ctx).height * .94,
                                      child: AdminClinicEditor(clinic: c),
                                    ),
                                  ),
                            icon: const Icon(Icons.edit_note_rounded),
                            label: Text(
                              adminText(
                                'Edit Clinic Details & Branding',
                                'تعديل بيانات وهوية العيادة',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text(context),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: !_service.canManage
                                ? null
                                : () => showDialog<void>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => AdminPasswordResetDialog(
                                      clinicId: c.id,
                                    ),
                                  ),
                            icon: const Icon(Icons.lock_reset_rounded),
                            label: Text(
                              adminText(
                                'Reset Admin Password',
                                'إعادة تعيين كلمة مرور المشرف',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text(context),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          AdminSectionTitle(
                            adminText(
                              'Clinic overview',
                              'نظرة عامة على العيادة',
                            ),
                          ),
                          AdminMetricGrid(
                            children: [
                              AdminMetricCard(
                                label: LocaleService().tr('admin_table_leads'),
                                value: adminNumber(c.leadsCount),
                                icon: Icons.mark_email_read_outlined,
                              ),
                              AdminMetricCard(
                                label: LocaleService().tr(
                                  'admin_clinic_branches',
                                ),
                                value: adminNumber(c.branchesCount),
                                icon: Icons.store_outlined,
                              ),
                              AdminMetricCard(
                                label: LocaleService().tr(
                                  'admin_clinic_practitioners',
                                ),
                                value: adminNumber(c.practitionersCount),
                                icon: Icons.badge_outlined,
                              ),
                              AdminMetricCard(
                                label: LocaleService().tr(
                                  'admin_clinic_offers',
                                ),
                                value: adminNumber(c.offersCount),
                                icon: Icons.local_offer_outlined,
                              ),
                            ],
                          ),
                          AdminSectionTitle(adminText('Location', 'الموقع')),
                          if (adminName(c.addressEn, c.addressAr).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                adminName(c.addressEn, c.addressAr),
                                style: TextStyle(
                                  color: AppColors.mutedText(context),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: !c.hasVerifiedLocation
                                ? null
                                : () async {
                                    final opened =
                                        await MapsLauncher.openVerifiedLocation(
                                          latitude: c.latitude,
                                          longitude: c.longitude,
                                          googleMapsUrl: c.googleMapsUrl,
                                        );
                                    if (mounted && !opened) {
                                      setState(
                                        () => _error = adminText(
                                          'Could not open Google Maps.',
                                          'تعذر فتح خرائط Google.',
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.map_outlined),
                            label: Text(
                              c.hasVerifiedLocation
                                  ? LocaleService().tr('open_in_maps')
                                  : adminText(
                                      'Verified map location unavailable',
                                      'موقع موثوق على الخريطة غير متوفر',
                                    ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          AdminClinicInspection(
                            key: ValueKey('inspection-${c.id}'),
                            clinic: c,
                          ),
                          AdminSectionTitle(
                            LocaleService().tr('clinic_nav_offers'),
                            key: _offersAnchor,
                          ),
                          RemoteCatalogPreview<OfferModel>(
                            key: ValueKey(c.id),
                            keyOf: (o) => o.id,
                            emptyState: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                adminText(
                                  'No offers for this clinic.',
                                  'لا توجد عروض لهذه العيادة.',
                                ),
                                style: TextStyle(
                                  color: AppColors.mutedText(context),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            loader: (page) =>
                                _service.getClinicOffersPage(c.id, page),
                            itemBuilder: (context, o) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LuxuryCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      adminName(o.titleEn, o.titleAr),
                                      style: TextStyle(
                                        color: AppColors.text(context),
                                        fontWeight: FontWeight.w600,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AdminStatusBadge(status: o.status),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
