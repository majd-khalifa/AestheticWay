import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';
import 'admin_categories_screen.dart';

/// Each module owns its server page. Unsupported legacy search stays explicitly local.
class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});
  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  final _service = AdminPortalService();
  final _search = TextEditingController();
  Timer? _localDebounce;
  int _module = 0;
  String _localQuery = '';
  final _queries = ['', '', ''];
  final List<String?> _statuses = [null, null, null];
  String get _key => const ['offers', 'products', 'articles'][_module];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.loadCollection(_key);
    });
  }

  @override
  void dispose() {
    _localDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _query => {
    'status': _statuses[_module],
    if (_module == 1) 'search': _search.text.trim(),
  };
  void _changeModule(int value) {
    if (value == _module) return;
    _localDebounce?.cancel();
    setState(() {
      _module = value;
      _search.text = _queries[value];
      _localQuery = _search.text.toLowerCase().trim();
    });
    _service.loadCollection(_key, query: _query);
  }

  void _searchChanged(String value) {
    _queries[_module] = value;
    if (_module == 1) {
      _service.searchCollection(_key, _query);
      return;
    }
    _localDebounce?.cancel();
    _localDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _localQuery = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_service, LocaleService()]),
    builder: (context, _) {
      final records = _records();
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: AdminDirectory<_Content>(
          items: records,
          page: _service.collection(_key),
          onRefresh: () =>
              _service.loadCollection(_key, refresh: true, query: _query),
          onLoadMore: () => _service.loadMore(_key),
          headers: [
            AdminSectionTitle(
              adminText('Content moderation', 'مراجعة المحتوى'),
              subtitle: adminText(
                'Inspect submissions and confirm platform visibility.',
                'مراجعة المحتوى والتحكم في ظهوره على المنصة.',
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final (i, label, icon) in [
                  (
                    0,
                    LocaleService().tr('cat_offers'),
                    Icons.local_offer_outlined,
                  ),
                  (
                    1,
                    LocaleService().tr('cat_products'),
                    Icons.auto_awesome_outlined,
                  ),
                  (
                    2,
                    LocaleService().tr('cat_articles'),
                    Icons.article_outlined,
                  ),
                ])
                  ChoiceChip(
                    label: Text(label),
                    avatar: Icon(icon, size: 18),
                    selected: _module == i,
                    onSelected: (_) => _changeModule(i),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const ValueKey('admin-treatment-categories'),
                onPressed: !_service.canManage
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminCategoriesScreen(),
                        ),
                      ),
                icon: const Icon(Icons.category_outlined),
                label: Text(
                  adminText('Treatment Categories', 'تصنيفات العلاجات'),
                ),
              ),
            ),
            if (_module == 1) ...[
              const _BrandProductAvailability(),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  key: const ValueKey('admin-add-brand-product'),
                  onPressed: null,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    adminText('Add Brand Product', 'إضافة منتج علامة تجميلية'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: _module == 1
                    ? adminText(
                        'Search products, brands or sponsors',
                        'البحث بالمنتج أو العلامة أو الراعي',
                      )
                    : adminText(
                        'Search loaded content',
                        'البحث في المحتوى المحمّل',
                      ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _searchChanged,
            ),
            if (_module != 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  adminText(
                    'Search covers loaded records. Load more to include additional content.',
                    'يشمل البحث السجلات المحمّلة. حمّل المزيد لتوسيع النتائج.',
                  ),
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final state in <String?>[
                  null,
                  'active',
                  'pending',
                  'suspended',
                  'rejected',
                ])
                  ChoiceChip(
                    label: Text(_filterLabel(state)),
                    selected: _statuses[_module] == state,
                    onSelected: (_) {
                      setState(() => _statuses[_module] = state);
                      _service.searchCollection(_key, _query);
                    },
                  ),
              ],
            ),
            if (records.any((r) => r.status == 'unknown'))
              AdminNotice(
                message: adminText(
                  'Some moderation states are unavailable. Select a status filter or choose an explicit moderation action.',
                  'لم تتوفر حالة المراجعة لبعض السجلات. استخدم تصفية الحالة أو اختر إجراء مراجعة واضحاً.',
                ),
              ),
            const SizedBox(height: 8),
          ],
          itemBuilder: (context, item) => _ModerationCard(item: item),
        ),
      );
    },
  );
  String _filterLabel(String? state) => switch (state) {
    'active' => adminText('Active', 'نشط'),
    'pending' => adminText('Pending', 'قيد المراجعة'),
    'suspended' => adminText('Suspended', 'موقوف'),
    'rejected' => adminText('Rejected', 'مرفوض'),
    _ => LocaleService().tr('status_all'),
  };
  List<_Content> _records() {
    final result = <_Content>[];
    if (_module == 0) {
      for (final o in _service.allOffers) {
        result.add(
          _Content(
            kind: 'offer',
            id: o.id,
            title: adminName(o.titleEn, o.titleAr),
            subtitle: adminName(o.clinicNameEn, o.clinicNameAr),
            description: adminName(o.termsEn, o.termsAr),
            image: o.imageUrl,
            logo: o.clinicLogoUrl,
            status: o.status,
            price: o.offerPrice,
            originalPrice: o.originalPrice,
            discount: o.discountPercentage,
          ),
        );
      }
    } else if (_module == 1) {
      for (final p in _service.allProducts) {
        final brand = adminName(p.brandNameEn, p.brandNameAr),
            sponsor = p.sponsorCompany?.trim() ?? '';
        result.add(
          _Content(
            kind: 'product',
            id: p.id,
            title: adminName(p.nameEn, p.nameAr),
            subtitle: brand.isEmpty
                ? adminText(
                    'Brand details not provided',
                    'بيانات العلامة غير متوفرة',
                  )
                : brand,
            attribution: [
              if (sponsor.isNotEmpty)
                '${adminText('Sponsor', 'الراعي')}: $sponsor',
              if (adminName(p.clinicNameEn, p.clinicNameAr).isNotEmpty)
                '${adminText('Clinic', 'العيادة')}: ${adminName(p.clinicNameEn, p.clinicNameAr)}',
            ].join('\n'),
            description: adminName(p.descriptionEn, p.descriptionAr),
            image: p.imageUrl,
            logo: p.clinicLogoUrl,
            status: p.status,
          ),
        );
      }
    } else {
      for (final a in _service.allArticles) {
        final author = adminName(a.authorDoctorNameEn, a.authorDoctorNameAr),
            clinic = adminName(a.clinicNameEn, a.clinicNameAr);
        result.add(
          _Content(
            kind: 'article',
            id: a.id,
            title: adminName(a.titleEn, a.titleAr),
            subtitle: author.isEmpty
                ? adminText('Author not provided', 'الكاتب غير متوفر')
                : '${LocaleService().tr('article_author_by')}: $author',
            attribution: clinic,
            description: adminName(a.contentEn, a.contentAr),
            image: a.coverImageUrl,
            logo: a.clinicLogoUrl,
            status: a.status,
          ),
        );
      }
    }
    final query = _module == 1
        ? (_service.isMockMode ? _search.text.toLowerCase().trim() : '')
        : _localQuery;
    return result
        .where(
          (r) =>
              (query.isEmpty ||
                  '${r.title} ${r.subtitle} ${r.description} ${r.attribution}'
                      .toLowerCase()
                      .contains(query)) &&
              (!_service.isMockMode ||
                  _statuses[_module] == null ||
                  r.status == _statuses[_module]),
        )
        .toList();
  }
}

