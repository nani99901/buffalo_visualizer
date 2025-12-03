import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MilkProductionGraphWidget extends StatelessWidget {
  final List<dynamic> yearlyData;
  const MilkProductionGraphWidget({Key? key, required this.yearlyData}) : super(key: key);

  String formatNumber(num n) => NumberFormat.decimalPattern('en_IN').format(n);

  @override
  Widget build(BuildContext context) {
    if (yearlyData.isEmpty) return const SizedBox.shrink();
    final maxLiters = yearlyData.map((d) => d['liters'] as num? ?? 0).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.bar_chart, color: Colors.blue), SizedBox(width: 8), Text('Milk Production Over Years')]),
          const SizedBox(height: 12),
          Column(children: yearlyData.map((d) {
            final percentage = (d['liters'] as num? ?? 0) / maxLiters * 100;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: SizedBox(height: 60, child: Row(children: [SizedBox(width: 70, child: Text('${d['year']}')), Expanded(child: LinearProgressIndicator(value: percentage / 100))])));
          }).toList())
        ]),
      ),
    );
  }
}
