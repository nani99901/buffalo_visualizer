import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RevenueGraphWidget extends StatelessWidget {
  final List<dynamic> yearlyData;
  const RevenueGraphWidget({Key? key, required this.yearlyData}) : super(key: key);

  String formatCurrency(num n) => NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(n);

  @override
  Widget build(BuildContext context) {
    if (yearlyData.isEmpty) return const SizedBox.shrink();

    final maxRevenue = yearlyData.map((d) => d['revenue'] as num).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.trending_up, color: Colors.green), SizedBox(width: 8), Text('Revenue Growth Over Years', style: TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            Column(
              children: yearlyData.map((d) {
                final percentage = (d['revenue'] as num) / maxRevenue * 100;
                final idx = yearlyData.indexOf(d);
                final growth = idx > 0 ? ((d['revenue'] - yearlyData[idx - 1]['revenue']) / yearlyData[idx - 1]['revenue'] * 100) : 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      SizedBox(width: 70, child: Text('${d['year']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(formatCurrency(d['revenue'] as num)),
                          Text('${growth.toStringAsFixed(1)}%'),
                        ]),
                        const SizedBox(height: 8),
                        Stack(children: [
                          Container(height: 28, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16))),
                          FractionallySizedBox(widthFactor: percentage / 100, child: Container(height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(16))))
                        ])
                      ]))
                    ]),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
