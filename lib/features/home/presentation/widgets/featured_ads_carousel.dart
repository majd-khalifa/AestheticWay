import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:aesthetic_way/core/widgets/viewport_activity.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/rating_chip.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';

/// Top Featured / Sponsored Clinics Auto Carousel (Luxury B2B Subscription Priority)
class FeaturedAdsCarousel extends StatefulWidget {
  final List<ClinicModel> ads;
  final ValueChanged<ClinicModel> onClinicTap;
  final ValueChanged<ClinicModel> onRequestAppointmentTap;
  final ValueChanged<ClinicModel> onContactTap;

  const FeaturedAdsCarousel({
    super.key,
    required this.ads,
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
    final isDark = AppColors.isDark(context);

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.accentChampagne.withValues(
                          alpha: isDark ? 0.12 : 0.18,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentChampagne.withValues(
                            alpha: 0.4,
                          ),
                          width: 0.7,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 15,
                        color: AppColors.accentChampagne,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.tr('featured_partners'),
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.silverPrimary
                            : AppColors.lightTextPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                // Slide indicator pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardSurfaceHover
                        : AppColors.lightCardSurfaceHover,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border(context),
                      width: 0.7,
                    ),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.ads.length}',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.silverSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
            child: SizedBox(
              height: 268,
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

          // Animated Expanding Dots Indicator
          if (widget.ads.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.ads.length, (index) {
                final isSelected = _currentIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 24 : 6,
                  height: 4.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isSelected
                        ? AppColors.accentChampagne
                        : (isDark
                              ? AppColors.silverBorder.withValues(alpha: 0.25)
                              : AppColors.lightBorder),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accentChampagne.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _FeaturedAdCard extends StatefulWidget {
  final ClinicModel clinic;
  final LocaleService loc;
  final Animation<double> sheenAnimation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRequestTap;
  final VoidCallback onContactTap;

  const _FeaturedAdCard({
    required this.clinic,
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
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final clinic = widget.clinic;
    final loc = widget.loc;
    final isDark = AppColors.isDark(context);
    final isVip = clinic.subscriptionTier == SubscriptionTier.vipPlatinum;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isVip
                  ? AppColors.accentChampagne.withValues(
                      alpha: isDark ? 0.6 : 0.8,
                    )
                  : (isDark
                        ? AppColors.silverBorder.withValues(alpha: 0.22)
                        : AppColors.lightBorder),
              width: isVip ? 1.0 : 0.8,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isPressed ? 0.28 : 0.48,
                      ),
                      blurRadius: _isPressed ? 10 : 22,
                      offset: Offset(0, _isPressed ? 3 : 8),
                      spreadRadius: _isPressed ? -3 : -1,
                    ),
                    if (isVip)
                      BoxShadow(
                        color: AppColors.accentChampagne.withValues(
                          alpha: 0.16,
                        ),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(
                        0xFF0F172A,
                      ).withValues(alpha: _isPressed ? 0.05 : 0.09),
                      blurRadius: _isPressed ? 8 : 18,
                      offset: Offset(0, _isPressed ? 2 : 6),
                      spreadRadius: _isPressed ? -2 : 0,
                    ),
                    if (isVip)
                      BoxShadow(
                        color: AppColors.accentChampagne.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17.2),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Cinematic Image / Short Video Area (up to 15s muted) with Minimal Info & Badges
                    Expanded(
                      flex: 14,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FeaturedAdSlideMedia(
                            imageUrl: clinic.coverImageUrl,
                            fallbackLogoUrl: clinic.logoUrl,
                            videoUrl: clinic.hasVideoAd
                                ? clinic.videoUrl
                                : null,
                            isActive: widget.isActive,
                          ),
                          // Deep 3-Stop Gradient for Maximum Typography Readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.transparent,
                                  const Color(
                                    0xFF050811,
                                  ).withValues(alpha: 0.96),
                                ],
                                stops: const [0.0, 0.38, 1.0],
                              ),
                            ),
                          ),
                          // Top Rating Badge on left/right according to RTL
                          Positioned(
                            top: 10,
                            left: 10,
                            child: RatingChip(
                              rating: clinic.rating,
                              reviewCount: clinic.reviewCount,
                              isCompact: true,
                              showGoogleSource: true,
                            ),
                          ),
                          // Muted Video Badge when clinic slide has a short video ad
                          if (clinic.hasVideoAd)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                key: const Key('featured_ad_video_badge'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.accentChampagne.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 0.7,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.videocam_outlined,
                                      size: 12,
                                      color: AppColors.accentChampagne,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.volume_off_rounded,
                                      size: 11,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      loc.isArabic ? 'فيديو 15ث' : '15s Video',
                                      style: AppTypography.badge.copyWith(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Bottom Meta inside Image
                          Positioned(
                            bottom: 8,
                            right: 14,
                            left: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.isArabic ? clinic.nameAr : clinic.nameEn,
                                  style: AppTypography.heroTitle.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16.5,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if ((loc.isArabic
                                        ? clinic.areaAr
                                        : clinic.areaEn)
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: AppColors.accentChampagne,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          loc.isArabic
                                              ? clinic.areaAr
                                              : clinic.areaEn,
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Action Bar: Telegram-style Single Primary + Secondary Contact Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardSurfaceSubtle
                            : AppColors.lightCardSurfaceSubtle,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.border(context),
                            width: 0.75,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Secondary Outline Contact Button
                          IconButton(
                            onPressed: widget.onContactTap,
                            icon: Icon(
                              Icons.headset_mic_outlined,
                              size: 18,
                              color: isDark
                                  ? AppColors.silverSecondary
                                  : AppColors.lightTextPrimary,
                            ),
                            tooltip: loc.tr('contact_btn'),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppColors.cardSurfaceHover
                                  : AppColors.lightCardSurfaceHover,
                              padding: const EdgeInsets.all(8),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.border(context),
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Primary Solid Telegram-style Button
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: widget.onRequestTap,
                                icon: Icon(
                                  Icons.calendar_month_outlined,
                                  size: 15,
                                  color: isDark
                                      ? AppColors.backgroundDeep
                                      : Colors.white,
                                ),
                                label: Text(
                                  loc.tr('request_appointment'),
                                  style: AppTypography.button.copyWith(
                                    color: isDark
                                        ? AppColors.backgroundDeep
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? AppColors.silverPrimary
                                      : AppColors.lightTextPrimary,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Subtle Luxury Sheen sweeping over active card
                if (widget.isActive)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: widget.sheenAnimation,
                        builder: (context, _) {
                          final value = widget.sheenAnimation.value;
                          return FractionallySizedBox(
                            alignment: Alignment(-2.0 + (value * 4.0), 0.0),
                            widthFactor: 0.4,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    (isVip
                                            ? AppColors.accentChampagne
                                            : AppColors.silverPrimary)
                                        .withValues(alpha: 0.07),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Media renderer for VIP / Featured Ad slides:
/// - If [videoUrl] is null or empty: renders [LuxuryImage] (existing behavior).
/// - If [videoUrl] is present: initializes muted [VideoPlayerController], loops within 15 seconds,
///   and gracefully falls back to [LuxuryImage] (cover image or luxury placeholder) if video initialization or playback fails.
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
