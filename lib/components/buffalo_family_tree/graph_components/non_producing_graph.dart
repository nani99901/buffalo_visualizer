import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NonProducingBuffaloGraphWidget extends StatelessWidget {
  final List<dynamic> yearlyData;
  const NonProducingBuffaloGraphWidget({Key? key, required this.yearlyData}) : super(key: key);

  String formatNumber(num n) => NumberFormat.decimalPattern('en_IN').format(n);

  @override
  Widget build(BuildContext context) {
    if (yearlyData.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.pie_chart, color: Colors.orange), SizedBox(width: 8), Text('Non-Producing Buffalo Analysis')]),
            const SizedBox(height: 12),
            Column(children: yearlyData.map((d) {
              final total = d['totalBuffaloes'] as num;
              final producing = d['producingBuffaloes'] as num;
              final nonProducing = total - producing;
              final producingPercentage = (producing / total) * 100;
              final nonProducingPercentage = (nonProducing / total) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${d['year']}'), Text('Total: ${formatNumber(total)} buffaloes')]),
                    const SizedBox(height: 8),
                    Text('Producing: ${formatNumber(producing)} - ${producingPercentage.toStringAsFixed(1)}%'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: producingPercentage / 100, color: Colors.green),
                    const SizedBox(height: 10),
                    Text('Non-Producing: ${formatNumber(nonProducing)} - ${nonProducingPercentage.toStringAsFixed(1)}%'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: nonProducingPercentage / 100, color: Colors.orange),
                  ],
                ),
              );
            }).toList())
          ],
        ),
      ),
    );
  }
}
