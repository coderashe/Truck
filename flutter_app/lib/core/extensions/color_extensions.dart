import 'dart:ui';

/// Compatibility extension for Flutter 3.24 to support withValues (introduced in 3.27)
extension ColorValuesCompat on Color {
  /// Creates a copy of this color with the given values replaced.
  /// For Flutter 3.24 compatibility, we only support alpha (opacity) changes.
  Color withValues({double? alpha, double? red, double? green, double? blue}) {
    if (red != null || green != null || blue != null) {
      // Full RGBA support for newer code
      return Color.fromRGBO(
        red != null ? (red * 255).round() : this.red,
        green != null ? (green * 255).round() : this.green,
        blue != null ? (blue * 255).round() : this.blue,
        alpha ?? opacity,
      );
    }
    // Simple opacity change (most common use case)
    return withOpacity(alpha ?? opacity);
  }
}
