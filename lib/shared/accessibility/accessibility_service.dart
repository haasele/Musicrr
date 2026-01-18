import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for managing accessibility features
class AccessibilityService {
  /// Check if reduced motion is enabled
  static bool isReducedMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get animation duration based on reduced motion preference
  static Duration getAnimationDuration(
    BuildContext context,
    Duration defaultDuration,
  ) {
    if (isReducedMotionEnabled(context)) {
      return Duration.zero;
    }
    return defaultDuration;
  }

  /// Get animation curve based on reduced motion preference
  static Curve getAnimationCurve(BuildContext context) {
    if (isReducedMotionEnabled(context)) {
      return Curves.linear;
    }
    return Curves.easeInOut;
  }

  /// Check if high contrast is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Get text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Check if bold text is enabled
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }
}

/// Widget that respects reduced motion settings
class AccessibleAnimatedWidget extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onComplete;

  const AccessibleAnimatedWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AccessibilityService.getAnimationDuration(
      context,
      duration,
    );
    final effectiveCurve = AccessibilityService.getAnimationCurve(context);

    if (effectiveDuration == Duration.zero) {
      return child;
    }

    return AnimatedSwitcher(
      duration: effectiveDuration,
      switchInCurve: effectiveCurve,
      switchOutCurve: effectiveCurve,
      child: child,
    );
  }
}

/// Semantic wrapper for better screen reader support
class SemanticWrapper extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final bool? button;
  final VoidCallback? onTap;

  const SemanticWrapper({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.button,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget widget = Semantics(
      label: label,
      hint: hint,
      button: button ?? false,
      child: child,
    );

    if (onTap != null) {
      widget = GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }

    return widget;
  }
}

/// High contrast aware color getter
class AccessibleColors {
  static Color getSurfaceColor(BuildContext context) {
    final theme = Theme.of(context);
    if (AccessibilityService.isHighContrastEnabled(context)) {
      return theme.colorScheme.surface;
    }
    return theme.colorScheme.surfaceContainerHighest;
  }

  static Color getOnSurfaceColor(BuildContext context) {
    final theme = Theme.of(context);
    if (AccessibilityService.isHighContrastEnabled(context)) {
      return theme.colorScheme.onSurface;
    }
    return theme.colorScheme.onSurfaceVariant;
  }
}
