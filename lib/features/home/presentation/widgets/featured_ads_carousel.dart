import '../../../clinics/presentation/widgets/patient_clinic_card.dart';
import '../../../../core/theme/patient_design.dart';
import '../../data/models/home_feed_model.dart';
import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:aesthetic_way/core/widgets/viewport_activity.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import '../../../../core/widgets/content_sized_page_view.dart';
import '../../../../core/widgets/patient_media_banner.dart';
import '../../../../core/widgets/async_action_button.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

/// Top Featured / Sponsored Clinics Auto Carousel (Luxury B2B Subscription Priority)
class FeaturedAdsCarousel extends StatefulWidget {
  final List<ClinicModel> ads;
  final List<FeaturedAdApiModel?>? placements;
  final ValueChanged<ClinicModel> onClinicTap;
  final ValueChanged<ClinicModel>? onRequestAppointmentTap;
  final ValueChanged<ClinicModel> onContactTap;
  final Future<void> Function(ClinicModel, AsyncActionScope)? onRequestAction;

  const FeaturedAdsCarousel({
    super.key,
    required this.ads,
    this.placements,
    required this.onClinicTap,
    this.onRequestAppointmentTap,
    required this.onContactTap,
    this.onRequestAction,
  });

  @override
  State<FeaturedAdsCarousel> createState() => _FeaturedAdsCarouselState();
}

class _FeaturedAdsCarouselState extends State<FeaturedAdsCarousel>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;
  bool _inViewport = true;
  final Animation<double> _sheenController =
      const AlwaysStoppedAnimation<double>(0);
  bool _tabActive = true;
  bool _foreground = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: widget.ads.length == 1 ? 1 : .72,
    );
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant FeaturedAdsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.ads.length == 1) != (widget.ads.length == 1)) {
      final previous = _pageController;
      _pageController = PageController(
        viewportFraction: widget.ads.length == 1 ? 1 : .72,
      );
      _currentIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
    if (widget.ads.isNotEmpty && _currentIndex >= widget.ads.length) {
      _currentIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tabActive =
        TabActivity.isActive(context) &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _startAutoScroll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.ads.length <= 1 ||
        !_tabActive ||
        !_foreground ||
        !_inViewport ||
        _reduceMotion) {
      return;
    }

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 4000), (
      timer,
    ) {
      if (!_isUserInteracting && mounted && _pageController.hasClients) {
        final nextPage = (_currentIndex + 1) % widget.ads.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onUserTouchDown() {
    _isUserInteracting = true;
    _resumeTimer?.cancel();
  }

  void _onUserTouchUp() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();

    if (widget.ads.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = ViewportActivity(
          onChanged: (visible) {
            _inViewport = visible;
            _startAutoScroll();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        loc.isArabic ? 'عيادات مختارة' : 'Featured Clinics',
                        style: PatientDesign.heading(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (widget.ads.length > 1)
                      Text(
                        '${_currentIndex + 1} / ${widget.ads.length}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.subtext(context),
                        ),
                      ),
                  ],
                ),
              ),

              // Carousel Container with Touch Listener
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    _onUserTouchDown();
                  } else if (notification is ScrollEndNotification) {
                    _onUserTouchUp();
                  }
                  return false;
                },
                child: ContentSizedPageView(
                  controller: _pageController,
                  padEnds: false,
                  itemCount: widget.ads.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) => _FeaturedAdCard(
                    clinic: widget.ads[index],
                    mediaAspectRatio: widget.ads.length == 1 ? 2.5 : 16 / 9,
                    placement: widget.placements?[index],
                    loc: loc,
                    sheenAnimation: _sheenController,
                    isActive: _currentIndex == index,
                    onTap: () => widget.onClinicTap(widget.ads[index]),
                    onRequestTap: widget.onRequestAppointmentTap == null
                        ? null
                        : () => widget.onRequestAppointmentTap!(
                            widget.ads[index],
                          ),
                    onContactTap: () => widget.onContactTap(widget.ads[index]),
                    onRequestAction: widget.onRequestAction == null
                        ? null
                        : (action) => widget.onRequestAction!(
                            widget.ads[index],
                            action,
                          ),
                  ),
                ),
              ),
              if (widget.ads.length > 1) const SizedBox(height: 10),

              if (widget.ads.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      widget.ads.length,
                      (index) => Semantics(
                        selected: _currentIndex == index,
                        label: loc.isArabic
                            ? 'إعلان ${index + 1}'
                            : 'Partner placement ${index + 1}',
                        child: TextButton(
                          onPressed: () => _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: _currentIndex == index ? 24 : 6,
                            height: 5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentIndex == index
                                  ? AppColors.goldText(context)
                                  : AppColors.border(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
        return constraints.hasBoundedHeight
            ? SingleChildScrollView(child: content)
            : content;
      },
    );
  }
}

