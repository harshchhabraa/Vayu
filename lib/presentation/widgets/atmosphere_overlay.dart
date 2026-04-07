import 'package:flutter/material.dart';

class AtmosphereOverlay extends StatelessWidget {
  final double currentAqi;
  final double intensity; // 0.0 to 1.0 (Scrub activation)

  const AtmosphereOverlay({
    Key? key,
    required this.currentAqi,
    required this.intensity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getAtmosphereColor(currentAqi);
    final fogOpacity = (currentAqi / 300).clamp(0.0, 0.7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(fogOpacity * intensity),
            color.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Color _getAtmosphereColor(double aqi) {
    if (aqi <= 50) return const Color(0xFF00BFA5); // Clear/Teal
    if (aqi <= 100) return const Color(0xFFFFB300); // Hazy/Amber
    return const Color(0xFF546E7A); // Smog/Grey-Blue
  }
}
