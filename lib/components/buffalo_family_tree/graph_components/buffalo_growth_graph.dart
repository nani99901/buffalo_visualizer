import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BuffaloGrowthGraphWidget extends StatelessWidget {
  final List<dynamic> yearlyData;
  const BuffaloGrowthGraphWidget({Key? key, required this.yearlyData}) : super(key: key);

  String formatNumber(num n) => NumberFormat.decimalPattern('en_IN').format(n);

  @override
  Widget build(BuildContext context) {
    if (yearlyData.isEmpty) return const SizedBox.shrink();
    final maxBuffaloes = yearlyData.map((d) => d['totalBuffaloes'] as num).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.trending_up, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Buffalo Population Growth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: yearlyData.asMap().entries.map((entry) {
                final i = entry.key;
                final data = entry.value;
                final total = data['totalBuffaloes'] as num;
                final producing = data['producingBuffaloes'] as num? ?? 0;
                final percentage = (total / maxBuffaloes) * 100;
                final prev = i > 0 ? yearlyData[i - 1]['totalBuffaloes'] as num : total;
                final growth = i > 0 ? ((total - prev) / prev) * 100 : 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        SizedBox(width: 72, child: Text('${data['year']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${formatNumber(total)} Buffaloes', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('(${formatNumber(producing)} producing)', style: const TextStyle(color: Colors.grey)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: growth > 0 ? Colors.purple[50] : growth < 0 ? Colors.red[50] : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(i > 0 ? '${growth > 0 ? '↗ ' : growth < 0 ? '↘ ' : ''}${growth.abs().toStringAsFixed(1)}%' : ''),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(height: 28, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16))),
                                  FractionallySizedBox(
                                    widthFactor: percentage / 100.0,
                                    child: Container(
                                      height: 28,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.only(right: 8),
                                      alignment: Alignment.centerRight,
                                      child: Text('${percentage.toStringAsFixed(0)}% of peak', style: const TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
