import 'package:flutter/material.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/data/paged_collection.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/pagination_footer.dart';
import '../../clinic_portal/services/clinic_portal_service.dart';
import '../data/category_request_repository.dart';
import '../models/category_request_model.dart';
import 'category_editor.dart';

class CategoryRequestsScreen extends StatefulWidget {
  const CategoryRequestsScreen({
    super.key,
    this.admin = false,
    this.repository,
  });
  final bool admin;
  final CategoryRequestRepository? repository;
  @override
  State<CategoryRequestsScreen> createState() => _CategoryRequestsScreenState();
}

class _CategoryRequestsScreenState extends State<CategoryRequestsScreen> {
  final _session = SessionSnapshot();
  late final _repository = widget.repository ?? CategoryRequestRepository();
  late final _page = PagedCollection<CategoryRequestModel>(
    keyOf: (r) => r.id,
    loader: (page, query) => _repository.list(
      admin: widget.admin,
      page: page,
      status: query['status'] as String?,
    ),
  );
  String _status = 'pending';
  String? _busy, _error;
  bool get _allowed =>
      _session.isCurrent &&
      AuthState().isLoggedIn &&
      (widget.admin
          ? AuthState().isSuperAdmin
          : AuthState().isClinicAdmin || AuthState().isClinicStaff);
  @override
  void initState() {
    super.initState();
    AuthState().addListener(_changed);
    if (_allowed) _refresh();
  }

  void _changed() {
    if (!_allowed) _page.clear();
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    if (!_allowed) return;
    await _page.refresh(query: {if (widget.admin) 'status': _status});
    if (_allowed && !widget.admin) {
      await ClinicPortalService().loadCollection('categories', refresh: true);
    }
  }

  @override
  void dispose() {
    AuthState().removeListener(_changed);
    _page.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (!_allowed || _busy != null) return;
    setState(() => _busy = 'new');
    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CategoryEditor(
          request: true,
          onSave: (en, ar, _, _) async {
            await _repository.submit(nameEn: en, nameAr: ar);
          },
        ),
      );
      if (saved == true && mounted && _allowed) await _refresh();
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _review(CategoryRequestModel request, bool approve) async {
    if (!_allowed || _busy != null) return;
    setState(() => _busy = 'confirmation-dialog');
    var reason = '';
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            approve
                ? categoryText(
                    'Approve category request?',
                    'الموافقة على طلب التصنيف؟',
                  )
                : categoryText('Reject category request?', 'رفض طلب التصنيف؟'),
          ),
          content: approve
              ? Text(request.nameEn)
              : TextField(
                  key: const ValueKey('category-rejection-reason'),
                  onChanged: (value) => reason = value,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: categoryText(
                      'Reason for the clinic',
                      'السبب للعيادة',
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(categoryText('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(categoryText('Confirm', 'تأكيد')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted || !_allowed) return;
      setState(() {
        _busy = request.id;
        _error = null;
      });
      await _repository.review(request.id, approve: approve, reason: reason);
      if (mounted && _allowed) await _refresh();
    } catch (e) {
      if (mounted && _allowed) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : categoryText(
                  'Unable to review the request. Try again.',
                  'تعذرت مراجعة الطلب. حاول مجدداً.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  String _statusLabel(String status) => switch (status) {
    'pending' => categoryText('Pending approval', 'بانتظار الموافقة'),
    'approved' => categoryText('Approved', 'تمت الموافقة'),
    'rejected' => categoryText('Rejected', 'مرفوض'),
    _ => categoryText('Status unavailable', 'الحالة غير متاحة'),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(categoryText('Category requests', 'طلبات التصنيفات')),
    ),
    body: !_allowed
        ? Center(
            child: Text(
              categoryText(
                'This account cannot access these requests.',
                'لا يملك هذا الحساب صلاحية الوصول إلى الطلبات.',
              ),
            ),
          )
        : ListenableBuilder(
            listenable: _page,
            builder: (context, _) => RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (widget.admin) ...[
                    Text(
                      categoryText('Pending requests: ', 'الطلبات المعلقة: ') +
                          (_status == 'pending' && _page.total != null
                              ? '${_page.total}'
                              : categoryText(
                                  'select Pending approval to refresh',
                                  'اختر بانتظار الموافقة للتحديث',
                                )),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: InputDecoration(
                        labelText: categoryText('Request status', 'حالة الطلب'),
                      ),
                      items: ['pending', 'approved', 'rejected']
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(_statusLabel(s)),
                            ),
                          )
                          .toList(),
                      onChanged: _busy != null
                          ? null
                          : (s) {
                              if (s != null) {
                                setState(() => _status = s);
                                _refresh();
                              }
                            },
                    ),
                  ] else ...[
                    Text(
                      categoryText(
                        'Requests need Super Admin approval. A submitted request is not an active treatment category. Pull to refresh approvals and the category directory.',
                        'تحتاج الطلبات إلى موافقة المشرف العام. إرسال الطلب لا ينشئ تصنيفاً نشطاً. اسحب للتحديث ومزامنة التصنيفات المعتمدة.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('request-new-category'),
                      onPressed: _busy != null ? null : _request,
                      icon: const Icon(Icons.add),
                      label: Text(
                        categoryText('Request a category', 'طلب تصنيف'),
                      ),
                    ),
                  ],
                  if (_error != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_page.isLoaded && _page.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        categoryText(
                          'No category requests.',
                          'لا توجد طلبات تصنيفات.',
                        ),
                      ),
                    ),
                  for (final request in _page.items)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.nameEn,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (request.nameAr.isNotEmpty) Text(request.nameAr),
                            if (widget.admin && request.clinicName.isNotEmpty)
                              Text(request.clinicName),
                            Text(_statusLabel(request.status)),
                            if (request.status == 'rejected' &&
                                request.rejectionReason.isNotEmpty)
                              Text(
                                ApiException.sanitizeRegulatoryCompliance(
                                  request.rejectionReason,
                                ),
                              ),
                            if (widget.admin && request.status == 'pending')
                              Wrap(
                                spacing: 12,
                                children: [
                                  TextButton.icon(
                                    onPressed: _busy != null
                                        ? null
                                        : () => _review(request, true),
                                    icon: _busy == request.id
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.check),
                                    label: Text(
                                      categoryText('Approve', 'موافقة'),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _busy != null
                                        ? null
                                        : () => _review(request, false),
                                    child: Text(categoryText('Reject', 'رفض')),
                                  ),
                                ],
                              ),
                          ],
                        ),
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
            ),
          ),
  );
}