class _FeaturedAdCard extends StatefulWidget {
  final ClinicModel clinic;
  final double mediaAspectRatio;
  final FeaturedAdApiModel? placement;
  final LocaleService loc;
  final Animation<double> sheenAnimation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onRequestTap;
  final VoidCallback onContactTap;
  final AsyncPatientAction? onRequestAction;

  const _FeaturedAdCard({
    required this.clinic,
    required this.mediaAspectRatio,
    this.placement,
    required this.loc,
    required this.sheenAnimation,
    required this.isActive,
    required this.onTap,
    required this.onRequestTap,
    required this.onContactTap,
    this.onRequestAction,
  });

  @override
  State<_FeaturedAdCard> createState() => _FeaturedAdCardState();
}

class _FeaturedAdCardState extends State<_FeaturedAdCard> {
  String get _image => widget.placement?.image.isNotEmpty == true
      ? widget.placement!.image
      : widget.clinic.primaryPhotoUrl;
  String? get _video => widget.placement != null
      ? widget.placement!.videoUrl
      : widget.clinic.subscriptionTier == SubscriptionTier.vipPlatinum
      ? widget.clinic.videoUrl
      : null;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 4),
      child: PatientClinicCard(
        clinic: widget.clinic,
        compact: true,
        onTap: widget.onTap,
        onRequestAction: widget.onRequestAction,
        onRequest: widget.onRequestTap,
        onContact: widget.onContactTap,
        media: Stack(
          children: [
            FeaturedAdSlideMedia(
              imageUrl: _image,
              aspectRatio: widget.mediaAspectRatio,
              videoUrl: _video,
              fallbackLogoUrl: widget.clinic.logoUrl,
              isActive: widget.isActive,
            ),
            if (_video?.isNotEmpty == true)
              PositionedDirectional(
                start: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.loc.isArabic ? 'فيديو 15 ثانية' : '15s Video',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FeaturedAdSlideMedia extends StatefulWidget {
  static const Duration maxVideoDuration = Duration(seconds: 15);

  final String? imageUrl;
  final double aspectRatio;
  final String? fallbackLogoUrl;
  final String? videoUrl;
  final bool isActive;

  const FeaturedAdSlideMedia({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.fallbackLogoUrl,
    this.videoUrl,
    this.isActive = true,
  });

  @override
  State<FeaturedAdSlideMedia> createState() => _FeaturedAdSlideMediaState();
}

class _FeaturedAdSlideMediaState extends State<FeaturedAdSlideMedia>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  bool _visible = false;
  bool _tabActive = true;
  bool _foreground = true;
  bool _seeking = false;
  bool _reduceMotion = false;
  bool _requestedPlayback = false;
  bool _userPaused = false;
  bool get _canPlay =>
      mounted &&
      widget.isActive &&
      _visible &&
      _tabActive &&
      _foreground &&
      !_userPaused &&
      (!_reduceMotion || _requestedPlayback);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tabActive =
        TabActivity.isActive(context) &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant FeaturedAdSlideMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _requestedPlayback = false;
      _userPaused = false;
    }
    _syncPlayback();
  }

  void _syncPlayback() {
    if (!_canPlay) {
      if (_controller != null) {
        _disposeController();
        if (mounted) setState(() {});
      }
      return;
    }
    if (_controller == null && !_hasVideoError) {
      _initVideoIfNeeded();
    }
  }

  Future<void> _initVideoIfNeeded() async {
    final resolved = resolveNetworkImageUrl(widget.videoUrl);
    if (resolved == null || !_canPlay || _controller != null) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(resolved),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );
    setState(() => _controller = controller);
    controller.addListener(_onVideoTick);
    try {
      await controller.initialize();
      if (!mounted || !identical(_controller, controller)) return;
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (!_canPlay || !identical(_controller, controller)) return;
      await controller.play();
      if (mounted && identical(_controller, controller)) {
        setState(() {
          _isVideoInitialized = true;
          _hasVideoError = false;
        });
      }
    } catch (_) {
      if (mounted && identical(_controller, controller)) {
        _disposeController();
        setState(() => _hasVideoError = true);
      }
    }
  }

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    if (controller.value.hasError && !_hasVideoError) {
      _disposeController();
      setState(() => _hasVideoError = true);
      return;
    }
    if (_canPlay &&
        controller.value.isInitialized &&
        !_seeking &&
        controller.value.position >= FeaturedAdSlideMedia.maxVideoDuration) {
      _seeking = true;
      controller
          .seekTo(Duration.zero)
          .catchError((_) {})
          .whenComplete(() => _seeking = false);
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    _isVideoInitialized = false;
    _hasVideoError = false;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      // Stop first, then release the codec. Late initialize completions are ignored.
      unawaited(controller.pause().catchError((_) {}));
      unawaited(controller.dispose().catchError((_) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final hasVideo = resolveNetworkImageUrl(widget.videoUrl) != null;
    Widget media = PatientMediaBanner(
      source: widget.imageUrl,
      aspectRatio: widget.aspectRatio,
    );
    // A video without a poster still needs measurable bounds: otherwise the
    // visibility observer sees zero height and can never initialize playback.
    if (hasVideo) {
      media = AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppColors.surfaceSubtle(context)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_display_outlined,
                    color: AppColors.goldText(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.isArabic
                        ? 'فيديو ترويجي · 15 ثانية'
                        : 'Promotional video · 15s',
                    style: TextStyle(
                      color: AppColors.subtext(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            media,
          ],
        ),
      );
    }
    if (_isVideoInitialized && !_hasVideoError && _controller != null) {
      final size = _controller!.value.size;
      media = AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: size.width > 0 ? size.width : 16,
              height: size.height > 0 ? size.height : 9,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      );
    }
    if (hasVideo) {
      final paused = _userPaused || (_reduceMotion && !_requestedPlayback);
      final initializing = _controller != null && !_isVideoInitialized;
      final label = initializing
          ? (loc.isArabic ? 'جارٍ تحميل الفيديو' : 'Loading video')
          : _hasVideoError
          ? (loc.isArabic ? 'إعادة تشغيل الفيديو' : 'Retry video')
          : paused
          ? (loc.isArabic ? 'تشغيل الفيديو' : 'Play video')
          : (loc.isArabic ? 'إيقاف الفيديو مؤقتاً' : 'Pause video');
      media = Stack(
        children: [
          media,
          PositionedDirectional(
            end: 8,
            bottom: 8,
            child: IconButton.filled(
              tooltip: label,
              onPressed: initializing
                  ? null
                  : () {
                      setState(() {
                        if (_hasVideoError) {
                          _hasVideoError = false;
                          _userPaused = false;
                        } else {
                          _userPaused = !paused;
                        }
                        _requestedPlayback = true;
                      });
                      _syncPlayback();
                    },
              icon: initializing
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: label,
                      ),
                    )
                  : Icon(
                      _hasVideoError
                          ? Icons.refresh
                          : paused
                          ? Icons.play_arrow
                          : Icons.pause,
                    ),
            ),
          ),
        ],
      );
    }
    return ViewportActivity(
      onChanged: (visible) {
        _visible = visible;
        _syncPlayback();
      },
      child: media,
    );
  }
}
