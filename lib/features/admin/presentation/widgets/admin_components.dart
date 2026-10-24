import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import '../../../../core/data/paged_collection.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/services/local_media_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/widgets/portal_media_frame.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../models/admin_lead_model.dart';

String adminText(String en, String ar) => LocaleService().isArabic ? ar : en;
String adminName(String? en, String? ar) {
  final values = LocaleService().isArabic ? [ar, en] : [en, ar];
  return values
          .whereType<String>()
          .where((v) => v.trim().isNotEmpty)
          .firstOrNull ??
      '';
}

String adminNumber(num value) => NumberFormat.decimalPattern().format(value);
String adminDate(DateTime? value) => value == null
    ? '—'
    : DateFormat('dd/MM/yyyy · HH:mm').format(value.toLocal());

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status.toLowerCase()) {
      'inactive' => (
        adminText('Inactive', 'غير نشط'),
        AppColors.mutedText(context),
      ),
      'active' => (adminText('Active', 'نشط'), AppColors.positiveText(context)),
      'suspended' => (
        adminText('Suspended', 'موقوف'),
        AppColors.dangerText(context),
      ),
      'rejected' => (
        adminText('Rejected', 'مرفوض'),
        AppColors.dangerText(context),
      ),
      'pending' => (
        adminText('Pending review', 'قيد المراجعة'),
        AppColors.warningText(context),
      ),
      'new' || 'sent' => (
        LocaleService().tr('clinic_lead_status_new'),
        AppColors.warningText(context),
      ),
      'contacted' => (
        LocaleService().tr('clinic_lead_status_contacted'),
        AppColors.infoText(context),
      ),
      'closed' => (
        LocaleService().tr('clinic_lead_status_closed'),
        AppColors.positiveText(context),
      ),
      _ => (
        adminText('Status unavailable', 'الحالة غير متوفرة'),
        AppColors.mutedText(context),
      ),
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class AdminNotice extends StatelessWidget {
  const AdminNotice({
    super.key,
    required this.message,
    this.error = false,
    this.onRetry,
  });
  final String message;
  final bool error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final color = error
        ? AppColors.dangerText(context)
        : AppColors.infoText(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                error ? Icons.error_outline : Icons.shield_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: color, height: 1.5, fontSize: 12.5),
                ),
              ),
            ],
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(LocaleService().tr('retry')),
            ),
        ],
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ?action,
      ],
    ),
  );
}

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
  });
  final String label, value;
  final String? caption;
  final IconData icon;
  @override
  Widget build(BuildContext context) => LuxuryCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.goldText(context)),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 25,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              caption!,
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
      ],
    ),
  );
}

/// A wrapped, variable-height grid: business labels are never truncated.
class AdminMetricGrid extends StatelessWidget {
  const AdminMetricGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final enlarged = MediaQuery.textScalerOf(context).scale(14) > 18;
      final columns = box.maxWidth < 330 || enlarged
          ? 1
          : box.maxWidth >= 700
          ? 3
          : 2;
      final width = (box.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children
            .map((w) => SizedBox(width: width, child: w))
            .toList(),
      );
    },
  );
}

class AdminEntityImage extends StatelessWidget {
  const AdminEntityImage({
    super.key,
    required this.url,
    this.logo,
    this.size = 64,
    this.isLogo = false,
    this.mediaKey,
  });
  final String? url, logo, mediaKey;
  final double size;
  final bool isLogo;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceHover(context),
      borderRadius: BorderRadius.circular(15),
    ),
    child: PortalMediaFrame(
      imageUrl: url,
      mediaCacheKey: mediaKey,
      width: size,
      height: size,
      fit: isLogo ? BoxFit.contain : BoxFit.cover,
      radius: 15,
      expandable: size >= 100,
    ),
  );
}

class AdminDirectory<T> extends StatelessWidget {
  const AdminDirectory({
    super.key,
    required this.items,
    required this.page,
    required this.headers,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    this.bottomPadding = 32,
  });
  final List<T> items;
  final PagedCollection<dynamic> page;
  final List<Widget> headers;
  final Widget Function(BuildContext, T) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final double bottomPadding;
  @override
  Widget build(BuildContext context) {
    final showItems = page.isLoaded || (!page.isLoading && page.error == null);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: PagedScrollBoundary(
        onLoadMore: onLoadMore,
        child: CustomScrollView(
          key: PageStorageKey('admin-directory-${T.toString()}'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverList.list(
                children: [
                  ...headers,
                  if (page.isLoading) const LinearProgressIndicator(),
                  if (page.error != null)
                    AdminNotice(
                      message: page.error!,
                      error: true,
                      onRetry: () => onRefresh(),
                    ),
                  if (items.isEmpty && !page.isLoading && page.error == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        adminText(
                          'No matching records.',
                          'لا توجد نتائج مطابقة.',
                        ),
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                ],
              ),
            ),
            if (showItems)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (c, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: itemBuilder(c, items[i]),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: PaginationFooter(
                loading: page.isLoading || page.isLoadingMore,
                hasMore: page.hasMore,
                error: page.error,
                onLoadMore: onLoadMore,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: bottomPadding + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminLeadCard extends StatelessWidget {
  const AdminLeadCard({super.key, required this.lead, required this.onTap});
  final AdminLeadModel lead;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => LuxuryCard(
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lead.localizedClinic(arabic: LocaleService().isArabic),
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        AdminStatusBadge(status: lead.status),
        const Divider(height: 24),
        Text(
          lead.patientName,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (lead.localizedService(arabic: LocaleService().isArabic).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              lead.localizedService(arabic: LocaleService().isArabic),
              style: TextStyle(
                color: AppColors.mutedText(context),
                height: 1.5,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(
              lead.referenceCode,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: AppColors.goldText(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              adminDate(lead.createdAt),
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                adminText('Inspect request', 'عرض الطلب'),
                style: TextStyle(color: AppColors.text(context), fontSize: 12),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.mutedText(context),
            ),
          ],
        ),
      ],
    ),
  );
}

String clinicLogoCacheKey(String id) => LocalMediaCache.clinicLogo(id);

Future<bool> confirmClinicSuspension(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(adminText('Suspend clinic?', 'إيقاف العيادة؟')),
        content: Text(
          adminText(
            'This hides the clinic from discovery and restricts its portal access.',
            'سيتم إخفاء العيادة من نتائج البحث وتقييد الوصول إلى بوابتها.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(adminText('Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(adminText('Suspend', 'إيقاف')),
          ),
        ],
      ),
    ) ??
    false;
