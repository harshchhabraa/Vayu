import 'package:flutter/material.dart';

class VayuBackground extends StatelessWidget {
  final Widget child;

  const VayuBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CB8C4),
            Color(0xFF3CD3AD),
          ],
        ),
      ),
      // Background should cover the whole screen; child handles its own padding/SafeAreas if needed
      child: child,
    );
  }
}    
