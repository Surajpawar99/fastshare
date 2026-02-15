import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpeedChart extends StatefulWidget {
  final double currentSpeed;

  const SpeedChart({super.key, required this.currentSpeed});

  @override
  State<SpeedChart> createState() => _SpeedChartState();
}

class _SpeedChartState extends State<SpeedChart> {
  final List<FlSpot> _spots = [];
  int _counter = 0;

  @override
  void didUpdateWidget(covariant SpeedChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSpeed != oldWidget.currentSpeed) {
      _addSpot(widget.currentSpeed);
    }
  }

  void _addSpot(double speed) {
    if (_spots.length > 20) {
      _spots.removeAt(0);
    }
    _spots.add(FlSpot(_counter.toDouble(), speed));
    _counter++;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.2),
              ),
            ),
          ],
          minY: 0,
        ),
      ),
    );
  }
}
