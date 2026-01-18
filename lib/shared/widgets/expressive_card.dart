import 'package:flutter/material.dart';

/// Material 3 Expressive card with tonal surface and container-based elevation
class ExpressiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  
  const ExpressiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.surfaceContainerHighest;
    
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// Expressive container with shape morphing support
class ExpressiveContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  
  const ExpressiveContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.color,
    this.padding,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final containerColor = color ?? theme.colorScheme.surfaceContainer;
    
    Widget container = Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding,
      child: child,
    );
    
    if (onTap != null) {
      container = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }
    
    return container;
  }
}
