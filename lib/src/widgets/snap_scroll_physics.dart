import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Custom scroll physics that snaps to specific offsets when scrolling ends.
///
/// This provides a clean, Flutter-idiomatic way to implement snap behavior
/// without manual animation controllers or scroll listeners.
class SnapScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that snaps to the nearest snap point.
  ///
  /// [snapOffsets] - List of scroll offsets to snap to
  /// [snapThreshold] - The opacity/progress threshold (0.0-1.0) to determine snap direction
  const SnapScrollPhysics({
    required this.snapOffsets,
    this.snapThreshold = 0.5,
    super.parent,
  });

  /// The list of offsets to snap to [snapStart, snapEnd]
  final List<double> snapOffsets;

  /// Threshold for determining snap direction (default 0.5 = 50%)
  final double snapThreshold;

  @override
  SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnapScrollPhysics(
      snapOffsets: snapOffsets,
      snapThreshold: snapThreshold,
      parent: buildParent(ancestor),
    );
  }

  double _getTargetPixels(double currentOffset) {
    // If we have exactly 2 snap points (start and end of fade zone)
    if (snapOffsets.length == 2) {
      final snapStart = snapOffsets[0];
      final snapEnd = snapOffsets[1];

      // If we're outside the snap zone, don't snap
      if (currentOffset <= snapStart) {
        return currentOffset;
      }
      if (currentOffset >= snapEnd) {
        return currentOffset;
      }

      // We're in the snap zone - calculate which snap point to use
      final fadeDuration = snapEnd - snapStart;
      final progress = ((currentOffset - snapStart) / fadeDuration).clamp(0.0, 1.0);

      // Snap based on threshold
      if (progress > snapThreshold) {
        return snapEnd;
      } else {
        return snapStart;
      }
    }

    // Fallback: find nearest snap point
    double nearestSnap = snapOffsets.first;
    double minDistance = (currentOffset - nearestSnap).abs();

    for (final snapOffset in snapOffsets.skip(1)) {
      final distance = (currentOffset - snapOffset).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestSnap = snapOffset;
      }
    }

    return nearestSnap;
  }

  bool _isInSnapZone(double offset) {
    if (snapOffsets.length < 2) return false;
    final snapStart = snapOffsets[0];
    final snapEnd = snapOffsets[snapOffsets.length - 1];
    return offset > snapStart && offset < snapEnd;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Check if we're in the snap zone
    if (!_isInSnapZone(position.pixels)) {
      // Outside snap zone - use parent physics
      return super.createBallisticSimulation(position, velocity);
    }

    // We're in the snap zone - determine target
    final target = _getTargetPixels(position.pixels);

    // If we're already very close to target, let it settle naturally
    if ((target - position.pixels).abs() < tolerance.distance) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Create snap simulation - completely override parent physics
    // Key: We don't call super here, so no competing simulations
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.5,
        stiffness: 100.0,
        damping: 15.0,
      );
}
