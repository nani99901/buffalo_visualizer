import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BuffaloGrowthGraph extends StatelessWidget {
  final List<Map<String, dynamic>> yearlyData;

  const BuffaloGrowthGraph({Key? key, required this.yearlyData}) : super(key: key);

  String formatNumber(num n) {
    final f = NumberFormat.decimalPattern('en_IN');
    return f.format(n);
  }

  @override
  Widget build(BuildContext context) {
    if (yearlyData.isEmpty) return const SizedBox.shrink();

    final maxBuffaloes = yearlyData
        .map((d) => d['totalBuffaloes'] as num)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Buffalo Population Growth',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: yearlyData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final total = data['totalBuffaloes'] as num;
                final producing = data['producingBuffaloes'] as num? ?? 0;
                final percentage = (total / maxBuffaloes) * 100;
                final prevTotal = index > 0 ? yearlyData[index - 1]['totalBuffaloes'] as num : total;
                final growth = index > 0
                    ? ((total - prevTotal) / prevTotal) * 100
                    : 0;

                Color growthColor;
                if (growth > 0) {
                  growthColor = Colors.purple[700]!;
                } else if (growth < 0) {
                  growthColor = Colors.red[700]!;
                } else {
                  growthColor = Colors.grey[700]!;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(
                            data['year'].toString(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${formatNumber(total)} Buffaloes',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '(${formatNumber(producing)} producing)',
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: growth > 0 ? Colors.purple[50] : growth < 0 ? Colors.red[50] : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      index > 0
                                          ? '${growth > 0 ? '↗ ' : growth < 0 ? '↘ ' : ''}${growth.abs().toStringAsFixed(1)}%'
                                          : '',
                                      style: TextStyle(color: growthColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage / 100.0,
                                    child: Container(
                                      height: 28,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.only(right: 12),
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${percentage.toStringAsFixed(0)}% of peak',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
