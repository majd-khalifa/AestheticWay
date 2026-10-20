import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../models/admin_lead_model.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';

/// Super Admin supervision deliberately exposes no patient workflow actions.
class AdminLeadDetailScreen extends StatefulWidget {
  const AdminLeadDetailScreen({super.key, required this.lead});
  final AdminLeadModel lead;
  @override
  State<AdminLeadDetailScreen> createState() => _AdminLeadDetailScreenState();
}

class _AdminLeadDetailScreenState extends State<AdminLeadDetailScreen> {
  late AdminLeadModel _lead;
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted || AdminPortalService().isMockMode) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final latest = await AdminPortalService().getLeadDetail(_lead.id);
      if (mounted) setState(() => _lead = latest);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = adminText(
            'Could not refresh this request.',
            'تعذر تحديث بيانات الطلب.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _lead, ar = LocaleService().isArabic;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(LocaleService().tr('admin_lead_inspect_title')),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            32 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            AdminNotice(
              message: LocaleService().tr('admin_lead_monitoring_banner'),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              AdminNotice(message: _error!, error: true, onRetry: _refresh),
            const SizedBox(height: 12),
            LuxuryCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.referenceCode,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: AppColors.goldText(context),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminStatusBadge(status: l.status),
                  const SizedBox(height: 12),
                  _ReadOnlyField(
                    label: LocaleService().tr('submitted_at'),
                    value: adminDate(l.createdAt),
                    ltr: true,
                  ),
                ],
              ),
            ),
            AdminSectionTitle(
              adminText('Recipient Clinic', 'العيادة المستلمة للطلب'),
            ),
            LuxuryCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReadOnlyField(
                    label: adminText('Clinic', 'العيادة'),
                    value: l.localizedClinic(arabic: ar),
                  ),
                  if ((ar ? l.branchNameAr : l.branchNameEn).isNotEmpty)
                    _ReadOnlyField(
                      label: adminText('Branch', 'الفرع'),
                      value: ar ? l.branchNameAr : l.branchNameEn,
                    ),
                ],
              ),
            ),
            AdminSectionTitle(
              adminText('Patient & inquiry', 'المريض والاستفسار'),
            ),
            LuxuryCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReadOnlyField(
                    label: LocaleService().tr('full_name'),
                    value: l.patientName,
                  ),
                  _ReadOnlyField(
                    label: adminText('Phone', 'رقم الهاتف'),
                    value: l.patientPhone,
                    ltr: true,
                  ),
                  if (l.patientEmail.isNotEmpty)
                    _ReadOnlyField(
                      label: adminText('Email', 'البريد الإلكتروني'),
                      value: l.patientEmail,
                      ltr: true,
                    ),
                  _ReadOnlyField(
                    label: adminText('Requested Service', 'الخدمة المطلوبة'),
                    value: l.localizedService(arabic: ar),
                  ),
                  if (l.notes.trim().isNotEmpty)
                    _ReadOnlyField(
                      label: LocaleService().tr('notes_opt'),
                      value: l.notes,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.ltr = false,
  });
  final String label, value;
  final bool ltr;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.mutedText(context),
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '—' : value,
          textDirection: ltr ? TextDirection.ltr : null,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}
