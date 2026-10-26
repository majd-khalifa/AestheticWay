import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/patient_media_banner.dart';
import '../../../../core/widgets/patient_video.dart';

/// Only real record photographs. The count and thumbnails describe this list.
class PatientClinicGallery extends StatefulWidget {
  const PatientClinicGallery({super.key, required this.images, this.videoUrl});
  final List<String> images;
  final String? videoUrl;
  @override
  State<PatientClinicGallery> createState() => _PatientClinicGalleryState();
}

class _PatientClinicGalleryState extends State<PatientClinicGallery> {
  int _index = 0;
  bool _showVideo = false;
  bool get _hasVideo => PatientVideo.publicUrl(widget.videoUrl) != null;
  int get _count => widget.images.length + (_hasVideo ? 1 : 0);
  @override
  void initState() {
    super.initState();
    _showVideo = _hasVideo;
  }

  void _select(int position) => setState(() {
    _showVideo = _hasVideo && position == 0;
    if (!_showVideo) _index = position - (_hasVideo ? 1 : 0);
  });
  @override
  void didUpdateWidget(covariant PatientClinicGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) _showVideo = _hasVideo;
    if (_index >= widget.images.length) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty && !_hasVideo) {
      return const PatientMediaBanner(
        category: PatientMediaCategory.clinicCover,
        source: null,
        aspectRatio: 16 / 9,
        borderRadius: BorderRadius.all(Radius.circular(18)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() < 100 || _count < 2) return;
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  final next = ((velocity < 0) != rtl) ? 1 : -1;
                  final position = _showVideo
                      ? 0
                      : _index + (_hasVideo ? 1 : 0);
                  _select((position + next) % _count);
                },
                child: _showVideo
                    ? PatientVideo(
                        key: const ValueKey('public-clinic-video'),
                        videoUrl: widget.videoUrl!,
                        posterUrl: widget.images.firstOrNull,
                      )
                    : PatientMediaBanner(
                        category: PatientMediaCategory.clinicCover,
                        source: widget.images[_index],
                        aspectRatio: 16 / 9,
                      ),
              ),
              if (!_showVideo && widget.images.length > 1)
                PositionedDirectional(
                  end: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_index + 1}/${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_count > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _count,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Semantics(
                  selected: _showVideo
                      ? i == 0
                      : i == _index + (_hasVideo ? 1 : 0),
                  button: true,
                  label: _hasVideo && i == 0
                      ? (LocaleService().isArabic
                            ? 'فيديو العيادة'
                            : 'Clinic video')
                      : (LocaleService().isArabic
                            ? 'صورة ${i + 1 - (_hasVideo ? 1 : 0)}'
                            : 'Photo ${i + 1 - (_hasVideo ? 1 : 0)}'),
                  child: InkWell(
                    onTap: () => _select(i),
                    child: Container(
                      width: 86,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              (_showVideo
                                  ? i == 0
                                  : i == _index + (_hasVideo ? 1 : 0))
                              ? AppColors.goldText(context)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PatientMediaBanner(
                            category: PatientMediaCategory.clinicCover,
                            source: _hasVideo && i == 0
                                ? widget.images.firstOrNull
                                : widget.images[i - (_hasVideo ? 1 : 0)],
                            height: 54,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          if (_hasVideo && i == 0)
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 6)],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
