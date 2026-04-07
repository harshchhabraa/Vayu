import 'package:flutter/material.dart';
import 'package:vayu/domain/models/detection_result.dart';

class VayuHudPainter extends CustomPainter {
  final List<Detection> detections;
  final Size previewSize;

  VayuHudPainter({
    required this.detections,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      if (!detection.isDisplayable) continue;

      final rect = _getScaledRect(detection.boundingBox, size);
      final color = Color(detection.gasColor);
      
      _drawSkeletalBox(canvas, rect, color);
      _drawLabel(canvas, rect, detection, color);
    }
  }

  void _drawSkeletalBox(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double cornerLength = rect.width * 0.2;
    
    // Draw 4 corners (the "Skeletal" look)
    final path = Path()
      // Top Left
      ..moveTo(rect.left, rect.top + cornerLength)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + cornerLength, rect.top)
      
      // Top Right
      ..moveTo(rect.right - cornerLength, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + cornerLength)
      
      // Bottom Right
      ..moveTo(rect.right, rect.bottom - cornerLength)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right - cornerLength, rect.bottom)
      
      // Bottom Left
      ..moveTo(rect.left + cornerLength, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.bottom - cornerLength);

    canvas.drawPath(path, paint);
    
    // Pulse/Inner area
    canvas.drawRect(
      rect, 
      Paint()..color = color.withOpacity(0.05)..style = PaintingStyle.fill
    );
  }

  void _drawLabel(Canvas canvas, Rect rect, Detection detection, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${detection.inferredGasLabel}\n${(detection.confidence * 100).toStringAsFixed(0)}% MATCH',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(rect.left, rect.top - textPainter.height - 4));
  }

  Rect _getScaledRect(BoundingBox box, Size size) {
    return Rect.fromLTRB(
      box.left * size.width,
      box.top * size.height,
      box.right * size.width,
      box.bottom * size.height,
    );
  }

  @override
  bool shouldRepaint(covariant VayuHudPainter oldDelegate) => true;
}
