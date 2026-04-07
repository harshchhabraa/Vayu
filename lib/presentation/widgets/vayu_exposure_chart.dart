import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';

class VayuExposureChart extends StatelessWidget {
  final List<ExposureEntry> entries;
  final double height;

  const VayuExposureChart({
    Key? key,
    required this.entries,
    this.height = 220, // Slightly taller for axis titles
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Start moving to see your health trends...',
            style: TextStyle(color: Color(0xFF80CBC4), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.score);
    }).toList();

    // Determine Y range (ensure at least 2.0 scale)
    double maxScore = entries.map((e) => e.score).reduce((a, b) => a > b ? a : b);
    double maxY = (maxScore * 1.2).clamp(2.0, double.infinity);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xFF00796B).withOpacity(0.05),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (entries.length / 4).clamp(1.0, double.infinity),
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                  
                  // Show time only at specific intervals to avoid crowding
                  final time = entries[index].timestamp;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('HH:mm').format(time),
                      style: const TextStyle(color: Color(0xFF80CBC4), fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(color: Color(0xFF80CBC4), fontWeight: FontWeight.bold, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF004D40),
              tooltipRoundedRadius: 12,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final entry = entries[spot.x.toInt()];
                  final timeStr = DateFormat('HH:mm').format(entry.timestamp);
                  return LineTooltipItem(
                    '$timeStr\nAQI: ${entry.aqi}\n${entry.activity.label}\nScore: ${entry.score.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: const Color(0xFF00796B),
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (index == entries.length - 1) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: const Color(0xFF00796B),
                    );
                  }
                  return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                },
              ),
              shadow: const Shadow(
                color: Color.fromRGBO(0, 121, 107, 0.2),
                offset: Offset(0, 5),
                blurRadius: 5,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00BFA5).withOpacity(0.3),
                    const Color(0xFF00BFA5).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
