import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vayu/presentation/widgets/vayu_background.dart';
import 'package:vayu/presentation/widgets/vayu_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXPOSURE INSIGHTS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: VayuBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('WEEKLY EXPOSURE (AVG)'),
              const SizedBox(height: 16),
              _buildWeeklyChart(),
              const SizedBox(height: 40),
              
              _buildSectionHeader('MONTHLY TREND'),
              const SizedBox(height: 16),
              _buildMonthlyChart(),
              const SizedBox(height: 40),

              _buildSectionHeader('VULNERABILITY MATRIX'),
              const SizedBox(height: 16),
              _buildVulnerabilityMatrix(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.tealAccent,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return VayuCard(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[value.toInt()], style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeGroupData(0, 45),
            _makeGroupData(1, 62),
            _makeGroupData(2, 85),
            _makeGroupData(3, 40),
            _makeGroupData(4, 95),
            _makeGroupData(5, 30),
            _makeGroupData(6, 25),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: y > 70 ? Colors.redAccent : Colors.tealAccent,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    return VayuCard(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 40),
                FlSpot(1, 45),
                FlSpot(2, 35),
                FlSpot(3, 55),
                FlSpot(4, 80),
                FlSpot(5, 75),
                FlSpot(6, 60),
                FlSpot(7, 50),
              ],
              isCurved: true,
              color: Colors.orangeAccent,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orangeAccent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVulnerabilityMatrix() {
    return VayuCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildMatrixRow('MORNING COMMUTE', 'HIGH RISK', Colors.redAccent),
          const Divider(height: 32, color: Colors.white10),
          _buildMatrixRow('AFTERNOON LUNCH', 'LOW RISK', Colors.tealAccent),
          const Divider(height: 32, color: Colors.white10),
          _buildMatrixRow('EVENING PEAK', 'MODERATE', Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
