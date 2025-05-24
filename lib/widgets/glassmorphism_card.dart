import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color color;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.color = const Color.fromARGB(255, 194, 194, 194),
    this.opacity = 0.2,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.grey.withOpacity(0.8),
                width: 0.7,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
