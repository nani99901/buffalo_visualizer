import 'package:flutter/material.dart';

import 'models.dart';
import '../../services/simulation_service.dart';
import 'header_controls.dart';
import 'tree_visualization.dart';
import 'cost_estimation_table.dart';

class BuffaloFamilyTree extends StatefulWidget {
  const BuffaloFamilyTree({Key? key}) : super(key: key);

  @override
  _BuffaloFamilyTreeState createState() => _BuffaloFamilyTreeState();
}

class _BuffaloFamilyTreeState extends State<BuffaloFamilyTree> {
  int units = 1;
  int years = 10;
  int startYear = 2026;
  int startMonth = 0;
  bool loading = false;
  Map<String, dynamic>? treeData;
  Map<String, dynamic>? revenueData;

  void runSimulation() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(milliseconds: 250));
    final result = SimulationService.runSimulation(
        units: units, years: years, startYear: startYear, startMonth: startMonth);
    setState(() {
      treeData = result['treeData'] as Map<String, dynamic>;
      revenueData = result['revenueData'] as Map<String, dynamic>;
      loading = false;
    });
  }

  void resetSimulation() {
    setState(() {
      treeData = null;
      revenueData = null;
      units = 1;
      years = 10;
      startYear = 2026;
      startMonth = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderControls(
              units: units,
              setUnits: (val) => setState(() => units = val),
              years: years,
              setYears: (val) => setState(() => years = val),
              startYear: startYear,
              setStartYear: (val) => setState(() => startYear = val),
              startMonth: startMonth,
              setStartMonth: (val) => setState(() => startMonth = val),
              runSimulation: runSimulation,
              treeData: treeData,
              onPriceEstimationPressed: () {
                if (revenueData == null || treeData == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please run a simulation to generate price estimates.')));
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => CostEstimationTable(treeData: treeData!, revenueData: revenueData!)));
              },
              resetSimulation: resetSimulation,
            ),
            Expanded(
              child: treeData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.grass, size: 80, color: Colors.indigo),
                          const SizedBox(height: 16),
                          const Text('Buffalo Family Tree Simulator', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: runSimulation, child: const Text('Start Your First Simulation'))
                        ],
                      ),
                    )
                  : Expanded(child: TreeVisualization(treeData: treeData!)),
            ),
          ],
        ),
      ),
    );
  }
}
