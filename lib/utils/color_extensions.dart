import 'package:flutter/material.dart';

/// Small extension to provide a `withValues` replacement for the
/// deprecated `withOpacity` usage. This keeps precision by building
/// a new color from the existing RGB channels and the provided opacity.
extension ColorWithValues on Color {
  /// Returns a new [Color] with the same RGB channels and the given
  /// [opacity] (0.0 - 1.0).
  Color withValues(double opacity) {
    return Color.fromRGBO(red, green, blue, opacity);
  }
}
