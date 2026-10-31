import 'package:flutter/material.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/data/paged_collection.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/paged_entity_picker.dart';
import '../../data/admin_repository.dart';
import '../../models/admin_clinic_model.dart';
import '../../models/admin_lead_model.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';
import 'admin_lead_detail_screen.dart';

class AdminLeadsScreen extends StatefulWidget {
  const AdminLeadsScreen({
    super.key,
    this.initialClinic,
    this.dateFrom,
    this.dateTo,
  });
  final AdminClinicModel? initialClinic;
  final String? dateFrom, dateTo;
  @override
  State<AdminLeadsScreen> createState() => _AdminLeadsScreenState();
}

class _AdminLeadsScreenState extends State<AdminLeadsScreen> {
  final _service = AdminPortalService();
  final _search = TextEditingController();
  AdminClinicModel? _clinic;
  String? _status;
  PagedCollection<AdminLeadModel>? _scoped;
  final _session = SessionSnapshot();
  void _sessionChanged() {
    if (!_session.isCurrent) _scoped?.clear();
  }

  Map<String, dynamic> get _queryValues => {
    'search': _search.text.trim(),
    'clinic': _clinic?.id,
    'status': _status,
    'date_from': widget.dateFrom,
    'date_to': widget.dateTo,
  };

  @override
  void initState() {
    super.initState();
    _clinic = widget.initialClinic;
    if (_clinic != null || widget.dateFrom != null || widget.dateTo != null) {
      _scoped = PagedCollection<AdminLeadModel>(
        keyOf: (l) => l.id,
        loader: (page, q) => _service.getLeadRecordsPage(page, q),
      );
      AuthState().addListener(_sessionChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scoped != null) {
        _scoped!.refresh(query: _queryValues);
      } else {
        _service.loadCollection('leads', refresh: true, query: _queryValues);
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    AuthState().removeListener(_sessionChanged);
    _scoped?.dispose();
    super.dispose();
  }

  void _query() {
    if (_scoped != null) {
      _scoped!.search(_queryValues);
    } else {
      _service.searchCollection('leads', _queryValues);
    }
  }

  Future<void> _chooseClinic() async {
    final result = await showPagedEntityPicker<AdminClinicModel>(
      context,
      title: LocaleService().tr('admin_filter_all_clinics'),
      hint: LocaleService().tr('admin_clinic_search_hint'),
      clearLabel: LocaleService().tr('admin_filter_all_clinics'),
      selectedKey: _clinic?.id,
      keyOf: (c) => c.id,
      labelOf: (c) => c.localizedName(arabic: LocaleService().isArabic),
      loader: (page, search) =>
          AdminRepository().getClinics(page: page, search: search),
    );
    if (!mounted || result == null) return;
    setState(() => _clinic = result.value);
    _query();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_service, LocaleService(), ?_scoped]),
    builder: (context, _) {
      var leads = _scoped?.items ?? _service.allLeads;
      if (_service.isMockMode) {
        leads = _service
            .getFilteredLeads(clinicId: _clinic?.id, status: _status)
            .where(
              (l) =>
                  '${l.patientName} ${l.patientPhone} ${l.referenceCode} ${l.clinicNameEn} ${l.clinicNameAr}'
                      .toLowerCase()
                      .contains(_search.text.toLowerCase()),
            )
            .toList();
      }
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: AdminDirectory<AdminLeadModel>(
          items: leads,
          page: _scoped ?? _service.collection('leads'),
          onRefresh: () =>
              _scoped?.refresh(force: true) ??
              _service.loadCollection('leads', refresh: true),
          onLoadMore: () => _scoped?.loadMore() ?? _service.loadMore('leads'),
          headers: [
            AdminSectionTitle(
              adminText('Consultation requests', 'طلبات الاستشارة'),
            ),
            AdminNotice(
              message: LocaleService().tr('admin_lead_monitoring_banner'),
            ),
            if (widget.dateFrom != null && widget.dateTo != null)
              Text(
                '${widget.dateFrom} — ${widget.dateTo} · UTC+4',
                textDirection: TextDirection.ltr,
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: adminText('Search requests', 'البحث في الطلبات'),
                hintText: adminText(
                  'Patient, phone, clinic or reference',
                  'المريض أو الهاتف أو العيادة أو رقم الطلب',
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) {
                setState(() {});
                _query();
              },
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _chooseClinic,
              icon: const Icon(Icons.apartment_outlined),
              label: Text(
                _clinic?.localizedName(arabic: LocaleService().isArabic) ??
                    LocaleService().tr('admin_filter_all_clinics'),
              ),
              style: TextButton.styleFrom(
                alignment: AlignmentDirectional.centerStart,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final status in <String?>[
                  null,
                  'new',
                  'contacted',
                  'closed',
                ])
                  ChoiceChip(
                    label: Text(
                      status == null
                          ? LocaleService().tr('status_all')
                          : LocaleService().tr(
                              'clinic_lead_status_${status == 'new' ? 'new' : status}',
                            ),
                    ),
                    selected: status == _status,
                    onSelected: (_) {
                      setState(() => _status = status);
                      _query();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          itemBuilder: (context, l) => AdminLeadCard(
            lead: l,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminLeadDetailScreen(lead: l)),
            ),
          ),
        ),
      );
    },
  );
}
