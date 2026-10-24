import '../widgets/admin_clinic_inspection.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/data/paged_collection.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/portal_media_frame.dart';
import '../../../../core/widgets/luxury_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../data/admin_repository.dart';
import '../../services/admin_review_service.dart';
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

/// Server-filtered setup reviews. Account activation is a separate field.
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
    loader: (page, q) =>
        _repo.getClinics(page: page, setupStatus: q['setup_status'] as String?),
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
    if (_allowed) _refresh();
  }

  Future<void> _refresh() =>
      _page.refresh(query: {'setup_status': _submitted ? 'submitted' : 'all'});

  void _changed() {
    if (!_allowed) _page.clear();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _allowed) _refresh();
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
              final rows = _page.items;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(adminText('Submitted', 'المرسلة')),
                          selected: _submitted,
                          onSelected: (_) {
                            setState(() => _submitted = true);
                            _refresh();
                          },
                        ),
                        ChoiceChip(
                          label: Text(adminText('All profiles', 'كل الملفات')),
                          selected: !_submitted,
                          onSelected: (_) {
                            setState(() => _submitted = false);
                            _refresh();
                          },
                        ),
                      ],
                    ),
                    Text(
                      adminText(
                        'Matching profiles: ${_page.total ?? '—'}',
                        'الملفات المطابقة: ${_page.total ?? '—'}',
                      ),
                    ),
                    if (_page.isLoaded && rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          adminText(
                            'No profiles match this filter.',
                            'لا توجد ملفات مطابقة لهذا المرشح.',
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
                              await _refresh();
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
        await _load();
        if (!mounted || !_allowed) return;
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
      if (_allowed) AdminReviewService().refresh();
      if (mounted) {
        setState(() {
          _busy = false;
          _sending = false;
        });
      }
    }
  }

  Future<void> _reject() async {
    if (_busy || !_allowed || _clinic?.setupStatus != 'submitted') return;
    setState(() => _busy = true);
    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (_) => const _ClinicRejectionDialog(),
      );
      if (reason == null || !mounted || !_allowed) return;
      setState(() => _sending = true);
      final updated = await _repo.rejectClinicSetup(widget.clinicId, reason);
      if (mounted && _allowed) {
        setState(() {
          _clinic = updated;
          _error = null;
        });
        await AdminPortalService().loadClinicDetail(updated.id, refresh: true);
      }
    } catch (e) {
      if (mounted && _allowed) {
        await _load();
        if (mounted && _allowed) {
          setState(
            () => _error = e is ApiException
                ? e.message
                : adminText(
                    'The decision was not confirmed. Refresh before retrying.',
                    'لم يتم تأكيد القرار. حدّث الحالة قبل المحاولة.',
                  ),
          );
        }
      }
    } finally {
      if (_allowed) AdminReviewService().refresh();
      if (mounted) {
        setState(() {
          _busy = false;
          _sending = false;
        });
      }
    }
  }

  Widget _field(String en, String ar, String value, {bool ltr = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              adminText(en, ar),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedText(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 3),
            SelectableText(
              value.isEmpty ? '—' : value,
              textDirection: ltr ? TextDirection.ltr : null,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text(context),
                height: 1.6,
              ),
            ),
          ],
        ),
      );
  Widget _section(String en, String ar, IconData icon, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: LuxuryCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.goldText(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      adminText(en, ar),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      backgroundColor: AppColors.bg(context),
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
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_loading || _sending) const LinearProgressIndicator(),
                  if (_error != null)
                    AdminNotice(message: _error!, error: true, onRetry: _load),
                  if (_clinic case final c?) ...[
                    _section(
                      'Clinic identity',
                      'هوية العيادة',
                      Icons.apartment_outlined,
                      [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PortalMediaFrame(
                              imageUrl: c.logo,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                              radius: 18,
                              expandable: true,
                              label: adminText('Clinic logo', 'شعار العيادة'),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.localizedName(
                                      arabic:
                                          Directionality.of(context) ==
                                          TextDirection.rtl,
                                    ),
                                    style: TextStyle(
                                      fontSize: 19,
                                      height: 1.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                  if (c.nameAr.isNotEmpty &&
                                      c.nameEn.isNotEmpty &&
                                      c.nameAr != c.nameEn)
                                    Text(
                                      Directionality.of(context) ==
                                              TextDirection.rtl
                                          ? c.nameEn
                                          : c.nameAr,
                                      style: TextStyle(
                                        color: AppColors.mutedText(context),
                                        height: 1.5,
                                      ),
                                    ),
                                  if (c.city.isNotEmpty)
                                    Text(
                                      c.locationLabel(
                                        arabic:
                                            Directionality.of(context) ==
                                            TextDirection.rtl,
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
                        const Divider(height: 28),
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
                      ],
                    ),
                    _section(
                      'Uploaded media',
                      'الوسائط المرفوعة',
                      Icons.photo_library_outlined,
                      [
                        PortalMediaFrame(
                          imageUrl: c.coverImage,
                          expandable: true,
                          label: adminText('Clinic cover', 'غلاف العيادة'),
                        ),
                        if (c.videoAdFile?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          _ReviewVideo(url: c.videoAdFile!),
                        ],
                        AdminClinicInspection(
                          key: ValueKey('gallery-${c.id}'),
                          clinic: c,
                          content: false,
                        ),
                      ],
                    ),
                    _section(
                      'Clinic profile',
                      'ملف العيادة',
                      Icons.description_outlined,
                      [
                        _field(
                          'Description (English)',
                          'الوصف بالإنجليزية',
                          c.descriptionEn,
                          ltr: true,
                        ),
                        _field(
                          'Description (Arabic)',
                          'الوصف بالعربية',
                          c.descriptionAr,
                        ),
                      ],
                    ),
                    _section(
                      'Contact details',
                      'معلومات الاتصال',
                      Icons.contact_phone_outlined,
                      [
                        _field('Phone', 'الهاتف', c.phone, ltr: true),
                        _field('WhatsApp', 'واتساب', c.whatsapp, ltr: true),
                        _field(
                          'Email',
                          'البريد الإلكتروني',
                          c.email,
                          ltr: true,
                        ),
                        _field(
                          'Website',
                          'الموقع الإلكتروني',
                          c.website,
                          ltr: true,
                        ),
                      ],
                    ),
                    _section(
                      'Location and branches',
                      'الموقع والفروع',
                      Icons.location_on_outlined,
                      [
                        _field(
                          'Address (English)',
                          'العنوان بالإنجليزية',
                          c.addressEn,
                          ltr: true,
                        ),
                        _field(
                          'Address (Arabic)',
                          'العنوان بالعربية',
                          c.addressAr,
                        ),
                        _field('City', 'المدينة', c.city),
                        _field('Emirate', 'الإمارة', c.emirate),
                        _field(
                          'Coordinates',
                          'الإحداثيات',
                          '${c.storedLatitude ?? '—'}, ${c.storedLongitude ?? '—'}',
                          ltr: true,
                        ),
                        _field(
                          'Google Maps',
                          'خرائط جوجل',
                          c.googleMapsUrl,
                          ltr: true,
                        ),
                        for (final b in c.branches) ...[
                          const Divider(height: 20),
                          _field('Branch', 'الفرع', '${b.nameEn} ${b.nameAr}'),
                          _field(
                            'Branch location',
                            'موقع الفرع',
                            '${b.addressEn} • ${b.city}',
                          ),
                          _field(
                            'Branch phone',
                            'هاتف الفرع',
                            b.phone,
                            ltr: true,
                          ),
                          _field(
                            'Branch coordinates',
                            'إحداثيات الفرع',
                            '${b.latitude ?? '—'}, ${b.longitude ?? '—'}',
                            ltr: true,
                          ),
                        ],
                      ],
                    ),
                    _section(
                      'Practitioners and treatments',
                      'الممارسون والعلاجات',
                      Icons.medical_services_outlined,
                      [
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _field(
                              'Practitioners',
                              'الممارسون',
                              '${c.practitionersCount}',
                            ),
                            _field(
                              'Treatments',
                              'العلاجات',
                              '${c.treatmentsCount}',
                            ),
                            _field('Offers', 'العروض', '${c.offersCount}'),
                          ],
                        ),
                        AdminClinicInspection(
                          key: ValueKey('content-${c.id}'),
                          clinic: c,
                          gallery: false,
                        ),
                      ],
                    ),
                    _section(
                      'Submission and decision',
                      'الإرسال والقرار',
                      Icons.fact_check_outlined,
                      [
                        _field(
                          'Submitted at',
                          'وقت الإرسال',
                          c.submittedForReviewAt?.toLocal().toIso8601String() ??
                              '',
                          ltr: true,
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                adminText(
                                  'Approve clinic profile',
                                  'الموافقة على ملف العيادة',
                                ),
                              ),
                            ),
                          ),
                        if (c.setupStatus == 'submitted')
                          OutlinedButton.icon(
                            key: const ValueKey('reject-clinic-profile'),
                            onPressed: _busy ? null : _reject,
                            icon: const Icon(Icons.edit_note),
                            label: Text(
                              adminText(
                                'Request profile changes',
                                'طلب تعديلات على الملف',
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        AdminNotice(
                          message: adminText(
                            'Rejection changes profile review only. Account activation/suspension remains a separate action.',
                            'الرفض يغير مراجعة الملف فقط. يظل التفعيل والإيقاف إجراءين منفصلين للحساب.',
                          ),
                        ),
                      ],
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

class _ClinicRejectionDialog extends StatefulWidget {
  const _ClinicRejectionDialog();
  @override
  State<_ClinicRejectionDialog> createState() => _ClinicRejectionDialogState();
}

class _ClinicRejectionDialogState extends State<_ClinicRejectionDialog> {
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(adminText('Request profile changes', 'طلب تعديلات على الملف')),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            adminText(
              'Explain what the clinic must correct. Account activation will remain unchanged.',
              'وضّح ما يجب على العيادة تصحيحه. لن تتغير حالة تفعيل الحساب.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('clinic-review-reason'),
            controller: _reason,
            maxLength: 1000,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: adminText(
                'Required correction details',
                'تفاصيل التعديل المطلوبة',
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(adminText('Cancel', 'إلغاء')),
      ),
      FilledButton(
        key: const ValueKey('confirm-clinic-rejection'),
        onPressed: _reason.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _reason.text.trim()),
        child: Text(adminText('Send changes request', 'إرسال طلب التعديل')),
      ),
    ],
  );
}
