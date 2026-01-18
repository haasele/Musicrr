import 'package:flutter/material.dart';

class SolidColorBackground extends StatelessWidget {
  final Color color;
  final Widget child;
  
  const SolidColorBackground({
    super.key,
    required this.color,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: child,
    );
  }
}
