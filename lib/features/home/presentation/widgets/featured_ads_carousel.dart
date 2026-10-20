import '../../data/models/home_feed_model.dart';
import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:aesthetic_way/core/widgets/viewport_activity.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import '../../../clinics/presentation/widgets/patient_clinic_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

/// Top Featured / Sponsored Clinics Auto Carousel (Luxury B2B Subscription Priority)
class FeaturedAdsCarousel extends StatefulWidget {
  final List<ClinicModel> ads;
  final List<FeaturedAdApiModel>? placements;
  final ValueChanged<ClinicModel> onClinicTap;
  final ValueChanged<ClinicModel> onRequestAppointmentTap;
  final ValueChanged<ClinicModel> onContactTap;

  const FeaturedAdsCarousel({
    super.key,
    required this.ads,
    this.placements,
    required this.onClinicTap,
    required this.onRequestAppointmentTap,
    required this.onContactTap,
  });

  @override
  State<FeaturedAdsCarousel> createState() => _FeaturedAdsCarouselState();
}

class _FeaturedAdsCarouselState extends State<FeaturedAdsCarousel>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;
  bool _inViewport = true;
  final Animation<double> _sheenController =
      const AlwaysStoppedAnimation<double>(0);
  bool _tabActive = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    if (widget.ads.length <= 1 || !_tabActive || !_foreground || !_inViewport) {
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

    return ViewportActivity(
      onChanged: (visible) {
        _inViewport = visible;
        _startAutoScroll();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  loc.tr('featured_partners'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${_currentIndex + 1} / ${widget.ads.length}',
                  style: TextStyle(color: AppColors.subtext(context)),
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
            child: SizedBox(
              height:
                  ((widget.placements?.any(
                            (ad) =>
                                ad.image.isNotEmpty || ad.videoUrl.isNotEmpty,
                          ) ??
                          widget.ads.any(
                            (c) => c.coverImageUrl.isNotEmpty || c.hasVideoAd,
                          ))
                      ? 360.0
                      : 228.0) *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.ads.length,
                onPageChanged: (idx) {
                  setState(() {
                    _currentIndex = idx;
                  });
                },
                itemBuilder: (context, index) {
                  final clinic = widget.ads[index];
                  return _FeaturedAdCard(
                    clinic: clinic,
                    placement: widget.placements?[index],
                    loc: loc,
                    sheenAnimation: _sheenController,
                    isActive: _currentIndex == index,
                    onTap: () => widget.onClinicTap(clinic),
                    onRequestTap: () => widget.onRequestAppointmentTap(clinic),
                    onContactTap: () => widget.onContactTap(clinic),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

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
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: _currentIndex == index
                              ? AppColors.goldText(context)
                              : AppColors.subtext(context),
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
  }
}

class _FeaturedAdCard extends StatefulWidget {
  final ClinicModel clinic;
  final FeaturedAdApiModel? placement;
  final LocaleService loc;
  final Animation<double> sheenAnimation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRequestTap;
  final VoidCallback onContactTap;

  const _FeaturedAdCard({
    required this.clinic,
    this.placement,
    required this.loc,
    required this.sheenAnimation,
    required this.isActive,
    required this.onTap,
    required this.onRequestTap,
    required this.onContactTap,
  });

  @override
  State<_FeaturedAdCard> createState() => _FeaturedAdCardState();
}

class _FeaturedAdCardState extends State<_FeaturedAdCard> {
  String get _image => widget.placement?.image ?? widget.clinic.coverImageUrl;
  String? get _video => widget.placement?.videoUrl ?? widget.clinic.videoUrl;
  bool get _hasVideo => _video?.isNotEmpty == true;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_image.isNotEmpty || _hasVideo)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 132,
                child: FeaturedAdSlideMedia(
                  imageUrl: _image,
                  fallbackLogoUrl: widget.clinic.logoUrl,
                  videoUrl: _video,
                  isActive: widget.isActive,
                ),
              ),
            ),
          if (_hasVideo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                widget.loc.isArabic ? 'فيديو 15 ثانية' : '15s Video',
                style: TextStyle(color: AppColors.subtext(context)),
              ),
            ),
          if (widget.placement != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.loc.isArabic ? 'إعلان شريك' : 'Sponsored partner',
                style: TextStyle(color: AppColors.goldText(context)),
              ),
            ),
          PatientClinicCard(
            clinic: widget.clinic,
            showCover: false,
            onTap: widget.onTap,
            onRequest: widget.onRequestTap,
            onContact: widget.onContactTap,
          ),
        ],
      ),
    ),
  );
}

class FeaturedAdSlideMedia extends StatefulWidget {
  static const Duration maxVideoDuration = Duration(seconds: 15);

  final String? imageUrl;
  final String? fallbackLogoUrl;
  final String? videoUrl;
  final bool isActive;

  const FeaturedAdSlideMedia({
    super.key,
    required this.imageUrl,
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
  bool get _canPlay =>
      mounted && widget.isActive && _visible && _tabActive && _foreground;

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
    if (oldWidget.videoUrl != widget.videoUrl) _disposeController();
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
    _controller = controller;
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
    Widget media = LuxuryImage(
      imageUrl: widget.imageUrl,
      fallbackLogoUrl: widget.fallbackLogoUrl,
      fit: BoxFit.cover,
      placeholderIcon: Icons.local_hospital_outlined,
      iconSize: 42,
    );
    if (_isVideoInitialized && !_hasVideoError && _controller != null) {
      final size = _controller!.value.size;
      media = ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.width > 0 ? size.width : 16,
            height: size.height > 0 ? size.height : 9,
            child: VideoPlayer(_controller!),
          ),
        ),
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
