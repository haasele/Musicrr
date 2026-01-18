import 'package:flutter/material.dart';

/// Material 3 Expressive motion animations
class ExpressiveMotion {
  /// Standard duration for expressive animations
  static const Duration standardDuration = Duration(milliseconds: 300);
  
  /// Extended duration for shape morphing
  static const Duration extendedDuration = Duration(milliseconds: 500);
  
  /// Quick duration for micro-interactions
  static const Duration quickDuration = Duration(milliseconds: 150);
  
  /// Standard curve for expressive motion
  static const Curve standardCurve = Curves.easeInOutCubic;
  
  /// Emphasized curve for important animations
  static const Curve emphasizedCurve = Curves.easeOutCubic;
  
  /// Decelerated curve for entrances
  static const Curve deceleratedCurve = Curves.decelerate;
  
  /// Accelerated curve for exits
  static const Curve acceleratedCurve = Curves.fastOutSlowIn;
}

/// Animated container with shape morphing
class MorphingContainer extends StatefulWidget {
  final Widget child;
  final double startBorderRadius;
  final double endBorderRadius;
  final Color? startColor;
  final Color? endColor;
  final Duration duration;
  final VoidCallback? onAnimationComplete;
  
  const MorphingContainer({
    super.key,
    required this.child,
    this.startBorderRadius = 8,
    this.endBorderRadius = 24,
    this.startColor,
    this.endColor,
    this.duration = ExpressiveMotion.extendedDuration,
    this.onAnimationComplete,
  });
  
  @override
  State<MorphingContainer> createState() => _MorphingContainerState();
}

class _MorphingContainerState extends State<MorphingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderRadiusAnimation;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _borderRadiusAnimation = Tween<double>(
      begin: widget.startBorderRadius,
      end: widget.endBorderRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ExpressiveMotion.standardCurve,
    ));
    
    if (widget.startColor != null && widget.endColor != null) {
      _colorAnimation = ColorTween(
        begin: widget.startColor,
        end: widget.endColor,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: ExpressiveMotion.standardCurve,
      ));
    }
    
    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _colorAnimation.value ?? Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Shared axis transition for navigation (horizontal slide)
class SharedAxisTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: ExpressiveMotion.standardCurve,
      )),
      child: child,
    );
  }
}

/// Fade through transition
class FadeThroughTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
