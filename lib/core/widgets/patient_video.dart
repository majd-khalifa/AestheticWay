import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../auth/guest_auth_guard.dart';
import '../auth/session_snapshot.dart';
import '../localization/app_locale.dart';
import 'lazy_tab_stack.dart';
import 'luxury_image.dart';
import 'patient_media_banner.dart';
import 'viewport_activity.dart';

enum PatientVideoPhase {
  poster,
  initializing,
  buffering,
  playing,
  paused,
  completed,
  failed,
  inactive,
}

/// Public, lazy media only. A phase is an observation, never a save receipt.
class PatientVideo extends StatefulWidget {
  const PatientVideo({
    super.key,
    required this.videoUrl,
    this.posterUrl,
    this.autoplay = false,
    this.isActive = true,
    this.aspectRatio = 16 / 9,
    this.onPhase,
    this.allowFullscreen = true,
    this.fullscreen = false,
  });
  final String videoUrl;
  final String? posterUrl;
  final bool autoplay, isActive, allowFullscreen, fullscreen;
  final double aspectRatio;
  final ValueChanged<PatientVideoPhase>? onPhase;
  static const maximum = Duration(seconds: 15);
  static String? publicUrl(String? value) {
    final resolved = resolveNetworkImageUrl(value);
    final uri = Uri.tryParse(resolved ?? '');
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !['https', 'http'].contains(uri.scheme) ||
        RegExp(
          r'\.(png|jpe?g|webp|gif|svg)$',
          caseSensitive: false,
        ).hasMatch(uri.path)) {
      return null;
    }
    return resolved;
  }

  @override
  State<PatientVideo> createState() => _PatientVideoState();
}

