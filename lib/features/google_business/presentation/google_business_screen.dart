import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/widgets/async_action_button.dart';
import '../data/google_business_repository.dart';
import '../models/google_business.dart';
import '../services/google_business_controller.dart';
import '../../locations/data/uae_location_repository.dart';
import '../../locations/models/uae_location.dart';

/// Native Google Maps renderer is injectable only after restricted Android/iOS
/// keys and an approved SDK are configured. Never render Places content on OSM.
typedef GoogleBusinessMapBuilder =
    Widget Function(BuildContext, GoogleBusinessPlace);

class GoogleBusinessScreen extends StatefulWidget {
  const GoogleBusinessScreen({
    super.key,
    this.repository,
    this.onEditManualPin,
    this.mapBuilder,
    this.initialQuery = '',
    this.searchCity = '',
  });
  final GoogleBusinessRepository? repository;
  final Future<void> Function()? onEditManualPin;
  final GoogleBusinessMapBuilder? mapBuilder;
  final String initialQuery, searchCity;
  @override
  State<GoogleBusinessScreen> createState() => _GoogleBusinessScreenState();
}

class _GoogleBusinessScreenState extends State<GoogleBusinessScreen> {
  late final _controller = GoogleBusinessController(
    widget.repository ?? CurrentClinicGoogleBusinessRepository(),
  );
  final _query = TextEditingController();
  bool _confirming = false;
  bool _includeCity = true;
  bool get ar => LocaleService().isArabic;
  String t(String en, String arabic) => ar ? arabic : en;
  void _search(String value) {
    final query = value
        .replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e\u2066-\u2069]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final cityText = widget.searchCity.trim().isNotEmpty
        ? widget.searchCity.trim()
        : _controller.association?.city.trim() ?? '';
    final city = currentUaeCatalog.resolve(cityText);
    final label = city?.label(ar) ?? cityText;
    final normalized = UaeLocationCatalog.normalize(query);
    final includesCity = [cityText, city?.nameEn ?? '', city?.nameAr ?? '']
        .where((v) => v.isNotEmpty)
        .any((v) => normalized.contains(UaeLocationCatalog.normalize(v)));
    final contextual =
        query.isNotEmpty && _includeCity && label.isNotEmpty && !includesCity
        ? '$query, $label'
        : query;
    // The endpoint has no locationBias parameter. This is explicit query text,
    // not a fabricated API field, geocoder result or automatic identity link.
    _controller.queryChanged(contextual.length <= 120 ? contextual : query);
  }

  @override
  void initState() {
    super.initState();
    _query.text = widget.initialQuery;
    _controller.reload().then((_) {
      if (mounted && _query.text.trim().isNotEmpty) _search(_query.text);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlink() async {
    if (_confirming || _controller.busy) return;
    setState(() => _confirming = true);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(t('Unlink Google Business?', 'إلغاء ارتباط نشاط Google؟')),
        content: Text(
          t(
            'This clears the stored Google association and its cached ratings. Your manual clinic pin, photos and video are preserved.',
            'سيُزال ارتباط Google وتقييماته المخزنة. يبقى الدبوس اليدوي والصور والفيديو.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('Cancel', 'إلغاء')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('Unlink', 'إلغاء الارتباط')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (ok == true) await _controller.unlink();
  }

  Future<void> _open(String placeId) async {
    if (!GoogleBusinessPlace.validPlaceId(placeId)) {
      throw StateError('No confirmed place identity');
    }
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': placeId,
      'query_place_id': placeId,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Maps could not open');
    }
  }

  // Official compact text-attribution alternative for a narrow mobile result
  // pane. Untranslated, one line, sans serif400,14sp, accessible contrast.
  Widget _attribution(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'Google Maps',
      textDirection: TextDirection.ltr,
      maxLines: 1,
      softWrap: false,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.normal,
        fontSize: 14,
        letterSpacing: 0,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF1F1F1F),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_controller, LocaleService()]),
    builder: (context, _) {
      final c = _controller, current = c.association, place = c.selected;
      final cityContext = widget.searchCity.trim().isNotEmpty
          ? widget.searchCity
          : current?.city ?? '';
      return PopScope(
        canPop: !c.saving,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 80
                : 56,
            title: Text(t('Location & Google Business', 'الموقع ونشاط Google')),
          ),
          body: !c.allowed
              ? Center(
                  child: Text(
                    t(
                      'Clinic administrator access is required. Reopen this screen after signing in.',
                      'يلزم دخول مشرف العيادة. أعد فتح الشاشة بعد تسجيل الدخول.',
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      t(
                        'Link the exact clinic business',
                        'اربط نشاط العيادة الصحيح',
                      ),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t(
                        'Google Business identity and your manual clinic pin are separate. A similar name is not proof that a business belongs to your clinic.',
                        'هوية نشاط Google والدبوس اليدوي مستقلان. تشابه الاسم لا يثبت أن النشاط يتبع لعيادتك.',
                      ),
                    ),
                    if (c.loading || c.saving)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              current == null
                                  ? t(
                                      'Association not loaded',
                                      'لم يُحمّل الارتباط',
                                    )
                                  : current.linked
                                  ? t(
                                      'Google association stored',
                                      'ارتباط Google محفوظ',
                                    )
                                  : t(
                                      'No Google Business linked',
                                      'لا يوجد نشاط Google مرتبط',
                                    ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (current?.linked == true) ...[
                              SelectableText(
                                current!.placeId,
                                textDirection: TextDirection.ltr,
                              ),
                              Text(switch (current.verification) {
                                GoogleBusinessVerification.notProvided => t(
                                  'The stored Place ID identifies the association. Ownership verification is not supplied by the current service.',
                                  'معرّف المكان المحفوظ يحدد الارتباط. الخدمة الحالية لا توفر تحقق ملكية النشاط.',
                                ),
                                GoogleBusinessVerification.pending => t(
                                  'Business association verification is pending. Ownership has not been confirmed.',
                                  'التحقق من ارتباط النشاط قيد الانتظار. لم يتم تأكيد الملكية.',
                                ),
                                GoogleBusinessVerification.verified => t(
                                  'Selected Google place verified. This does not prove ownership of the Google Business Profile.',
                                  'تم التحقق من مكان Google المحدد. هذا لا يثبت ملكية الملف التجاري في Google.',
                                ),
                                GoogleBusinessVerification.rejected => t(
                                  'Association review was rejected. Refresh to review the current state.',
                                  'رُفضت مراجعة الارتباط. حدّث للاطلاع على الحالة الحالية.',
                                ),
                              }),
                              Text(switch (current.syncStatus) {
                                'pending' => t(
                                  'Ratings sync pending',
                                  'مزامنة التقييمات قيد الانتظار',
                                ),
                                'synced' => t(
                                  'Ratings synchronized — this does not verify ownership',
                                  'تمت مزامنة التقييمات؛ هذا لا يثبت الملكية',
                                ),
                                'failed' => t(
                                  'Ratings sync failed; refresh or ask platform management to review it',
                                  'تعذرت مزامنة التقييمات؛ حدّث أو اطلب المراجعة من إدارة المنصة',
                                ),
                                _ => t(
                                  'Ratings sync status unavailable',
                                  'حالة مزامنة التقييمات غير متاحة',
                                ),
                              }),
                              AsyncActionButton(
                                label: t(
                                  'Review business in Google Maps',
                                  'مراجعة النشاط في خرائط Google',
                                ),
                                icon: Icons.open_in_new,
                                onPressed: (_) => _open(current.placeId),
                              ),
                              if (c.repository.capabilities.unlink)
                                TextButton.icon(
                                  onPressed:
                                      c.busy || _confirming || c.needsRefresh
                                      ? null
                                      : _unlink,
                                  icon: const Icon(Icons.link_off),
                                  label: Text(
                                    t(
                                      'Unlink Google Business',
                                      'إلغاء ارتباط نشاط Google',
                                    ),
                                  ),
                                ),
                            ],
                            TextButton.icon(
                              onPressed: c.busy ? null : c.reload,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                t('Refresh association', 'تحديث الارتباط'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('Search Google Business', 'البحث عن نشاط Google'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (!c.repository.capabilities.search)
                      Text(
                        t(
                          'Google Business search is not available yet. You can review an existing association or adjust the manual pin.',
                          'البحث عن نشاط Google غير متاح حالياً. يمكنك مراجعة الارتباط الحالي أو ضبط الدبوس اليدوي.',
                        ),
                      ),
                    TextField(
                      key: const ValueKey('google-business-query'),
                      controller: _query,
                      maxLength: 120,
                      enabled:
                          c.repository.capabilities.search &&
                          !c.busy &&
                          !c.needsRefresh,
                      onChanged: _search,
                      decoration: InputDecoration(
                        labelText: t(
                          'Clinic or business name',
                          'اسم العيادة أو النشاط',
                        ),
                        hintText: t(
                          'Search in Arabic or English',
                          'ابحث بالعربية أو الإنجليزية',
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    if (cityContext.trim().isNotEmpty)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FilterChip(
                          label: Text(
                            t(
                              'Include $cityContext in search',
                              'تضمين $cityContext في البحث',
                            ),
                          ),
                          selected: _includeCity,
                          onSelected: c.busy || c.needsRefresh
                              ? null
                              : (value) {
                                  setState(() => _includeCity = value);
                                  _search(_query.text);
                                },
                        ),
                      ),
                    if (c.repository.capabilities.search) _attribution(context),
                    if (c.searching) const LinearProgressIndicator(),
                    if (c.repository.capabilities.search &&
                        c.hasSearched &&
                        c.suggestions.isEmpty &&
                        !c.searching &&
                        !c.loading &&
                        place == null &&
                        c.error == null)
                      Text(
                        t(
                          'No suggestions were returned. Try another name or try later if Google search is unavailable; a manual pin remains separate.',
                          'لم تُرجع الخدمة اقتراحات. جرّب اسماً آخر أو أعد المحاولة لاحقاً إذا كان البحث غير متاح؛ الدبوس اليدوي مستقل.',
                        ),
                      ),
                    for (final suggestion in c.suggestions)
                      ListTile(
                        title: Text(suggestion.name),
                        subtitle: Text(suggestion.address),
                        leading: const Icon(Icons.location_on_outlined),
                        onTap: () => c.select(suggestion),
                      ),
                    if (place != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                place.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(place.address),
                              Text(place.locality),
                              SelectableText(
                                '${place.latitude.toStringAsFixed(7)}, ${place.longitude.toStringAsFixed(7)}',
                                textDirection: TextDirection.ltr,
                              ),
                              _attribution(context),
                              SelectableText(
                                place.placeId,
                                textDirection: TextDirection.ltr,
                              ),
                              if (widget.mapBuilder != null)
                                SizedBox(
                                  height: 220,
                                  child: widget.mapBuilder!(context, place),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    t(
                                      'Inspect this exact business and its entrance in Google Maps before confirming. Linking does not move your independent clinic pin.',
                                      'راجع هذا النشاط ومدخله في خرائط Google قبل التأكيد. الربط لا يغيّر دبوس العيادة المستقل.',
                                    ),
                                  ),
                                ),
                              AsyncActionButton(
                                label: t(
                                  'Open selected place in Google Maps',
                                  'فتح المكان المحدد في خرائط Google',
                                ),
                                onPressed: (_) => _open(place.placeId),
                              ),
                              CheckboxListTile(
                                key: const ValueKey(
                                  'google-business-identity-confirm',
                                ),
                                contentPadding: EdgeInsets.zero,
                                value: c.confirmed,
                                onChanged: c.busy
                                    ? null
                                    : (v) => c.confirmIdentity(v ?? false),
                                title: Text(
                                  t(
                                    'I checked the name, address and map location. This is my clinic’s exact business.',
                                    'راجعت الاسم والعنوان والموقع. هذا هو نشاط عيادتي الصحيح.',
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed:
                                    c.busy ||
                                        c.needsRefresh ||
                                        !c.confirmed ||
                                        !c.repository.capabilities.link ||
                                        place.selectionProof.isEmpty ||
                                        c.proofExpired
                                    ? null
                                    : () => c.saveLink(),
                                child: Text(
                                  c.saving
                                      ? t(
                                          'Verifying association…',
                                          'جارٍ التحقق من الارتباط…',
                                        )
                                      : current?.linked == true
                                      ? t(
                                          'Verify and replace association',
                                          'التحقق واستبدال الارتباط',
                                        )
                                      : t(
                                          'Verify and link business',
                                          'التحقق وربط النشاط',
                                        ),
                                ),
                              ),
                              TextButton(
                                onPressed: c.busy ? null : c.cancelSelection,
                                child: Text(
                                  t('Cancel selection', 'إلغاء الاختيار'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (c.error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          c.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const Divider(height: 32),
                    Text(
                      t('Manual clinic pin', 'دبوس العيادة اليدوي'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      t(
                        'Adjust the reception/entrance location independently. This never searches, verifies or replaces a Google Business.',
                        'اضبط موقع الاستقبال أو المدخل بشكل مستقل. هذا لا يبحث عن نشاط Google ولا يتحقق منه ولا يستبدله.',
                      ),
                    ),
                    if (widget.onEditManualPin != null)
                      AsyncActionButton(
                        label: t(
                          'Edit manual clinic pin',
                          'تعديل الدبوس اليدوي للعيادة',
                        ),
                        icon: Icons.edit_location_alt_outlined,
                        onPressed: c.busy
                            ? null
                            : (action) async {
                                await action.wait(widget.onEditManualPin!());
                                await action.wait(c.reload());
                              },
                      ),
                  ],
                ),
        ),
      );
    },
  );
}
