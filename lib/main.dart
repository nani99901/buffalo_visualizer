// import 'package:flutter/material.dart';
// import 'components/buffalo_family_tree/buffalo_family_tree.dart';

// void main() {
//   runApp(const BuffaloVisualizerSample());
// }

// class BuffaloVisualizerSample extends StatelessWidget {
//   const BuffaloVisualizerSample({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Sample data used earlier; BuffaloFamilyTree now generates data via the simulation service

//     return MaterialApp(
//       title: 'Buffalo Visualizer - Flutter (Sample)',
//       theme: ThemeData(
//         scaffoldBackgroundColor: const Color(0xFFF0F4FF),
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//       ),
//       debugShowCheckedModeBanner: false,
//       home: const BuffaloFamilyTree(),
//     );
//   }
// }

import 'package:buffalo_visualizer/components/buffalo_family_tree/cost_estimation_table.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;

void main() {
  // Register iframe factory
  ui.platformViewRegistry.registerViewFactory(
    'react-iframe',
    (int viewId) {
      final IFrameElement = html.IFrameElement()
        ..id = 'react-iframe'
        ..src = 'https://buffalovisualizer.vercel.app/'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return IFrameElement;
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buffalo Visualizer - Flutter Controller',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: SafeArea(child: ControllerPage()),
      ),
    );
  }
}

class ControllerPage extends StatefulWidget {
  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  int units = 1;
  int years = 10;
  int startYear = 2026;
  int startMonth = 0; // 0-based
  Map<String, dynamic>? treeData;
  Map<String, dynamic>? revenueData;

  // Revenue configuration
  final Map<String, dynamic> revenueConfig = {
    'landingPeriod': 2,
    'highRevenuePhase': {'months': 5, 'revenue': 9000},
    'mediumRevenuePhase': {'months': 3, 'revenue': 6000},
    'restPeriod': {'months': 4, 'revenue': 0}
  };

  // Calculate monthly revenue for EACH buffalo based on its individual cycle
  int calculateMonthlyRevenueForBuffalo(
    int buffaloId,
    int acquisitionMonth,
    int currentYear,
    int currentMonth,
    int startYearVal,
  ) {
    final monthsSinceAcquisition =
        (currentYear - startYearVal) * 12 + (currentMonth - acquisitionMonth);
    
    if (monthsSinceAcquisition < revenueConfig['landingPeriod']) {
      return 0;
    }
    
    final productionMonths = monthsSinceAcquisition - revenueConfig['landingPeriod'];
    final cyclePosition = productionMonths % 12;
    
    if (cyclePosition < revenueConfig['highRevenuePhase']['months']) {
      return revenueConfig['highRevenuePhase']['revenue'];
    } else if (cyclePosition < revenueConfig['highRevenuePhase']['months'] + 
               revenueConfig['mediumRevenuePhase']['months']) {
      return revenueConfig['mediumRevenuePhase']['revenue'];
    } else {
      return revenueConfig['restPeriod']['revenue'];
    }
  }

  // Calculate annual revenue for ALL mature buffaloes with individual cycles
  Map<String, dynamic> calculateAnnualRevenueForHerd(
    List<dynamic> herd,
    int startYearVal,
    int startMonthVal,
    int currentYear,
  ) {
    double annualRevenue = 0;
    
    final matureBuffaloes = herd.where((buffalo) {
      final ageInCurrentYear = currentYear - buffalo['birthYear'];
      return ageInCurrentYear >= 3;
    }).toList();

    for (final buffalo in matureBuffaloes) {
      final acquisitionMonth = buffalo['acquisitionMonth'];
      
      for (int month = 0; month < 12; month++) {
        annualRevenue += calculateMonthlyRevenueForBuffalo(
          buffalo['id'], 
          acquisitionMonth, 
          currentYear, 
          month,
          startYearVal
        );
      }
    }

    return {
      'annualRevenue': annualRevenue,
      'matureBuffaloes': matureBuffaloes.length,
      'totalBuffaloes': herd.where((buffalo) => buffalo['birthYear'] <= currentYear).length
    };
  }

  // Calculate total revenue data based on ACTUAL herd growth with staggered cycles
  Map<String, dynamic> calculateRevenueData(
    List<dynamic> herd,
    int startYearVal,
    int startMonthVal,
    int totalYears,
  ) {
    final List<Map<String, dynamic>> yearlyData = [];
    double totalRevenue = 0;
    double totalMatureBuffaloYears = 0;

    final monthNames = [
      "January", "February", "March", "April", "May", "June", 
      "July", "August", "September", "October", "November", "December"
    ];

    for (int yearOffset = 0; yearOffset < totalYears; yearOffset++) {
      final currentYear = startYearVal + yearOffset;
      
      final annualResult = calculateAnnualRevenueForHerd(
        herd, startYearVal, startMonthVal, currentYear
      );

      final annualRevenue = annualResult['annualRevenue'];
      final matureBuffaloes = annualResult['matureBuffaloes'];
      final totalBuffaloes = annualResult['totalBuffaloes'];

      totalRevenue += annualRevenue;
      totalMatureBuffaloYears += matureBuffaloes;

      final monthlyRevenuePerBuffalo = matureBuffaloes > 0 
          ? annualRevenue / (matureBuffaloes * 12) 
          : 0;

      yearlyData.add({
        'year': currentYear,
        'activeUnits': (totalBuffaloes / 2).ceil(),
        'monthlyRevenue': monthlyRevenuePerBuffalo,
        'revenue': annualRevenue,
        'totalBuffaloes': totalBuffaloes,
        'producingBuffaloes': matureBuffaloes,
        'nonProducingBuffaloes': totalBuffaloes - matureBuffaloes,
        'startMonth': monthNames[startMonthVal],
        'startYear': startYearVal,
        'matureBuffaloes': matureBuffaloes
      });
    }

    return {
      'yearlyData': yearlyData,
      'totalRevenue': totalRevenue,
      'totalUnits': totalMatureBuffaloYears / totalYears,
      'averageAnnualRevenue': totalRevenue / totalYears,
      'revenueConfig': revenueConfig,
      'totalMatureBuffaloYears': totalMatureBuffaloYears
    };
  }