class _PatientVideoState extends State<PatientVideo>
    with WidgetsBindingObserver {
  final _session = SessionSnapshot();
  VideoPlayerController? _player;
  Timer? _initializationDeadline;
  PatientVideoPhase _phase = PatientVideoPhase.poster;
  bool _visible = false, _routeActive = true, _foreground = true;
  bool _reduced = false, _requested = false, _paused = false;
  bool _completed = false, _failed = false, _muted = true, _opening = false;
  bool _controlling = false;
  bool get _present =>
      mounted &&
      widget.isActive &&
      _visible &&
      _routeActive &&
      _foreground &&
      _session.isCurrent;
  bool get _wantsPlay =>
      _present &&
      !_paused &&
      !_completed &&
      !_failed &&
      (_requested || (widget.autoplay && !_reduced));
  String t(String en, String ar) => LocaleService().isArabic ? ar : en;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthState().addListener(_identityChanged);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void _identityChanged() => _sync();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeActive =
        TabActivity.isActive(context) &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _reduced = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void didUpdateWidget(covariant PatientVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _release();
      _requested = false;
      _paused = false;
      _completed = false;
      _failed = false;
    }
    _sync();
  }

  void _emit(PatientVideoPhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    // A dependency/visibility edge can occur during another widget's build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _phase == phase) widget.onPhase?.call(phase);
    });
  }

  void _sync() {
    if (!_present) {
      _release();
      _emit(PatientVideoPhase.inactive);
      if (mounted) setState(() {});
      return;
    }
    if (_paused) {
      _emit(PatientVideoPhase.paused);
      return;
    }
    if (_completed) {
      _emit(PatientVideoPhase.completed);
      return;
    }
    if (_failed) {
      _emit(PatientVideoPhase.failed);
      return;
    }
    if (_wantsPlay && _player == null) {
      unawaited(_initialize());
    } else if (!_wantsPlay && _player != null && _player!.value.isPlaying) {
      unawaited(_player!.pause().catchError((_) {}));
    }
  }

  Future<void> _initialize() async {
    final url = PatientVideo.publicUrl(widget.videoUrl);
    if (url == null || !_wantsPlay || _player != null) return;
    final p = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );
    _player = p;
    p.addListener(_tick);
    _emit(PatientVideoPhase.initializing);
    if (mounted) setState(() {});
    _initializationDeadline?.cancel();
    _initializationDeadline = Timer(const Duration(seconds: 20), () {
      if (mounted && identical(p, _player)) {
        _failed = true;
        _release();
        _emit(PatientVideoPhase.failed);
        setState(() {});
      }
    });
    try {
      await p.initialize();
      if (!mounted || !identical(p, _player)) return;
      _initializationDeadline?.cancel();
      await p.setLooping(false);
      await p.setVolume(_muted ? 0 : 1);
      if (!_wantsPlay || !identical(p, _player)) return;
      await p.play();
      if (mounted && identical(p, _player)) setState(() {});
    } catch (_) {
      if (mounted && identical(p, _player)) {
        _failed = true;
        _release();
        _emit(PatientVideoPhase.failed);
        setState(() {});
      }
    }
  }

  void _tick() {
    final p = _player;
    if (!mounted || p == null) return;
    final value = p.value;
    if (value.hasError) {
      _failed = true;
      _release();
      _emit(PatientVideoPhase.failed);
    } else if (!_completed &&
        value.isInitialized &&
        (value.isCompleted ||
            value.position >= PatientVideo.maximum ||
            (value.duration > Duration.zero &&
                value.position >= value.duration))) {
      _completed = true;
      unawaited(p.pause().catchError((_) {}));
      _emit(PatientVideoPhase.completed);
    } else if (_completed) {
      _emit(PatientVideoPhase.completed);
    } else if (_paused) {
      _emit(PatientVideoPhase.paused);
    } else if (!value.isInitialized) {
      _emit(PatientVideoPhase.initializing);
    } else if (value.isBuffering) {
      _emit(PatientVideoPhase.buffering);
    } else if (value.isPlaying) {
      _emit(PatientVideoPhase.playing);
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (!_present || _controlling) return;
    final p = _player;
    _controlling = true;
    try {
      if (p != null && !_paused && !_completed && !_failed) {
        _paused = true;
        _emit(PatientVideoPhase.paused);
        setState(() {});
        await p.pause();
      } else {
        _requested = true;
        _paused = false;
        _failed = false;
        final replay = _completed;
        _completed = false;
        setState(() {});
        if (p?.value.isInitialized == true) {
          if (replay) await p!.seekTo(Duration.zero);
          if (!mounted || !identical(p, _player) || !_wantsPlay) return;
          await p!.play();
        } else {
          // A pause during initialization keeps the selected slide stationary.
          if (p != null) _release();
          _sync();
        }
      }
    } catch (_) {
      _controlFailed(p);
    } finally {
      _controlling = false;
      if (mounted) setState(() {});
    }
  }

  void _controlFailed(VideoPlayerController? player) {
    if (!mounted || player == null || !identical(player, _player)) return;
    _failed = true;
    _paused = false;
    _release();
    _emit(PatientVideoPhase.failed);
    setState(() {});
  }

  Future<void> _volume() async {
    final p = _player;
    setState(() => _muted = !_muted);
    try {
      await p?.setVolume(_muted ? 0 : 1);
    } catch (_) {
      _controlFailed(p);
    }
  }

  Future<void> _fullscreen() async {
    if (_opening || !_present) return;
    _opening = true;
    _paused = true;
    _emit(PatientVideoPhase.paused);
    _release();
    setState(() {});
    try {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(title: Text(t('Clinic video', 'فيديو العيادة'))),
            body: SafeArea(
              child: Center(
                child: PatientVideo(
                  videoUrl: widget.videoUrl,
                  posterUrl: widget.posterUrl,
                  autoplay: true,
                  allowFullscreen: false,
                  fullscreen: true,
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _release() {
    _initializationDeadline?.cancel();
    _initializationDeadline = null;
    final p = _player;
    _player = null;
    if (p == null) return;
    p.removeListener(_tick);
    unawaited(p.pause().catchError((_) {}));
    unawaited(p.dispose().catchError((_) {}));
  }

  @override
  void dispose() {
    AuthState().removeListener(_identityChanged);
    WidgetsBinding.instance.removeObserver(this);
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _player;
    final initialized =
        p?.value.isInitialized == true &&
        p!.value.size.width > 0 &&
        p.value.size.height > 0;
    final waiting =
        !_paused &&
        !_completed &&
        (_phase == PatientVideoPhase.initializing ||
            _phase == PatientVideoPhase.buffering) &&
        p != null;
    final stopped = _paused || _completed || p == null;
    final label = _failed
        ? t('Retry video', 'إعادة تشغيل الفيديو')
        : stopped
        ? t('Play video', 'تشغيل الفيديو')
        : t('Pause video', 'إيقاف الفيديو مؤقتاً');
    final ratio = widget.fullscreen && initialized
        ? p.value.aspectRatio
        : widget.aspectRatio;
    return ViewportActivity(
      onChanged: (visible) {
        _visible = visible;
        _sync();
      },
      child: AspectRatio(
        aspectRatio: ratio > 0 && ratio.isFinite ? ratio : 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (initialized)
                ColoredBox(
                  color: Colors.black,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: p.value.size.width,
                      height: p.value.size.height,
                      child: VideoPlayer(p),
                    ),
                  ),
                )
              else
                PatientMediaBanner(
                  category: PatientMediaCategory.clinicCover,
                  source: widget.posterUrl,
                  aspectRatio: widget.aspectRatio,
                ),
              if (waiting)
                Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: t('Loading video', 'جارٍ تحميل الفيديو'),
                  ),
                ),
              if (_failed)
                Align(
                  alignment: Alignment.topCenter,
                  child: Material(
                    color: Colors.black87,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        t(
                          'Video could not load. You can retry.',
                          'تعذر تحميل الفيديو. يمكنك المحاولة مجدداً.',
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.black.withValues(alpha: .72),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _controlling ? null : _toggle,
                        tooltip: label,
                        icon: Icon(
                          _failed
                              ? Icons.refresh
                              : stopped
                              ? Icons.play_arrow
                              : Icons.pause,
                          color: Colors.white,
                        ),
                      ),
                      if (initialized)
                        Expanded(
                          child: VideoProgressIndicator(
                            p,
                            allowScrubbing: false,
                            colors: const VideoProgressColors(
                              playedColor: Color(0xFFD4B885),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      IconButton(
                        tooltip: _muted
                            ? t('Unmute video', 'تشغيل صوت الفيديو')
                            : t('Mute video', 'كتم صوت الفيديو'),
                        onPressed: _volume,
                        icon: Icon(
                          _muted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.allowFullscreen)
                        IconButton(
                          onPressed: _opening ? null : _fullscreen,
                          tooltip: t('Full screen', 'ملء الشاشة'),
                          icon: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
