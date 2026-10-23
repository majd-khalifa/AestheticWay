import '../../treatments/models/category_request_model.dart';
import 'package:flutter/foundation.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/data/paged_collection.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/localization/app_locale.dart';
import '../../treatments/data/category_request_repository.dart';

/// One bounded count read per entry/resume/decision, never a build-time poll.
class AdminReviewService extends ChangeNotifier {
  static final _instance = AdminReviewService.withRepository(
    CategoryRequestRepository(),
  );
  factory AdminReviewService() => _instance;
  AdminReviewService.withRepository(this._repository) {
    AuthState().addListener(_sessionChanged);
    CategoryRequestRepository.decisions.addListener(_decisionChanged);
  }
  final CategoryRequestRepository _repository;
  int? pendingCategories;
  bool loading = false;
  String? error;
  Future<void>? _flight;
  int _generation = 0;
  int _identity = AuthState().sessionEpoch;
  void _sessionChanged() {
    if (_identity == AuthState().sessionEpoch) return;
    _identity = AuthState().sessionEpoch;
    ++_generation;
    _flight = null;
    pendingCategories = null;
    loading = false;
    error = null;
    notifyListeners();
  }

  void _decisionChanged() {
    if (!AuthState().isLoggedIn || !AuthState().isSuperAdmin) return;
    // A pre-decision GET may still be in flight. It must neither satisfy nor
    // overwrite this post-write read, even when its response arrives last.
    ++_generation;
    _flight = null;
    refresh();
  }

  Future<void> refresh() {
    if (!AuthState().isLoggedIn || !AuthState().isSuperAdmin) {
      return Future.value();
    }
    if (_flight != null) return _flight!;
    final session = SessionSnapshot();
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    late final Future<void> flight;
    flight =
        (() async {
          try {
            final rows = await _repository.list(admin: true, status: 'pending');
            if (!session.isCurrent || generation != _generation) return;
            // A row count is NOT the global total when pagination is present.
            pendingCategories = rows is PageItems<CategoryRequestModel>
                ? rows.total
                : null;
          } catch (e) {
            if (!session.isCurrent || generation != _generation) return;
            pendingCategories = null;
            error = e is ApiException
                ? e.message
                : LocaleService().isArabic
                ? 'تعذر تحميل عدد الطلبات.'
                : 'Could not load the request count.';
          } finally {
            if (session.isCurrent && generation == _generation) {
              loading = false;
              notifyListeners();
            }
          }
        })().whenComplete(() {
          if (identical(_flight, flight)) _flight = null;
        });
    _flight = flight;
    return flight;
  }

  @override
  void dispose() {
    ++_generation;
    AuthState().removeListener(_sessionChanged);
    CategoryRequestRepository.decisions.removeListener(_decisionChanged);
    super.dispose();
  }
}
