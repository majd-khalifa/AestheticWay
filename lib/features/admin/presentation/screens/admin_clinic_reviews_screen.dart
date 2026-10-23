import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/data/paged_collection.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/luxury_image.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../data/admin_repository.dart';
import '../../models/admin_clinic_model.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';

String _statusLabel(String value) => switch (value) {
  'draft' => adminText('Draft', 'مسودة'),
  'submitted' => adminText('Submitted', 'مرسل للمراجعة'),
  'approved' => adminText('Approved', 'مقبول'),
  'rejected' => adminText('Rejected', 'مرفوض'),
  'pending' => adminText('Pending', 'معلق'),
  'active' => adminText('Active', 'مفعّل'),
  'suspended' => adminText('Suspended', 'موقوف'),
  _ => adminText('Unknown', 'غير معروف'),
};

/// 1f1e4bf has no setup-status filter/count or rejection transition. Inspect
/// paged server results honestly; never substitute account status=pending.
class AdminClinicReviewsScreen extends StatefulWidget {
  const AdminClinicReviewsScreen({super.key, this.repository});
  final AdminRepository? repository;
  @override
  State<AdminClinicReviewsScreen> createState() =>
      _AdminClinicReviewsScreenState();
}

class _AdminClinicReviewsScreenState extends State<AdminClinicReviewsScreen>
    with WidgetsBindingObserver {
  final _session = SessionSnapshot();
  late final _repo = widget.repository ?? AdminRepository();
  late final _page = PagedCollection<AdminClinicModel>(
    loader: (page, _) => _repo.getClinics(page: page),
    keyOf: (c) => c.id,
  );
  bool _submitted = true;
  bool get _allowed =>
      _session.isCurrent && AuthState().isLoggedIn && AuthState().isSuperAdmin;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthState().addListener(_changed);
    if (_allowed) _page.refresh();
  }

  void _changed() {
    if (!_allowed) _page.clear();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _allowed) _page.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthState().removeListener(_changed);
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(adminText('Clinic Reviews', 'مراجعة العيادات'))),
    body: !_allowed
        ? Center(
            child: Text(
              adminText(
                'Super Admin access is required.',
                'يتطلب الوصول حساب مشرف عام.',
              ),
            ),
          )
        : ListenableBuilder(
            listenable: _page,
            builder: (context, _) {
              final submitted = _page.items
                  .where((c) => c.setupStatus == 'submitted')
                  .toList();
              final rows = _submitted ? submitted : _page.items;
              return RefreshIndicator(
                onRefresh: () => _page.refresh(),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    AdminNotice(
                      message: adminText(
                        'Global pending count and server-side Submitted filtering are not provided by this backend. The Submitted filter covers loaded pages only. Profile rejection is not supported yet.',
                        'لا يوفر الخادم العدد الإجمالي المعلق أو تصفية المرسلة على الخادم. مرشح المرسلة يشمل الصفحات المحملة فقط. رفض ملف الإعداد غير مدعوم بعد.',
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(
                            adminText(
                              'Submitted (loaded)',
                              'المرسلة (المحمّلة)',
                            ),
                          ),
                          selected: _submitted,
                          onSelected: (_) => setState(() => _submitted = true),
                        ),
                        ChoiceChip(
                          label: Text(
                            adminText(
                              'All loaded profiles',
                              'كل الملفات المحمّلة',
                            ),
                          ),
                          selected: !_submitted,
                          onSelected: (_) => setState(() => _submitted = false),
                        ),
                      ],
                    ),
                    Text(
                      adminText(
                        'Submitted in loaded pages: ${submitted.length}',
                        'المرسلة في الصفحات المحمّلة: ${submitted.length}',
                      ),
                    ),
                    if (_page.isLoaded && rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          adminText(
                            'No matching profiles in loaded pages. Additional pages may contain submissions.',
                            'لا توجد ملفات مطابقة في الصفحات المحملة. قد تتضمن الصفحات التالية ملفات مرسلة.',
                          ),
                        ),
                      ),
                    for (final c in rows)
                      Card(
                        child: ListTile(
                          title: Text(
                            c.localizedName(
                              arabic:
                                  Directionality.of(context) ==
                                  TextDirection.rtl,
                            ),
                          ),
                          subtitle: Text(
                            '${adminText('Setup', 'الإعداد')}: ${_statusLabel(c.setupStatus)} • ${adminText('Access', 'التفعيل')}: ${_statusLabel(c.status)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => AdminClinicReviewDetail(
                                  clinicId: c.id,
                                  repository: _repo,
                                ),
                              ),
                            );
                            if (mounted && _allowed) {
                              await _page.refresh();
                              AdminPortalService().loadCollection(
                                'clinics',
                                refresh: true,
                              );
                            }
                          },
                        ),
                      ),
                    PaginationFooter(
                      loading: _page.isLoading || _page.isLoadingMore,
                      hasMore: _page.hasMore,
                      error: _page.error,
                      onLoadMore: _page.loadMore,
                    ),
                  ],
                ),
              );
            },
          ),
  );
}

