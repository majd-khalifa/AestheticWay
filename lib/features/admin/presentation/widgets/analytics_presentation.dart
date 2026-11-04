import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../models/analytics_v2.dart';
import 'admin_components.dart';

String analyticsValue(int? value) => value == null ? '—' : adminNumber(value);
String analyticsLabel(String key) => switch (key) {
  'clinic_views' => adminText('Clinic views', 'مشاهدات العيادة'),
  'whatsapp_taps' => adminText('WhatsApp taps', 'نقرات واتساب'),
  'call_taps' => adminText('Call taps', 'نقرات الاتصال'),
  'maps_taps' => adminText('Maps taps', 'نقرات الخرائط'),
  _ => adminText('Saved consultations', 'الاستشارات المحفوظة'),
};

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: children,
      ),
    ),
  );
}

class AnalyticsPeriod extends StatelessWidget {
  const AnalyticsPeriod({
    super.key,
    required this.title,
    required this.period,
    this.onChoose,
    this.busy = false,
  });
  final String title, period;
  final VoidCallback? onChoose;
  final bool busy;
  @override
  Widget build(BuildContext context) => LuxuryCard(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                period,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              Text(
                adminText('Dubai time · UTC+4', 'توقيت دبي · UTC+4'),
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        if (onChoose != null || busy)
          IconButton(
            tooltip: adminText('Change reporting period', 'تغيير فترة التقرير'),
            onPressed: busy ? null : onChoose,
            icon: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.date_range_outlined),
          ),
      ],
    ),
  );
}

class AnalyticsCoverageBadge extends StatelessWidget {
  const AnalyticsCoverageBadge({super.key, required this.coverage});
  final AnalyticsCoverage coverage;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (coverage) {
      AnalyticsCoverage.complete => (
        adminText('Complete', 'مكتملة'),
        AppColors.positiveText(context),
      ),
      AnalyticsCoverage.partial => (
        adminText('Partial', 'جزئية'),
        AppColors.warningText(context),
      ),
      AnalyticsCoverage.unavailable => (
        adminText('Unavailable', 'غير متاحة'),
        AppColors.mutedText(context),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        semanticsLabel: '${adminText('Coverage', 'التغطية')}: $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AnalyticsMetricTile extends StatelessWidget {
  const AnalyticsMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.metric,
    this.caption,
    this.valueKey,
    this.trustedLabel,
  });
  final String label, value;
  final AnalyticsMetric? metric;
  final String? caption;
  final Key? valueKey;
  final String? trustedLabel;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final title = Text(
        label,
        style: TextStyle(
          color: AppColors.mutedText(context),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
      final number = Text(
        value,
        key: valueKey,
        style: TextStyle(
          color: AppColors.text(context),
          fontSize: 27,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      );
      return LuxuryCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bounds.maxWidth >= 230)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  number,
                ],
              )
            else ...[
              title,
              const SizedBox(height: 8),
              number,
            ],
            if (metric != null) ...[
              const SizedBox(height: 8),
              AnalyticsCoverageBadge(coverage: metric!.coverage),
              const SizedBox(height: 8),
              AnalyticsObservations(
                metric: metric!,
                trustedLabel: trustedLabel,
              ),
            ],
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  caption!,
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class AnalyticsObservations extends StatelessWidget {
  const AnalyticsObservations({
    super.key,
    required this.metric,
    this.trustedLabel,
  });
  final AnalyticsMetric metric;
  final String? trustedLabel;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 4,
    children: [
      Text(
        '${adminText('Observed', 'مرصود')} ${adminNumber(metric.recorded)}',
        style: TextStyle(
          color: AppColors.mutedText(context),
          fontSize: 11.5,
          height: 1.4,
        ),
      ),
      Text(
        '${trustedLabel ?? adminText('Trusted', 'موثوق')} ${adminNumber(metric.trusted)}',
        style: TextStyle(
          color: AppColors.mutedText(context),
          fontSize: 11.5,
          height: 1.4,
        ),
      ),
    ],
  );
}

/// Analytics-only variable-height tiles; other portals keep their existing grid.
class AnalyticsKpiGrid extends StatelessWidget {
  const AnalyticsKpiGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final minimum = MediaQuery.textScalerOf(context).scale(138);
      final columns = ((bounds.maxWidth + 12) / (minimum + 12)).floor().clamp(
        1,
        5,
      );
      final width = (bounds.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class AnalyticsDisclosure extends StatelessWidget {
  const AnalyticsDisclosure({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  @override
  Widget build(BuildContext context) => LuxuryCard(
    padding: EdgeInsets.zero,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
        children: children,
      ),
    ),
  );
}

class AnalyticsDailyMetrics extends StatelessWidget {
  const AnalyticsDailyMetrics({super.key, required this.metrics});
  final AnalyticsV2Metrics metrics;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final key in analyticsMetricKeys)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      analyticsLabel(key),
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    analyticsValue(metrics.values[key]!.count),
                    key: ValueKey('daily-$key-canonical'),
                    semanticsLabel:
                        '${adminText('Canonical', 'العدد المعتمد')}: ${analyticsValue(metrics.values[key]!.count)}',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AnalyticsCoverageBadge(
                    coverage: metrics.values[key]!.coverage,
                  ),
                  AnalyticsObservations(
                    metric: metrics.values[key]!,
                    trustedLabel: key == 'lead_submissions'
                        ? adminText('Saved', 'محفوظ')
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: AppColors.border(context)),
            ],
          ),
        ),
    ],
  );
}

class AnalyticsHelp extends StatelessWidget {
  const AnalyticsHelp({super.key});
  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.info_outline, size: 18),
    label: Text(adminText('How to read these counts', 'كيف تقرأ هذه الأعداد')),
    onPressed: () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminSectionTitle(
              adminText('Understanding the report', 'فهم التقرير'),
            ),
            for (final text in [
              adminText(
                '— is unavailable. Canonical zero requires complete coverage.',
                '— تعني غير متاح. الصفر المعتمد يتطلب تغطية مكتملة.',
              ),
              adminText(
                'Observed includes stored legacy events. Trusted counts use validated V2 events; saved consultations come from saved Lead records. Trusted counts alone do not prove complete coverage.',
                'تشمل الأعداد المرصودة أحداثاً قديمة محفوظة. تستخدم الأعداد الموثوقة أحداث V2 المتحققة، والاستشارات من سجلات الطلبات المحفوظة. الأعداد الموثوقة وحدها لا تثبت اكتمال التغطية.',
              ),
              adminText(
                'Calls, WhatsApp and Maps measure tap intentions, not completed conversations or visits.',
                'تقيس نقرات الاتصال وواتساب والخرائط نوايا الانتقال، لا المحادثات أو الزيارات المكتملة.',
              ),
              adminText(
                'Unique accounts are unavailable. This endpoint provides no platform clinic total; directory pages are never summed into one.',
                'الحسابات الفريدة غير متاحة. لا توفر هذه الواجهة إجمالي نشاط عيادات المنصة، ولا تُجمع صفحات الدليل لإنتاجه.',
              ),
              adminText(
                'Periods use Dubai time (UTC+4). Only server-returned dates and retained history are shown. Legacy records do not attest collection coverage.',
                'الفترات بتوقيت دبي (UTC+4). تظهر التواريخ والسجلات التي أعادها الخادم فقط. السجلات القديمة لا تثبت اكتمال تغطية الجمع.',
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(text, style: const TextStyle(height: 1.6)),
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Navigator.pop(sheet),
                child: Text(adminText('Close', 'إغلاق')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
