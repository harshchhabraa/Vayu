import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class VayuDeteriorationChart extends StatelessWidget {
  final List<double> stressPoints; // Values from 0 to 100 representing stress/inflammation

  const VayuDeteriorationChart({
    Key? key,
    required this.stressPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We'll show "Vitality %" which is 100 - stress
    final List<FlSpot> spots = stressPoints.asMap().entries.map((e) {
      final vitality = (100 - e.value).clamp(0.0, 100.0);
      return FlSpot(e.key.toDouble(), vitality);
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == 100 || value == 50) {
                  return Text('${value.toInt()}%', 
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.redAccent.withOpacity(0.2), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF263238),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}% VITALITY',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