class AdminClinicReviewDetail extends StatefulWidget {
  const AdminClinicReviewDetail({
    super.key,
    required this.clinicId,
    this.repository,
  });
  final String clinicId;
  final AdminRepository? repository;
  @override
  State<AdminClinicReviewDetail> createState() =>
      _AdminClinicReviewDetailState();
}

class _AdminClinicReviewDetailState extends State<AdminClinicReviewDetail> {
  final _session = SessionSnapshot();
  late final _repo = widget.repository ?? AdminRepository();
  AdminClinicModel? _clinic;
  bool _loading = false, _busy = false, _sending = false;
  String? _error;
  bool get _allowed =>
      _session.isCurrent && AuthState().isLoggedIn && AuthState().isSuperAdmin;
  @override
  void initState() {
    super.initState();
    AuthState().addListener(_changed);
    if (_allowed) _load();
  }

  void _changed() {
    if (mounted) {
      setState(() {
        if (!_allowed) _clinic = null;
      });
    }
  }

  @override
  void dispose() {
    AuthState().removeListener(_changed);
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || !_allowed) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await _repo.getClinicDetail(widget.clinicId);
      if (c.id != widget.clinicId) {
        throw ApiException(
          message: adminText(
            'Clinic profile identity could not be verified. Refresh before reviewing.',
            'تعذر التحقق من هوية ملف العيادة. حدّث البيانات قبل المراجعة.',
          ),
        );
      }
      if (mounted && _allowed) setState(() => _clinic = c);
    } catch (e) {
      if (mounted && _allowed) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : adminText('Could not load profile.', 'تعذر تحميل الملف.'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve() async {
    if (_busy || !_allowed || _clinic?.setupStatus != 'submitted') return;
    setState(() => _busy = true);
    try {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            adminText(
              'Approve profile and activate clinic?',
              'الموافقة على الملف وتفعيل العيادة؟',
            ),
          ),
          content: Text(
            adminText(
              'This backend action approves setup and activates the clinic together. Review the profile first. This is platform moderation, not medical or regulatory certification.',
              'يوافق هذا الإجراء على الإعداد ويفعّل العيادة معاً. راجع الملف أولاً. هذه مراجعة للمنصة وليست شهادة اعتماد طبي أو تنظيمي.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(adminText('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(adminText('Approve and activate', 'موافقة وتفعيل')),
            ),
          ],
        ),
      );
      if (yes != true || !mounted || !_allowed) return;
      setState(() => _sending = true);
      final c = await _repo.approveClinicProfile(widget.clinicId);
      if (mounted && _allowed) {
        setState(() {
          _clinic = c;
          _error = null;
        });
        await AdminPortalService().loadClinicDetail(c.id, refresh: true);
      }
    } catch (e) {
      if (mounted && _allowed) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : adminText(
                  'Approval was not confirmed. Refresh before retrying.',
                  'لم يتم تأكيد الموافقة. حدّث الحالة قبل المحاولة مجدداً.',
                ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _sending = false;
        });
      }
    }
  }

  Widget _field(String en, String ar, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: SelectableText(
      '${adminText(en, ar)}: ${value.isEmpty ? '—' : value}',
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          adminText('Submitted clinic profile', 'ملف العيادة المرسل'),
        ),
      ),
      body: !_allowed
          ? Center(
              child: Text(
                adminText(
                  'Super Admin access is required.',
                  'يتطلب الوصول حساب مشرف عام.',
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_loading || _sending) const LinearProgressIndicator(),
                  if (_error != null)
                    AdminNotice(message: _error!, error: true, onRetry: _load),
                  if (_clinic case final c?) ...[
                    Text(
                      c.nameEn,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (c.nameAr.isNotEmpty) Text(c.nameAr),
                    _field(
                      'Setup status',
                      'حالة الإعداد',
                      _statusLabel(c.setupStatus),
                    ),
                    _field(
                      'Account activation',
                      'تفعيل الحساب',
                      _statusLabel(c.status),
                    ),
                    LuxuryImage(
                      imageUrl: c.coverImage,
                      height: 180,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 12),
                    LuxuryImage(imageUrl: c.logo, height: 80, width: 80),
                    if (c.videoAdFile?.isNotEmpty == true)
                      _ReviewVideo(url: c.videoAdFile!),
                    _field(
                      'Description (English)',
                      'الوصف بالإنجليزية',
                      c.descriptionEn,
                    ),
                    _field(
                      'Description (Arabic)',
                      'الوصف بالعربية',
                      c.descriptionAr,
                    ),
                    _field('Phone', 'الهاتف', c.phone),
                    _field('WhatsApp', 'واتساب', c.whatsapp),
                    _field('Email', 'البريد الإلكتروني', c.email),
                    _field('Website', 'الموقع الإلكتروني', c.website),
                    _field(
                      'Address (English)',
                      'العنوان بالإنجليزية',
                      c.addressEn,
                    ),
                    _field('Address (Arabic)', 'العنوان بالعربية', c.addressAr),
                    _field('City', 'المدينة', c.city),
                    _field(
                      'Coordinates',
                      'الإحداثيات',
                      '${c.storedLatitude ?? '—'}, ${c.storedLongitude ?? '—'}',
                    ),
                    _field(
                      'Submitted at',
                      'وقت الإرسال',
                      c.submittedForReviewAt?.toIso8601String() ?? '',
                    ),
                    for (final b in c.branches)
                      _field(
                        'Branch',
                        'الفرع',
                        '${b.nameEn} ${b.nameAr} — ${b.addressEn} — ${b.latitude ?? '—'}, ${b.longitude ?? '—'}',
                      ),
                    _field(
                      'Practitioners / Treatments / Offers',
                      'الممارسون / العلاجات / العروض',
                      '${c.practitionersCount} / ${c.treatmentsCount} / ${c.offersCount}',
                    ),
                    _field(
                      'Platform notes',
                      'ملاحظات المنصة',
                      ApiException.sanitizeRegulatoryCompliance(
                        c.moderationNotes,
                      ),
                    ),
                    if (c.setupStatus == 'submitted')
                      FilledButton(
                        key: const ValueKey('approve-clinic-profile'),
                        onPressed: _busy ? null : _approve,
                        child: Text(
                          adminText(
                            'Approve clinic profile',
                            'الموافقة على ملف العيادة',
                          ),
                        ),
                      ),
                    AdminNotice(
                      message: adminText(
                        'Setup rejection and clinic-visible feedback are BLOCKED BY BACKEND. Activation/suspension is a separate account action and must not substitute for a setup decision. The API supplies catalog counts, not complete staff/treatment records.',
                        'رفض الإعداد وملاحظاته المرئية للعيادة محجوبان من الخادم. التفعيل والإيقاف إجراءان منفصلان للحساب ولا يحلان محل قرار الإعداد. يوفر الرد أعداد الكتالوج وليس سجلات الفريق والعلاجات الكاملة.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
    ),
  );
}

class _ReviewVideo extends StatefulWidget {
  const _ReviewVideo({required this.url});
  final String url;
  @override
  State<_ReviewVideo> createState() => _ReviewVideoState();
}

class _ReviewVideoState extends State<_ReviewVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_loading) return;
    if (_controller?.value.isInitialized == true) {
      if (_controller!.value.isPlaying) {
        await _controller!.pause();
      } else {
        await _controller!.play();
      }
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.play();
    } catch (_) {
      if (mounted) {
        _error = adminText(
          'Video could not be loaded. Try again.',
          'تعذر تحميل الفيديو. حاول مجدداً.',
        );
      }
      _controller = null;
      await controller.dispose();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_controller?.value.isInitialized == true)
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      OutlinedButton(
        onPressed: _loading ? null : _play,
        child: Text(
          _loading
              ? adminText('Loading video…', 'جارٍ تحميل الفيديو…')
              : adminText(
                  'Play / pause clinic video',
                  'تشغيل / إيقاف فيديو العيادة',
                ),
        ),
      ),
      if (_error != null) Text(_error!),
    ],
  );
}
