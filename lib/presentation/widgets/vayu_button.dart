import 'package:flutter/material.dart';

class VayuButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;

  const VayuButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
  }) : super(key: key);

  @override
  State<VayuButton> createState() => _VayuButtonState();
}

class _VayuButtonState extends State<VayuButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSecondary ? Colors.white.withOpacity(0.9) : const Color(0xFF009688); // Teal
    final textColor = widget.isSecondary ? const Color(0xFF009688) : Colors.white;
    final shadowColor = widget.isSecondary ? const Color(0xFFDFDFDF) : const Color(0xFF00695C);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0), // translateY(4px)
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            // Soft shadow when NOT pressed
            if (!_isPressed)
              BoxShadow(
                color: const Color.fromRGBO(0, 150, 136, 0.25),
                offset: const Offset(0, 12),
                blurRadius: 24,
              ),
            // Claymorphism tight bottom lip, shrinks when pressed
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, _isPressed ? 0 : 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
