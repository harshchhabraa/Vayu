import 'package:flutter/material.dart';

class VayuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final bool showShadow;

  const VayuCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.margin,
    this.width,
    this.height,
    this.color,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? const Color(0xFFF1F8F7); // Cleaner, slightly brighter base

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: showShadow ? [
          // 1. Dark Soft Shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(4, 12),
            blurRadius: 30,
            spreadRadius: 0,
          ),
          // 2. Light Inner Highlight (Subtle)
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            offset: const Offset(-4, -4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
