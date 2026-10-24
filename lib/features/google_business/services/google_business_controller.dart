import '../../locations/services/patient_location_controller.dart';
import 'dart:async';
import 'package:clock/clock.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/auth/guest_auth_guard.dart';
import '../../../core/auth/session_snapshot.dart';
import '../../../core/localization/app_locale.dart';
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
  DateTime? _tokenIssuedAt;
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
    selected = null;
    confirmed = false;
    hasSearched = false;
    suggestions = const [];
    error = null;
    searching = false;
    final query = value.trim();
    if (!repository.capabilities.search || query.length < 2) {
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
      confirmed = value && selected != null;
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
      selected = null;
      confirmed = false;
      suggestions = const [];
      return true;
    } catch (_) {
      if (_current(g)) {
        error = _text(
          'The change was not verified. Refresh the association before retrying; no automatic retry was sent.',
          'لم يتم التحقق من التغيير. حدّث الارتباط قبل إعادة المحاولة؛ لم تُرسل إعادة محاولة تلقائية.',
        );
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
    selected = null;
    AuthState().removeListener(_authChanged);
    LocaleService().removeListener(_languageChanged);
    super.dispose();
  }
}
