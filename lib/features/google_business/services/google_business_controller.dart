import '../../locations/services/patient_location_controller.dart';
import 'dart:async';
import 'package:clock/clock.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_exception.dart';
import '../data/google_business_repository.dart';
import '../models/google_business.dart';

class GoogleBusinessController extends ChangeNotifier {
  GoogleBusinessController(this.repository, {DateTime Function()? now})
    : _now = now ?? clock.now {
    AuthState().addListener(_authChanged);
    LocaleService().addListener(_languageChanged);
  }
  final GoogleBusinessRepository repository;
  final DateTime Function() _now;
  DateTime? _tokenIssuedAt, _proofExpiresAt;
  Timer? _proofTimer;
  bool _expiredProof = false;
  bool get proofExpired =>
      _expiredProof ||
      _proofExpiresAt != null && !_now().isBefore(_proofExpiresAt!);
  void _retireProof() {
    _proofTimer?.cancel();
    _proofExpiresAt = null;
    _expiredProof = false;
  }

  String? _tokenLanguage;
  final _session = SessionSnapshot();
  GoogleBusinessAssociation? association;
  List<GooglePlaceSuggestion> suggestions = const [];
  GoogleBusinessPlace? selected;
  bool loading = false,
      searching = false,
      saving = false,
      confirmed = false,
      needsRefresh = false,
      hasSearched = false;
  String? error;
  Timer? _debounce;
  String? _token;
  int _generation = 0;
  bool _disposed = false;
  bool get allowed =>
      !_disposed &&
      _session.isCurrent &&
      AuthState().isLoggedIn &&
      AuthState().isClinicAdmin;
  bool get busy => loading || saving;
  String _text(String en, String ar) => LocaleService().isArabic ? ar : en;
  bool _current(int g) => allowed && g == _generation;
  static String _newToken() {
    final r = Random.secure();
    final b = List.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  void _languageChanged() {
    if (!allowed || saving) return;
    ++_generation;
    _debounce?.cancel();
    _token = null;
    _retireProof();
    selected = null;
    suggestions = const [];
    confirmed = false;
    loading = false;
    searching = false;
    error = null;
    hasSearched = false;
    notifyListeners();
  }

  void _authChanged() {
    if (!allowed && !_disposed) {
      _debounce?.cancel();
      ++_generation;
      _token = null;
      association = null;
      _retireProof();
      selected = null;
      suggestions = const [];
      confirmed = false;
      error = null;
      loading = false;
      searching = false;
      saving = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (!allowed || busy) return;
    final g = ++_generation;
    _debounce?.cancel();
    _token = null;
    _retireProof();
    selected = null;
    suggestions = const [];
    confirmed = false;
    searching = false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final value = await repository.current();
      if (_current(g)) {
        association = value;
        needsRefresh = false;
      }
    } catch (_) {
      if (_current(g)) {
        error = _text(
          'Could not load the current Google association. Try again.',
          'تعذر تحميل ارتباط Google الحالي. أعد المحاولة.',
        );
      }
    } finally {
      if (_current(g)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void queryChanged(String value) {
    if (!allowed || busy || needsRefresh) return;
    _debounce?.cancel();
    final g = ++_generation;
    _retireProof();
    selected = null;
    confirmed = false;
    hasSearched = false;
    suggestions = const [];
    error = null;
    searching = false;
    final query = value.trim();
    if (!repository.capabilities.search ||
        query.length < 2 ||
        query.length > 120) {
      _token = null;
      notifyListeners();
      return;
    }
    final language = LocaleService().currentLanguage.code;
    if (_tokenIssuedAt != null &&
        (_now().difference(_tokenIssuedAt!) >= const Duration(minutes: 3) ||
            language != _tokenLanguage)) {
      _token = null;
    }
    if (_token == null) {
      _token = _newToken();
      _tokenIssuedAt = _now();
      _tokenLanguage = language;
    }
    final token = _token!;
    searching = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final rows = await repository.autocomplete(
          query,
          sessionToken: token,
          languageCode: language,
        );
        if (_current(g)) {
          suggestions = rows
              .where((s) => GoogleBusinessPlace.validPlaceId(s.placeId))
              .toList(growable: false);
          hasSearched = true;
        }
      } catch (_) {
        if (_current(g)) {
          error = _text(
            'Google search could not load. Try again or use a manual pin.',
            'تعذر تحميل بحث Google. أعد المحاولة أو استخدم الدبوس اليدوي.',
          );
          _token = null;
        }
      } finally {
        if (_current(g)) {
          searching = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> select(GooglePlaceSuggestion suggestion) async {
    if (!allowed ||
        busy ||
        !repository.capabilities.search ||
        _token == null ||
        !suggestions.contains(suggestion)) {
      return;
    }
    _debounce?.cancel();
    final g = ++_generation;
    final token = _token!;
    _token = null;
    loading = true;
    searching = false;
    error = null;
    _retireProof();
    selected = null;
    confirmed = false;
    suggestions = const [];
    notifyListeners();
    try {
      final value = await repository.details(
        suggestion.placeId,
        sessionToken: token,
        languageCode: LocaleService().currentLanguage.code,
      );
      if (!_current(g)) return;
      if (value.placeId != suggestion.placeId ||
          value.countryCode.toUpperCase() != 'AE' ||
          !PatientPosition(value.latitude, value.longitude).potentiallyUae) {
        throw StateError('Unverified selected place');
      }
      selected = value;
      _proofExpiresAt = _now().add(value.proofExpiresIn);
      _proofTimer = Timer(value.proofExpiresIn, () {
        if (!allowed || _disposed) return;
        _expiredProof = true;
        confirmed = false;
        error = _text(
          'This selection has expired. Search again to request fresh details.',
          'انتهت صلاحية الاختيار. ابحث مجدداً لطلب تفاصيل جديدة.',
        );
        notifyListeners();
      });
    } catch (_) {
      if (_current(g)) {
        error = _text(
          'This result could not be verified. Search again and choose the exact UAE business.',
          'تعذر التحقق من هذه النتيجة. ابحث مجدداً واختر نشاط العيادة الإماراتي الصحيح.',
        );
      }
    } finally {
      if (_current(g)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void confirmIdentity(bool value) {
    if (!busy && allowed) {
      confirmed = value && selected != null && !proofExpired;
      notifyListeners();
    }
  }

  Future<bool> saveLink() async {
    final place = selected, before = association;
    if (!allowed ||
        busy ||
        needsRefresh ||
        !confirmed ||
        place == null ||
        place.selectionProof.isEmpty ||
        proofExpired ||
        before == null ||
        !repository.capabilities.link) {
      return false;
    }
    return _mutate(
      () => repository.link(
        place,
        clinicId: before.clinicId,
        expectedPlaceId: before.placeId,
      ),
      expectedPlaceId: place.placeId,
    );
  }

  Future<bool> unlink() async {
    final before = association;
    if (!allowed ||
        busy ||
        needsRefresh ||
        before == null ||
        !before.linked ||
        !repository.capabilities.unlink) {
      return false;
    }
    return _mutate(
      () => repository.unlink(
        clinicId: before.clinicId,
        expectedPlaceId: before.placeId,
      ),
      expectedPlaceId: '',
    );
  }

  Future<bool> _mutate(
    Future<GoogleBusinessAssociation> Function() write, {
    required String expectedPlaceId,
  }) async {
    final g = ++_generation, clinic = association!.clinicId;
    saving = true;
    needsRefresh = true;
    error = null;
    _debounce?.cancel();
    _token = null;
    notifyListeners();
    try {
      final ack = await write();
      if (!_current(g)) return false;
      if (ack.clinicId != clinic || ack.placeId != expectedPlaceId) {
        throw StateError('Unexpected association acknowledgment');
      }
      final fresh = await repository.current();
      if (!_current(g)) return false;
      if (fresh.clinicId != clinic || fresh.placeId != expectedPlaceId) {
        throw StateError('Association not persisted');
      }
      association = fresh;
      needsRefresh = false;
      _retireProof();
      selected = null;
      confirmed = false;
      suggestions = const [];
      return true;
    } catch (e) {
      if (_current(g)) {
        error = _text(
          'The change was not verified. Refresh the association before retrying; no automatic retry was sent.',
          'لم يتم التحقق من التغيير. حدّث الارتباط قبل إعادة المحاولة؛ لم تُرسل إعادة محاولة تلقائية.',
        );
        if (e is ApiException &&
            e.errorCode == 'INVALID_OR_EXPIRED_SELECTION_PROOF') {
          _retireProof();
          selected = null;
          confirmed = false;
          error = _text(
            'The selection expired or was already used. Refresh, then search again.',
            'انتهت صلاحية الاختيار أو استُخدم مسبقاً. حدّث ثم ابحث مجدداً.',
          );
        } else if (e is ApiException &&
            (e.errorCode == 'STALE_GOOGLE_ASSOCIATION' ||
                e.statusCode == 409)) {
          error = _text(
            'The association changed elsewhere. Refresh before choosing again.',
            'تغيّر الارتباط في مكان آخر. حدّث قبل الاختيار مجدداً.',
          );
        } else if (e is ApiException && e.statusCode == 403) {
          error = _text(
            'You do not have permission to change this association. Refresh your session.',
            'لا تملك صلاحية تغيير هذا الارتباط. حدّث جلستك.',
          );
        }
      }
      return false;
    } finally {
      if (_current(g)) {
        saving = false;
        notifyListeners();
      }
    }
  }

  void cancelSelection() {
    if (!busy && allowed) {
      ++_generation;
      _debounce?.cancel();
      _token = null;
      _retireProof();
      selected = null;
      suggestions = const [];
      searching = false;
      confirmed = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _debounce?.cancel();
    _token = null;
    association = null;
    _retireProof();
    selected = null;
    AuthState().removeListener(_authChanged);
    LocaleService().removeListener(_languageChanged);
    super.dispose();
  }
}
