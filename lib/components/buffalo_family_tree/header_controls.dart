import 'package:flutter/material.dart';

class HeaderControls extends StatelessWidget {
  final int units;
  final void Function(int) setUnits;
  final int years;
  final void Function(int) setYears;
  final int startYear;
  final void Function(int) setStartYear;
  final int startMonth;
  final void Function(int) setStartMonth;
  final VoidCallback runSimulation;
  final Map<String, dynamic>? treeData;
  final VoidCallback resetSimulation;
  final VoidCallback? onPriceEstimationPressed;

  const HeaderControls({
    Key? key,
    required this.units,
    required this.setUnits,
    required this.years,
    required this.setYears,
    required this.startYear,
    required this.setStartYear,
    required this.startMonth,
    required this.setStartMonth,
    required this.runSimulation,
    required this.treeData,
    required this.resetSimulation,
    this.onPriceEstimationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🐃 Buffalo Family Tree Simulator', style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  if (treeData != null) ...[
                    ElevatedButton(onPressed: resetSimulation, child: const Text('Reset')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: onPriceEstimationPressed, child: const Text('Price estimation')),
                    const SizedBox(width: 8),
                  ],
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Starting Units'),
                  controller: TextEditingController(text: units.toString()),
                  onSubmitted: (val) => setUnits(int.tryParse(val) ?? units),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Years'),
                  controller: TextEditingController(text: years.toString()),
                  onSubmitted: (val) => setYears(int.tryParse(val) ?? years),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Start Year'),
                  controller: TextEditingController(text: startYear.toString()),
                  onSubmitted: (val) => setStartYear(int.tryParse(val) ?? startYear),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int>(
                  value: startMonth,
                  items: monthNames.asMap().entries.map((entry) => DropdownMenuItem<int>(value: entry.key, child: Text(entry.value))).toList(),
                  onChanged: (v) => setStartMonth(v ?? startMonth),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: runSimulation, child: const Text('Run Simulation')),
            ],
          )
        ],
      ),
    );
  }
}
