import '../../../clinics/presentation/widgets/patient_clinic_card.dart';
import '../../../../core/theme/patient_design.dart';
import '../../data/models/home_feed_model.dart';
import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:aesthetic_way/core/widgets/viewport_activity.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import '../../../../core/widgets/content_sized_page_view.dart';
import '../../../../core/widgets/patient_media_banner.dart';
import '../../../../core/widgets/async_action_button.dart';
import 'package:aesthetic_way/core/widgets/patient_video.dart';
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
  PatientVideoPhase _videoPhase = PatientVideoPhase.poster;
  bool _advancing = false;

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
    String? signature(FeaturedAdsCarousel value) {
      if (_currentIndex >= value.ads.length) return null;
      final c = value.ads[_currentIndex];
      final placement = _currentIndex < (value.placements?.length ?? 0)
          ? value.placements![_currentIndex]
          : null;
      return '${c.id}:${placement?.videoUrl ?? c.videoUrl}:${c.subscriptionTier}';
    }

    if (signature(oldWidget) != signature(widget)) {
      _videoPhase = PatientVideoPhase.poster;
    }
    if ((oldWidget.ads.length == 1) != (widget.ads.length == 1)) {
      final previous = _pageController;
      _pageController = PageController(
        viewportFraction: widget.ads.length == 1 ? 1 : .72,
      );
      _currentIndex = 0;
      _advancing = false;
      _videoPhase = PatientVideoPhase.poster;
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
        _reduceMotion ||
        _isUserInteracting ||
        _advancing ||
        const {
          PatientVideoPhase.initializing,
          PatientVideoPhase.buffering,
          PatientVideoPhase.playing,
          PatientVideoPhase.paused,
        }.contains(_videoPhase)) {
      return;
    }

    _autoScrollTimer = Timer(const Duration(seconds: 4), _advance);
  }

  Future<void> _advance() async {
    if (!mounted ||
        widget.ads.length < 2 ||
        _advancing ||
        _isUserInteracting ||
        !_tabActive ||
        !_foreground ||
        !_inViewport ||
        _reduceMotion ||
        !_pageController.hasClients) {
      return;
    }
    _autoScrollTimer?.cancel();
    final controller = _pageController;
    _advancing = true;
    try {
      await controller.animateToPage(
        (_currentIndex + 1) % widget.ads.length,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      if (mounted && identical(controller, _pageController)) {
        _advancing = false;
        _startAutoScroll();
      }
    }
  }

  void _videoChanged(int index, String clinicId, PatientVideoPhase phase) {
    if (!mounted ||
        index != _currentIndex ||
        index >= widget.ads.length ||
        widget.ads[index].id != clinicId) {
      return;
    }
    _videoPhase = phase;
    _autoScrollTimer?.cancel();
    if (phase == PatientVideoPhase.completed) {
      // Completion advances exactly once. Reduced motion/manual interaction
      // retains the slide; no independent video or competing scroll timer.
      if (!_isUserInteracting) unawaited(_advance());
    } else {
      _startAutoScroll();
    }
  }

  void _pageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _videoPhase = PatientVideoPhase.poster;
    });
    _startAutoScroll();
  }

  void _onUserTouchDown() {
    _isUserInteracting = true;
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
  }

  void _onUserTouchUp() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
        _startAutoScroll();
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
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _onUserTouchDown();
                  } else if (notification is ScrollEndNotification &&
                      _isUserInteracting) {
                    _onUserTouchUp();
                  }
                  return false;
                },
                child: ContentSizedPageView(
                  controller: _pageController,
                  padEnds: false,
                  itemCount: widget.ads.length,
                  onPageChanged: _pageChanged,
                  itemBuilder: (context, index) => _FeaturedAdCard(
                    clinic: widget.ads[index],
                    mediaAspectRatio: widget.ads.length == 1 ? 2.5 : 16 / 9,
                    placement: index < (widget.placements?.length ?? 0)
                        ? widget.placements![index]
                        : null,
                    onVideoPhase: (phase) =>
                        _videoChanged(index, widget.ads[index].id, phase),
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
  final ValueChanged<PatientVideoPhase> onVideoPhase;

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
    required this.onVideoPhase,
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
              onPhase: widget.onVideoPhase,
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
                    widget.loc.isArabic ? 'فيديو العيادة' : 'Clinic video',
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

class FeaturedAdSlideMedia extends StatelessWidget {
  static const Duration maxVideoDuration = PatientVideo.maximum;
  const FeaturedAdSlideMedia({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.fallbackLogoUrl,
    this.videoUrl,
    this.isActive = true,
    this.onPhase,
  });
  final String? imageUrl, fallbackLogoUrl, videoUrl;
  final double aspectRatio;
  final bool isActive;
  final ValueChanged<PatientVideoPhase>? onPhase;
  @override
  Widget build(BuildContext context) => PatientVideo.publicUrl(videoUrl) == null
      ? PatientMediaBanner(
          category: PatientMediaCategory.clinicCover,
          source: imageUrl,
          aspectRatio: aspectRatio,
        )
      : PatientVideo(
          videoUrl: videoUrl!,
          posterUrl: imageUrl,
          autoplay: true,
          isActive: isActive,
          aspectRatio: aspectRatio,
          allowFullscreen: false,
          onPhase: onPhase,
        );
}