class _Content {
  const _Content({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.image,
    required this.status,
    this.attribution = '',
    this.logo,
    this.price,
    this.originalPrice,
    this.discount,
  });
  final String kind,
      id,
      title,
      subtitle,
      description,
      image,
      status,
      attribution;
  final String? logo;
  final double? price, originalPrice;
  final int? discount;
}

class _ModerationCard extends StatelessWidget {
  const _ModerationCard({required this.item});
  final _Content item;
  Future<void> _moderate(BuildContext context, String target) async {
    final service = AdminPortalService();
    final ok = await service.setContentStatus(item.kind, item.id, target);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      ok
          ? adminText('Moderation saved.', 'تم حفظ حالة المراجعة.')
          : service.writeError(item.kind, item.id) ??
                adminText(
                  'Could not save moderation.',
                  'تعذر حفظ حالة المراجعة.',
                ),
      type: ok ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminPortalService(),
        busy = service.isPending(item.kind, item.id);
    return LuxuryCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminEntityImage(
                url: item.image,
                logo: item.logo,
                size: 72,
                isLogo: item.kind == 'product',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: AppColors.goldText(context),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.attribution.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                item.attribution,
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          if (item.kind == 'offer' && item.price != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    '${adminNumber(item.price!)} AED',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.originalPrice != null &&
                      item.originalPrice! > item.price!)
                    Text(
                      '${adminNumber(item.originalPrice!)} AED',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if ((item.discount ?? 0) > 0)
                    Text(
                      adminText(
                        '${item.discount}% off',
                        'خصم ${item.discount}٪',
                      ),
                      style: TextStyle(
                        color: AppColors.positiveText(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          AdminStatusBadge(status: item.status),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  builder: (_) => _ContentInspection(item: item),
                ),
                icon: const Icon(Icons.visibility_outlined),
                label: Text(adminText('Inspect content', 'فحص المحتوى')),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (item.status == 'unknown') ...[
                OutlinedButton(
                  onPressed: !service.canManage
                      ? null
                      : () => _moderate(context, 'active'),
                  child: Text(adminText('Approve', 'اعتماد')),
                ),
                OutlinedButton(
                  onPressed: !service.canManage
                      ? null
                      : () => _moderate(context, 'suspended'),
                  child: Text(adminText('Suspend', 'إيقاف')),
                ),
              ] else
                Semantics(
                  label: adminText('Content visibility', 'ظهور المحتوى'),
                  child: Switch.adaptive(
                    value: item.status == 'active',
                    onChanged: !service.canManage
                        ? null
                        : (_) => _moderate(
                            context,
                            item.status == 'active' ? 'suspended' : 'active',
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentInspection extends StatelessWidget {
  const _ContentInspection({required this.item});
  final _Content item;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .88,
    child: ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                adminText('Content inspection', 'فحص المحتوى'),
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: adminText('Close', 'إغلاق'),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdminEntityImage(
          url: item.image,
          logo: item.logo,
          size: 160,
          isLogo: item.kind == 'product',
        ),
        AdminSectionTitle(item.title, subtitle: item.subtitle),
        if (item.attribution.isNotEmpty)
          Text(
            item.attribution,
            style: TextStyle(color: AppColors.mutedText(context), height: 1.5),
          ),
        const SizedBox(height: 16),
        SelectableText(
          item.description.isEmpty
              ? adminText('No content provided.', 'المحتوى غير متوفر.')
              : item.description,
          style: TextStyle(
            color: AppColors.text(context),
            height: 1.8,
            fontSize: 15,
          ),
        ),
        if (item.kind == 'product') ...[
          const SizedBox(height: 16),
          const _BrandProductAvailability(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, en, ar) in [
                (
                  Icons.edit_outlined,
                  'Edit Brand Product',
                  'تعديل منتج العلامة',
                ),
                (
                  Icons.archive_outlined,
                  'Archive Brand Product',
                  'أرشفة منتج العلامة',
                ),
              ])
                OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(icon),
                  label: Text(adminText(en, ar)),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _BrandProductAvailability extends StatelessWidget {
  const _BrandProductAvailability();
  @override
  Widget build(BuildContext context) => AdminNotice(
    message: adminText(
      'Adding, editing and archiving brand products is currently unavailable. Inspection and publication moderation are available.',
      'إضافة منتجات العلامات وتعديلها وأرشفتها غير متاح حالياً. يمكن فحص المحتوى والتحكم في النشر.',
    ),
  );
}
