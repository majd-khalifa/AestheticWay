import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/patient_media_banner.dart';

/// Only real record photographs. The count and thumbnails describe this list.
class PatientClinicGallery extends StatefulWidget {
  const PatientClinicGallery({super.key, required this.images});
  final List<String> images;
  @override
  State<PatientClinicGallery> createState() => _PatientClinicGalleryState();
}

class _PatientClinicGalleryState extends State<PatientClinicGallery> {
  int _index = 0;
  @override
  void didUpdateWidget(covariant PatientClinicGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.images.length) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
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
                  if (velocity.abs() < 100 || widget.images.length < 2) return;
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  final next = ((velocity < 0) != rtl) ? 1 : -1;
                  setState(
                    () => _index = (_index + next) % widget.images.length,
                  );
                },
                child: PatientMediaBanner(
                  category: PatientMediaCategory.clinicCover,
                  source: widget.images[_index],
                  aspectRatio: 16 / 9,
                ),
              ),
              if (widget.images.length > 1)
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
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Semantics(
                  selected: i == _index,
                  button: true,
                  label: LocaleService().isArabic
                      ? 'صورة ${i + 1}'
                      : 'Photo ${i + 1}',
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Container(
                      width: 86,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: i == _index
                              ? AppColors.goldText(context)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: PatientMediaBanner(
                        category: PatientMediaCategory.clinicCover,
                        source: widget.images[i],
                        height: 54,
                        borderRadius: BorderRadius.circular(7),
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
