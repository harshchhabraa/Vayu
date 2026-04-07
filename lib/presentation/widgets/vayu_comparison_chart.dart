import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ComparisonData {
  final List<double> baseline;
  final List<double> projected;
  final List<double> aqiValues; // The raw AQI at each point for the atmosphere

  ComparisonData({required this.baseline, required this.projected, required this.aqiValues});
}

class VayuComparisonChart extends StatelessWidget {
  final ComparisonData data;
  final Function(double x, double y, double aqi) onScrub;
  final VoidCallback? onScrubEnd;

  const VayuComparisonChart({
    Key? key,
    required this.data,
    required this.onScrub,
    this.onScrubEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (event is FlPanEndEvent || event is FlPointerExitEvent) {
               if (onScrubEnd != null) onScrubEnd!();
            } else if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
              final spot = response.lineBarSpots!.first;
              final index = spot.spotIndex;
              onScrub(spot.x / (data.baseline.length - 1), spot.y, data.aqiValues[index]);
            }
          },
          touchTooltipData: const LineTouchTooltipData(showOnTopOfTheChartBoxArea: true),
        ),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // 1. Baseline (Gray Dashed)
          LineChartBarData(
            spots: data.baseline.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: Colors.grey.withOpacity(0.4),
            barWidth: 2,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
          // 2. Projected (Teal Solid)
          LineChartBarData(
            spots: data.projected.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: const Color(0xFF00BFA5),
            barWidth: 6,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [const Color(0xFF00BFA5).withOpacity(0.3), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