  // Run simulation locally
  void runLocalSimulation() {
    setState(() {
      treeData = null;
      revenueData = null;
    });

    // Simulate loading
    Future.delayed(const Duration(milliseconds: 300), () {
      final totalYears = years;
      final List<Map<String, dynamic>> herd = [];
      int nextId = 1;

      // Create initial buffaloes (2 per unit) with staggered acquisition
      for (int u = 0; u < units; u++) {
        // First buffalo - acquired in starting month
        herd.add({
          'id': nextId++,
          'age': 3,
          'mature': true,
          'parentId': null,
          'generation': 0,
          'birthYear': startYear - 3,
          'acquisitionMonth': startMonth,
          'unit': u + 1,
        });

        // Second buffalo - acquired in July (6 months later)
        herd.add({
          'id': nextId++,
          'age': 3,
          'mature': true,
          'parentId': null,
          'generation': 0,
          'birthYear': startYear - 3,
          'acquisitionMonth': (startMonth + 6) % 12,
          'unit': u + 1,
        });
      }

      // Simulate years
      for (int year = 1; year <= totalYears; year++) {
        final currentYear = startYear + (year - 1);
        final matureBuffaloes = herd.where((b) => b['age'] >= 3).toList();

        // Each mature buffalo gives birth to one offspring per year
        for (final parent in matureBuffaloes) {
          herd.add({
            'id': nextId++,
            'age': 0,
            'mature': false,
            'parentId': parent['id'],
            'birthYear': currentYear,
            'acquisitionMonth': parent['acquisitionMonth'],
            'generation': parent['generation'] + 1,
            'unit': parent['unit'],
          });
        }

        // Age all buffaloes
        for (final b in herd) {
          b['age']++;
          if (b['age'] >= 3) b['mature'] = true;
        }
      }

      // Calculate revenue data based on ACTUAL herd growth with staggered cycles
      final calculatedRevenueData = calculateRevenueData(
        herd, startYear, startMonth, totalYears
      );

      setState(() {
        treeData = {
          'units': units,
          'years': years,
          'startYear': startYear,
          'startMonth': startMonth,
          'totalBuffaloes': herd.length,
          'buffaloes': herd,
          'revenueData': calculatedRevenueData
        };
        revenueData = calculatedRevenueData;
      });
    });
  }

  void sendToReact() {
    final iframe = html.document.getElementById('react-iframe') as html.IFrameElement?;

    if (iframe == null) {
      print('Iframe not found');
      return;
    }

    if (iframe.contentWindow == null) {
      print('Iframe content window not ready');
      return;
    }

    print('Sending to React: units=$units, years=$years, startYear=$startYear, startMonth=$startMonth');
    
    // Also run local simulation to generate data for Flutter
    runLocalSimulation();
    
    // Send to React iframe
    iframe.contentWindow!.postMessage({
      "type": "RUN_SIMULATION",
      "payload": {
        "units": units,
        "years": years,
        "startYear": startYear,
        "startMonth": startMonth,
      }
    }, "*");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Buffalo Family Tree Simulator',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Units
                    _buildFieldRow(
                      label: 'Starting Units',
                      child: SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: units.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => units = int.tryParse(v) ?? units),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
        
                    // Years
                    _buildFieldRow(
                      label: 'Simulation Years',
                      child: SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: years.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => years = int.tryParse(v) ?? years),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),

                    // Start Year
                    _buildFieldRow(
                      label: 'Start Year',
                      child: SizedBox(
                        width: 120,
                        child: TextFormField(
                          initialValue: startYear.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => startYear = int.tryParse(v) ?? startYear),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),

                    // Start Month
                    _buildFieldRow(
                      label: 'Start Month',
                      child: DropdownButton<int>(
                        value: startMonth,
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i,
                          child: Text(_monthName(i)),
                        )),
                        onChanged: (v) => setState(() => startMonth = v ?? startMonth),
                      ),
                    ),
                    const SizedBox(width: 30),

                    // Run Button
                    ElevatedButton.icon(
                      onPressed: sendToReact,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run'),
                    ),
                    const SizedBox(width: 10),

                    // Reset Button
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          units = 2;
                          years = 10;
                          startYear = 2026;
                          startMonth = 0;
                          treeData = null;
                          revenueData = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                    const SizedBox(width: 40),

                    // Price Estimation Button (only enabled when simulation data exists)
                    ElevatedButton.icon(
                      onPressed: treeData != null && revenueData != null
                          ? () {
                            // print(treeData);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CostEstimationTable(
                                  treeData: treeData!,
                                  revenueData: revenueData!,
                                ),
                              ),
                            );
                          }
                          : null,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Price Estimation'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Status indicator
        if (treeData == null && revenueData == null)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Click "Run" to simulate and generate data for price estimation',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          )
        else if (treeData != null && revenueData != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Simulation data ready! ${treeData!['totalBuffaloes']} buffaloes simulated over $years years',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: const HtmlElementView(viewType: 'react-iframe'),
          ),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const monthNames = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return monthNames[m % 12];
  }

  Widget _buildFieldRow({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        child,
      ],
    );
  }
}