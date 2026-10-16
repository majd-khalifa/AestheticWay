import 'package:flutter/material.dart';

/// Deprecated DistanceChip: GPS distance (`0.0 km`) is strictly hidden per client specification.
class DistanceChip extends StatelessWidget {
  final double distanceKm;
  final String? areaName;

  const DistanceChip({
    super.key,
    required this.distanceKm,
    this.areaName,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
