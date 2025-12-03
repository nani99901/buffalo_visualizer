import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class CostEstimationTable extends StatefulWidget {
  final Map<String, dynamic> treeData;
  final Map<String, dynamic> revenueData;

  const CostEstimationTable({
    Key? key,
    required this.treeData,
    required this.revenueData,
  }) : super(key: key);

  @override
  State<CostEstimationTable> createState() => _CostEstimationTableState();
}

class _CostEstimationTableState extends State<CostEstimationTable> {
  String _activeGraph = "revenue";
  bool _showCostEstimation = true;
  int _selectedYear = 0;
  int _selectedUnit = 1;
  String selectedSection = 'monthly';

  final List<String> _monthNames = [
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

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
  );

  final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  Map<String, dynamic> _buffaloDetails = {};
  Map<String, Map<String, Map<String, dynamic>>> _monthlyRevenue = {};
  Map<String, Map<String, double>> _investorMonthlyRevenue = {};

  @override
  void initState() {
    super.initState();
    _initializeBuffaloDetails();
    _calculateDetailedMonthlyRevenue();
    _selectedYear = widget.treeData['startYear'] ?? DateTime.now().year;
  }

  void _initializeBuffaloDetails() {
    // This is a simplified version - you'll need to adapt based on your actual data structure
    final treeData = widget.treeData;
    final units = treeData['units'] ?? 1;
    _buffaloDetails = {};

    // Generate buffalo details for each unit
    for (int unit = 1; unit <= units; unit++) {
      // Parent buffaloes (2 per unit)
      for (int i = 1; i <= 2; i++) {
        final buffaloId = 'B${(unit - 1) * 2 + i}';
        _buffaloDetails[buffaloId] = {
          'id': buffaloId,
          'unit': unit,
          'generation': 0,
          'acquisitionMonth': 0, // January
          'birthYear': _selectedYear - 3, // Assume 3 years old
          'children': [],
          'grandchildren': [],
          'isActive': true,
        };
      }
    }
  }

  void _calculateDetailedMonthlyRevenue() {
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;

    _monthlyRevenue = {};
    _investorMonthlyRevenue = {};

    // Initialize monthly revenue structure
    for (int year = startYear; year <= startYear + years; year++) {
      _monthlyRevenue[year.toString()] = {};
      _investorMonthlyRevenue[year.toString()] = {};

      for (int month = 0; month < 12; month++) {
        _monthlyRevenue[year.toString()]![month.toString()] = {
          'total': 0,
          'buffaloes': {},
        };
        _investorMonthlyRevenue[year.toString()]![month.toString()] = 0.0;
      }
    }

    // Calculate revenue for each buffalo
    _buffaloDetails.forEach((buffaloId, buffalo) {
      final birthYear = buffalo['birthYear'] as int;
      final unit = buffalo['unit'] as int;
      final acquisitionMonth = buffalo['acquisitionMonth'] as int;

      for (int year = startYear; year <= startYear + years; year++) {
        if (year >= birthYear + 3) {
          // Buffalo becomes productive at age 3
          for (int month = 0; month < 12; month++) {
            final revenue = _calculateMonthlyRevenueForBuffalo(
              acquisitionMonth,
              month,
              year,
              startYear,
            );

            if (revenue > 0) {
              final yearStr = year.toString();
              final monthStr = month.toString();

              _monthlyRevenue[yearStr]![monthStr]!['total'] =
                  (_monthlyRevenue[yearStr]![monthStr]!['total'] as int) +
                  revenue;

              (_monthlyRevenue[yearStr]![monthStr]!['buffaloes']
                      as Map)[buffaloId] =
                  revenue;

              _investorMonthlyRevenue[yearStr]![monthStr] =
                  (_investorMonthlyRevenue[yearStr]![monthStr] ?? 0) + revenue;
            }
          }
        }
      }
    });
  }

  // Calculate monthly revenue for a buffalo
  int _calculateMonthlyRevenueForBuffalo(
    int acquisitionMonth,
    int currentMonth,
    int currentYear,
    int startYear,
  ) {
    final monthsSinceAcquisition =
        (currentYear - startYear) * 12 + (currentMonth - acquisitionMonth);

    if (monthsSinceAcquisition < 2) {
      return 0; // Landing period
    }

    final productionMonth = monthsSinceAcquisition - 2;
    final cycleMonth = productionMonth % 12;

    if (cycleMonth < 5) {
      return 9000; // High revenue phase
    } else if (cycleMonth < 8) {
      return 6000; // Medium revenue phase
    } else {
      return 0; // Rest period
    }
  }

  // Get income producing buffaloes for selected unit and year
  List<Map<String, dynamic>> _getIncomeProducingBuffaloes(int unit, int year) {
    final List<Map<String, dynamic>> incomeProducing = [];

    _buffaloDetails.forEach((buffaloId, buffalo) {
      if (buffalo['unit'] == unit) {
        final birthYear = buffalo['birthYear'] as int;

        // Check if buffalo is at least 3 years old
        if (year >= birthYear + 3) {
          // Check if buffalo has any revenue in the selected year
          bool hasRevenue = false;
          for (int month = 0; month < 12; month++) {
            final revenue =
                (_monthlyRevenue[year.toString()]?[month
                        .toString()]?['buffaloes']
                    as Map?)?[buffaloId] ??
                0;
            if (revenue > 0) {
              hasRevenue = true;
              break;
            }
          }

          if (hasRevenue) {
            incomeProducing.add({'id': buffaloId, ...buffalo});
          }
        }
      }
    });

    return incomeProducing;
  }

  Future<void> _downloadExcel() async {
    final unitBuffaloes = _getIncomeProducingBuffaloes(
      _selectedUnit,
      _selectedYear,
    );
    final cpfCost = _calculateCPFCost(unitBuffaloes);

    // Create CSV content
    StringBuffer csvContent = StringBuffer();
    csvContent.writeln(
      'Monthly Revenue Breakdown - Unit $_selectedUnit - $_selectedYear\n',
    );

    // Headers
    csvContent.write('Month,');
    for (final buffalo in unitBuffaloes) {
      csvContent.write('${buffalo['id']},');
    }
    csvContent.writeln('Unit Total,CPF Cost,Net Revenue');

    // Monthly data
    for (int monthIndex = 0; monthIndex < _monthNames.length; monthIndex++) {
      double unitTotal = 0;
      csvContent.write('${_monthNames[monthIndex]},');

      for (final buffalo in unitBuffaloes) {
        final revenue =
            (_monthlyRevenue[_selectedYear.toString()]?[monthIndex
                    .toString()]?['buffaloes']
                as Map?)?[buffalo['id']] ??
            0;
        csvContent.write('$revenue,');
        unitTotal += revenue.toDouble();
      }

      final netRevenue = unitTotal - cpfCost['monthlyCPFCost'];
      csvContent.writeln('$unitTotal,${cpfCost['monthlyCPFCost']},$netRevenue');
    }

    // Yearly totals
    double yearlyUnitTotal = 0;
    csvContent.write('\nYearly Total,');

    for (final buffalo in unitBuffaloes) {
      double yearlyTotal = 0;
      for (int monthIndex = 0; monthIndex < _monthNames.length; monthIndex++) {
        final revenue =
            (_monthlyRevenue[_selectedYear.toString()]?[monthIndex
                    .toString()]?['buffaloes']
                as Map?)?[buffalo['id']] ??
            0;
        yearlyTotal += revenue.toDouble();
      }
      csvContent.write('$yearlyTotal,');
      yearlyUnitTotal += yearlyTotal;
    }

    final yearlyNetRevenue = yearlyUnitTotal - cpfCost['annualCPFCost'];
    csvContent.writeln(
      '$yearlyUnitTotal,${cpfCost['annualCPFCost']},$yearlyNetRevenue',
    );

    // Share the CSV content
    await Share.share(
      csvContent.toString(),
      subject: 'Unit-$_selectedUnit-Revenue-$_selectedYear.csv',
    );
  }

  Map<String, dynamic> _calculateCPFCost(
    List<Map<String, dynamic>> unitBuffaloes,
  ) {
    final milkProducingBuffaloes = unitBuffaloes.length;
    final annualCPFCost = milkProducingBuffaloes * 13000;
    final monthlyCPFCost = (annualCPFCost / 12).round();

    return {
      'milkProducingBuffaloes': milkProducingBuffaloes,
      'annualCPFCost': annualCPFCost,
      'monthlyCPFCost': monthlyCPFCost,
    };
  }

  // Format currency
  String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  // Format number
  String formatNumber(int number) {
    return _numberFormat.format(number);
  }

  // Number to words conversion
  String numberToWords(int num) {
    if (num == 0) return 'Zero';

    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    final teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    final crore = (num / 10000000).floor();
    final lakh = ((num % 10000000) / 100000).floor();
    final thousand = ((num % 100000) / 1000).floor();
    final hundred = ((num % 1000) / 100).floor();
    final remainder = num % 100;

    String words = '';

    if (crore > 0) {
      words += '${numberToWords(crore)} Crore ';
    }

    if (lakh > 0) {
      words += '${numberToWords(lakh)} Lakh ';
    }

    if (thousand > 0) {
      words += '${numberToWords(thousand)} Thousand ';
    }

    if (hundred > 0) {
      words += '${ones[hundred]} Hundred ';
    }

    if (remainder > 0) {
      if (words.isNotEmpty) words += 'and ';

      if (remainder < 10) {
        words += ones[remainder];
      } else if (remainder < 20) {
        words += teens[remainder - 10];
      } else {
        words += tens[(remainder / 10).floor()];
        if (remainder % 10 > 0) {
          words += ' ${ones[remainder % 10]}';
        }
      }
    }

    return words.trim();
  }

  String formatPriceInWords(double amount) {
    final integerPart = amount.toInt();
    final words = numberToWords(integerPart);
    return '$words Rupees Only';
  }

  // Calculate initial investment
  Map<String, dynamic> calculateInitialInvestment() {
    final units = widget.treeData['units'] ?? 0;
    final buffaloPrice = 175000;
    final cpfPerUnit = 13000;

    final buffaloCost = units * 2 * buffaloPrice;
    final cpfCost = units * cpfPerUnit;
    final totalInvestment = buffaloCost + cpfCost;

    return {
      'buffaloCost': buffaloCost,
      'cpfCost': cpfCost,
      'totalInvestment': totalInvestment,
    };
  }

  // Calculate break-even analysis
  // Calculate break-even analysis with monthly precision
  Map<String, dynamic> calculateBreakEvenAnalysis() {
    final initialInvestment = calculateInitialInvestment();
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;

    double cumulativeRevenue = 0;
    int? breakEvenYear;
    int? breakEvenMonth;
    final List<Map<String, dynamic>> breakEvenData = [];

    // Get monthly investor revenue (you need to calculate this)
    final investorMonthlyRevenue = _calculateInvestorMonthlyRevenue();

    // Check monthly break-even
    bool foundBreakEven = false;

    for (int year = startYear; year <= startYear + years; year++) {
      if (foundBreakEven) break;

      for (int month = 0; month < 12; month++) {
        final monthlyRevenue =
            investorMonthlyRevenue[year.toString()]?[month.toString()] ?? 0;
        cumulativeRevenue += monthlyRevenue;

        if (cumulativeRevenue >= initialInvestment['totalInvestment'] &&
            !foundBreakEven) {
          breakEvenYear = year;
          breakEvenMonth = month;
          foundBreakEven = true;
          break;
        }
      }
    }

    // Yearly break-even data for table
    double yearlyCumulative = 0;

    for (int i = 0; i < yearlyData.length; i++) {
      final yearData = yearlyData[i];
      final yearRevenue = yearlyData
          .sublist(0, i + 1)
          .fold<double>(
            0,
            (sum, item) => sum + (item["revenue"] as num).toDouble(),
          );

      yearlyCumulative = yearRevenue;
      final isBreakEven = breakEvenYear == yearData['year'];

      breakEvenData.add({
        'year': yearData['year'],
        'annualRevenue': yearData['revenue'],
        'cumulativeRevenue': yearlyCumulative,
        'isBreakEven': isBreakEven,
        'totalBuffaloes': yearData['totalBuffaloes'],
        'matureBuffaloes': yearData['producingBuffaloes'],
      });
    }

    return {
      'breakEvenData': breakEvenData,
      'breakEvenYear': breakEvenYear,
      'breakEvenMonth': breakEvenMonth,
      'initialInvestment': initialInvestment['totalInvestment'],
      'finalCumulativeRevenue': cumulativeRevenue,
    };
  }

  // Calculate investor monthly revenue (shared between buffaloes)
  Map<String, Map<String, double>> _calculateInvestorMonthlyRevenue() {
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;
    final units = widget.treeData['units'] ?? 1;

    Map<String, Map<String, double>> investorMonthlyRevenue = {};

    // Initialize structure
    for (int year = startYear; year <= startYear + years; year++) {
      investorMonthlyRevenue[year.toString()] = {};
      for (int month = 0; month < 12; month++) {
        investorMonthlyRevenue[year.toString()]![month.toString()] = 0.0;
      }
    }

    // Calculate revenue based on buffalo details
    _buffaloDetails.forEach((buffaloId, buffalo) {
      final birthYear = buffalo['birthYear'] as int;
      final acquisitionMonth = buffalo['acquisitionMonth'] as int;

      for (int year = startYear; year <= startYear + years; year++) {
        if (year >= birthYear + 3) {
          // Productive at age 3
          for (int month = 0; month < 12; month++) {
            final revenue = _calculateMonthlyRevenueForBuffalo(
              acquisitionMonth,
              month,
              year,
              startYear,
            );

            // Investor gets revenue if buffalo is generating income
            if (revenue > 0) {
              investorMonthlyRevenue[year.toString()]![month.toString()] =
                  (investorMonthlyRevenue[year.toString()]![month.toString()] ??
                      0) +
                  revenue;
            }
          }
        }
      }
    });

    return investorMonthlyRevenue;
  }

  // Calculate asset market value
  List<Map<String, dynamic>> calculateAssetMarketValue() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final buffaloPrice = 175000;

    return yearlyData.map((yearData) {
      final totalBuffaloes = yearData['totalBuffaloes'] as int;
      return {
        'year': yearData['year'],
        'totalBuffaloes': totalBuffaloes,
        'assetValue': totalBuffaloes * buffaloPrice,
        'totalAssetValue': totalBuffaloes * buffaloPrice,
      };
    }).toList();
  }

  // Calculate herd statistics
  Map<String, dynamic> calculateHerdStats() {
    final units = widget.treeData['units'] ?? 0;
    final totalBuffaloes = widget.treeData['totalBuffaloes'] ?? 0;
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;
    final years = widget.treeData['years'] ?? 0;
    final totalMatureBuffaloYears =
        widget.revenueData['totalMatureBuffaloYears'] ?? 0;

    final startingBuffaloes = units * 2;
    final growthMultiple = totalBuffaloes / startingBuffaloes;
    final averageMatureBuffaloes = totalMatureBuffaloYears / years;
    final revenuePerBuffalo = totalRevenue / totalBuffaloes;

    return {
      'startingBuffaloes': startingBuffaloes,
      'finalBuffaloes': totalBuffaloes,
      'growthMultiple': growthMultiple,
      'averageMatureBuffaloes': averageMatureBuffaloes,
      'revenuePerBuffalo': revenuePerBuffalo,
    };
  }

  // Revenue Graph Widget
  Widget _buildRevenueGraph() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final List<ChartData> chartData = yearlyData.map((data) {
      return ChartData(data['year'].toString(), (data['revenue'] as num).toDouble());
    }).toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SfCartesianChart(
        title: ChartTitle(
          text: 'Revenue Trends',
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.compactCurrency(symbol: '₹'),
        ),
        series: <CartesianSeries<ChartData, String>>[
          ColumnSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Revenue',
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  // Buffalo Growth Graph Widget
  Widget _buildBuffaloGrowthGraph() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final List<ChartData> chartData = yearlyData.map((data) {
      return ChartData(
        data['year'].toString(),
        (data['totalBuffaloes'] as num).toDouble(),
      );
    }).toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SfCartesianChart(
        title: ChartTitle(
          text: 'Herd Growth',
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <CartesianSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Buffaloes',
            color: const Color(0xFF8B5CF6),
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  // Production Analysis Graph Widget
  Widget _buildProductionAnalysisGraph() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final List<ChartData> producingData = yearlyData.map((data) {
      return ChartData(
        data['year'].toString(),
        (data['totalBuffaloes'] as num).toDouble(),
      );
    }).toList();

    final List<ChartData> nonProducingData = yearlyData.map((data) {
      final total = data['totalBuffaloes'] as int;
      final producing = data['producingBuffaloes'] as int;
      return ChartData(data['year'].toString(), (total - producing).toDouble());
    }).toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SfCartesianChart(
        title: ChartTitle(
          text: 'Production Analysis',
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <CartesianSeries<ChartData, String>>[
          StackedColumnSeries<ChartData, String>(
            dataSource: producingData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Producing',
            color: const Color(0xFF10B981),
          ),
          StackedColumnSeries<ChartData, String>(
            dataSource: nonProducingData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            name: 'Non-Producing',
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  // Summary Cards Widget
  Widget _buildSummaryCards() {
    final herdStats = calculateHerdStats();
    final units = widget.treeData['units'] ?? 0;
    final years = widget.treeData['years'] ?? 0;
    final totalBuffaloes = widget.treeData['totalBuffaloes'] ?? 0;
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;

    final cards = [
      {
        'value': units.toString(),
        'label': 'Starting Units',
        'description': '${herdStats['startingBuffaloes']} initial buffaloes',
        'color': Colors.blue,
      },
      {
        'value': years.toString(),
        'label': 'Simulation Years',
        'description': 'Revenue generation period',
        'color': Colors.green,
      },
      {
        'value': totalBuffaloes.toString(),
        'label': 'Final Herd Size',
        'description':
            '${(herdStats['growthMultiple'] as double).toStringAsFixed(1)}x growth',
        'color': Colors.purple,
      },
      {
        'value': formatCurrency(totalRevenue),
        'label': 'Total Revenue',
        'description': 'From entire herd growth',
        'color': Colors.blue,
        // 'gradient': true,
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final card = cards[index];

          return Container(
            width: 365, // card width for horizontal layout
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: card['gradient'] == true ? Colors.blue : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card['value'].toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: card['gradient'] == true
                          ? Colors.white
                          : (card['color'] as Color),
                    ),
                  ),
                  // const SizedBox(height: 5),
                  Text(
                    card['label'].toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: card['gradient'] == true
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card['description'].toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: card['gradient'] == true
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyRevenueBreakdown() {
    final unitBuffaloes = _getIncomeProducingBuffaloes(
      _selectedUnit,
      _selectedYear,
    );
    final cpfCost = _calculateCPFCost(unitBuffaloes);
    final startYear = widget.treeData['startYear'] ?? DateTime.now().year;
    final years = widget.treeData['years'] ?? 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.cyan[100]!],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.blue[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 40, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Monthly Revenue - Income Producing Buffaloes Only',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Year and Unit Selection with Download Button
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 4,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Year:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[300]!),
                          ),
                        ),
                        items: List.generate(years + 1, (i) {
                          final year = startYear + i;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value!;
                          });
                        },
                      ),
                    ],
                  ),
                );
              } else if (index == 1) {
                final units = widget.treeData['units'] ?? 1;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Unit:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[300]!),
                          ),
                        ),
                        items: List.generate(units, (i) {
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text('Unit ${i + 1}'),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value!;
                          });
                        },
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: ElevatedButton(
                    onPressed: _downloadExcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[500],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Download Excel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Buffalo Family Tree
          if (unitBuffaloes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'Income Producing Buffaloes - Unit $_selectedUnit ($_selectedYear)',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 4,
                        ),
                    itemCount: unitBuffaloes
                        .where((b) => b['generation'] == 0)
                        .length,
                    itemBuilder: (context, index) {
                      final parents = unitBuffaloes
                          .where((b) => b['generation'] == 0)
                          .toList();
                      if (index >= parents.length)
                        return const SizedBox.shrink();

                      final parent = parents[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  parent['id'] as String,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[500],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Parent',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Acquisition: ${_monthNames[parent['acquisitionMonth'] as int]}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Active in $_selectedYear',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Monthly Revenue Table
          if (unitBuffaloes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'Monthly Revenue Breakdown - $_selectedYear (Unit $_selectedUnit)',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                      columns: [
                        DataColumn(
                          label: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Text(
                              'Month',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        ...unitBuffaloes.map((buffalo) {
                          return DataColumn(
                            label: Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Text(
                                    buffalo['id'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    buffalo['generation'] == 0
                                        ? 'Parent'
                                        : buffalo['generation'] == 1
                                        ? 'Child'
                                        : 'Grandchild',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        DataColumn(
                          label: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Unit Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CPF Cost',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Net Revenue',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                      rows: _monthNames.asMap().entries.map((monthEntry) {
                        final monthIndex = monthEntry.key;
                        final monthName = monthEntry.value;
                        double unitTotal = 0;

                        for (final buffalo in unitBuffaloes) {
                          final revenue =
                              (_monthlyRevenue[_selectedYear
                                      .toString()]?[monthIndex
                                      .toString()]?['buffaloes']
                                  as Map?)?[buffalo['id']] ??
                              0;
                          unitTotal += revenue.toDouble();
                        }

                        final netRevenue =
                            unitTotal - cpfCost['monthlyCPFCost'];

                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                ),
                                child: Text(
                                  monthName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            ...unitBuffaloes.map((buffalo) {
                              final revenue =
                                  (_monthlyRevenue[_selectedYear
                                          .toString()]?[monthIndex
                                          .toString()]?['buffaloes']
                                      as Map?)?[buffalo['id']] ??
                                  0;
                              Color textColor = Colors.grey;
                              String phase = 'Rest';

                              if (revenue == 9000) {
                                textColor = Colors.green;
                                phase = 'High';
                              } else if (revenue == 6000) {
                                textColor = Colors.blue;
                                phase = 'Medium';
                              }

                              return DataCell(
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: revenue == 9000
                                        ? Colors.green[50]
                                        : revenue == 6000
                                        ? Colors.blue[50]
                                        : Colors.grey[50],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatCurrency(revenue.toDouble()),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        phase,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                ),
                                child: Text(
                                  formatCurrency(unitTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                ),
                                child: Text(
                                  formatCurrency(
                                    cpfCost['monthlyCPFCost'].toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                ),
                                child: Text(
                                  formatCurrency(netRevenue),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: netRevenue >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  ),

                  // Yearly Total Row
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[800]!, Colors.grey[900]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Yearly Total',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        ...unitBuffaloes.map((buffalo) {
                          double yearlyTotal = 0;
                          for (
                            int monthIndex = 0;
                            monthIndex < _monthNames.length;
                            monthIndex++
                          ) {
                            final revenue =
                                (_monthlyRevenue[_selectedYear
                                        .toString()]?[monthIndex
                                        .toString()]?['buffaloes']
                                    as Map?)?[buffalo['id']] ??
                                0;
                            yearlyTotal += revenue.toDouble();
                          }
                          return Expanded(
                            child: Text(
                              formatCurrency(yearlyTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formatCurrency(
                                unitBuffaloes.fold<double>(0, (sum, buffalo) {
                                  double yearlyTotal = 0;
                                  for (
                                    int monthIndex = 0;
                                    monthIndex < _monthNames.length;
                                    monthIndex++
                                  ) {
                                    final revenue =
                                        (_monthlyRevenue[_selectedYear
                                                .toString()]?[monthIndex
                                                .toString()]?['buffaloes']
                                            as Map?)?[buffalo['id']] ??
                                        0;
                                    yearlyTotal += revenue.toDouble();
                                  }
                                  return sum + yearlyTotal;
                                }),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formatCurrency(
                                cpfCost['annualCPFCost'].toDouble(),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formatCurrency(
                                unitBuffaloes.fold<double>(0, (sum, buffalo) {
                                      double yearlyTotal = 0;
                                      for (
                                        int monthIndex = 0;
                                        monthIndex < _monthNames.length;
                                        monthIndex++
                                      ) {
                                        final revenue =
                                            (_monthlyRevenue[_selectedYear
                                                    .toString()]?[monthIndex
                                                    .toString()]?['buffaloes']
                                                as Map?)?[buffalo['id']] ??
                                            0;
                                        yearlyTotal += revenue.toDouble();
                                      }
                                      return sum + yearlyTotal;
                                    }) -
                                    cpfCost['annualCPFCost'],
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.yellow[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    '🐄 No Income Producing Buffaloes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'There are no income-producing buffaloes in Unit $_selectedUnit for the year $_selectedYear.',
                    style: TextStyle(fontSize: 16, color: Colors.yellow[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buffaloes start generating income at age 3 (born in ${_selectedYear - 3} or earlier).',
                    style: TextStyle(fontSize: 14, color: Colors.yellow[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Revenue Break-Even Analysis Widget
  Widget _buildRevenueBreakEvenAnalysis() {
    final breakEvenAnalysis = calculateBreakEvenAnalysis();
    final initialInvestment = calculateInitialInvestment();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple[50]!, Colors.indigo[100]!],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.purple[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_rupee, size: 40, color: Colors.purple),
              const SizedBox(width: 12),
              Text(
                'Revenue Break-Even Analysis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Initial Investment Breakdown
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3.5,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              final List<Map<String, dynamic>> investments = [
                {
                  'value': formatCurrency(initialInvestment['buffaloCost']),
                  'label': 'Buffalo Cost',
                  'description':
                      '${widget.treeData['units']} units × 2 buffaloes × ₹1.75 Lakhs',
                  'color': Colors.blue,
                },
                {
                  'value': formatCurrency(initialInvestment['cpfCost']),
                  'label': 'CPF Cost',
                  'description': '${widget.treeData['units']} units × ₹13,000',
                  'color': Colors.green,
                },
                {
                  'value': formatCurrency(initialInvestment['totalInvestment']),
                  'label': 'Total Investment',
                  'description': 'Initial Capital Outlay',
                  'color': Colors.purple,
                  'gradient': true,
                },
              ];

              final investment = investments[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: investment['gradient'] == true
                      ? Colors.purple
                      : Colors.white,
                  border: Border.all(
                    color: investment['gradient'] == true
                        ? Colors.transparent
                        : (investment['color'] as Color).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        investment['value'].toString(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: investment['gradient'] == true
                              ? Colors.white
                              : (investment['color'] as Color),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        investment['label'].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: investment['gradient'] == true
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        investment['description'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: investment['gradient'] == true
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Break-Even Result
          // Break-Even Result - Enhanced
          if (breakEvenAnalysis['breakEvenYear'] != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[500]!, Colors.green[600]!],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🎉 Break-Even Achieved!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    breakEvenAnalysis['breakEvenMonth'] != null
                        ? 'Year ${breakEvenAnalysis['breakEvenYear']} (Month ${breakEvenAnalysis['breakEvenMonth']! + 1})'
                        : 'Year ${breakEvenAnalysis['breakEvenYear']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Investment Recovery Time: ${(breakEvenAnalysis['breakEvenYear']! - (widget.treeData['startYear'] ?? DateTime.now().year))} Years ${breakEvenAnalysis['breakEvenMonth'] != null ? '${breakEvenAnalysis['breakEvenMonth']! + 1} Months' : ''}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cumulative Revenue: ${formatCurrency(breakEvenAnalysis['finalCumulativeRevenue'])}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            )
          else if (breakEvenAnalysis['finalCumulativeRevenue'] > 0)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[500]!, Colors.amber[600]!],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '📈 Break-Even Not Reached',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cumulative Revenue: ${formatCurrency(breakEvenAnalysis['finalCumulativeRevenue'])}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((breakEvenAnalysis['finalCumulativeRevenue'] / initialInvestment['totalInvestment']) * 100).toStringAsFixed(1)}% of Investment Recovered',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Break-Even Timeline Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Break-Even Timeline',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Break-Even Timeline Table - Updated
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Year')),
                      DataColumn(label: Text('Total Buffaloes')),
                      DataColumn(label: Text('Mature Buffaloes')),
                      DataColumn(label: Text('Annual Revenue')),
                      DataColumn(label: Text('Cumulative Revenue')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: (breakEvenAnalysis['breakEvenData'] as List<dynamic>)
                        .map((data) {
                          final double progress =
                              (data['cumulativeRevenue'] /
                                  initialInvestment['totalInvestment']) *
                              100;
                          String statusText = 'In Progress';
                          Color statusColor = Colors.grey;
                          Color textColor = Colors.grey[600]!;

                          if (data['isBreakEven'] == true) {
                            statusText = '✓ Break-Even';
                            statusColor = Colors.green[100]!;
                            textColor = Colors.green[800]!;
                          } else if (progress >= 75) {
                            statusText = '75% Recovered';
                            statusColor = Colors.green[50]!;
                            textColor = Colors.green[700]!;
                          } else if (progress >= 50) {
                            statusText = '50% Recovered';
                            statusColor = Colors.yellow[100]!;
                            textColor = Colors.yellow[800]!;
                          } else if (progress >= 25) {
                            statusText = '25% Recovered';
                            statusColor = Colors.blue[50]!;
                            textColor = Colors.blue[700]!;
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['year'].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Year ${(breakEvenAnalysis['breakEvenData'] as List<dynamic>).indexOf(data) + 1}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    formatNumber(data['totalBuffaloes']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    formatNumber(data['matureBuffaloes']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    formatCurrency(data['annualRevenue']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatCurrency(
                                          data['cumulativeRevenue'],
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${progress.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: progress >= 50
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: textColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        })
                        .toList(),
                  ),
                ),
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: DataTable(
                //     columns: const [
                //       DataColumn(label: Text('Year')),
                //       DataColumn(label: Text('Annual Revenue')),
                //       DataColumn(label: Text('Cumulative Revenue')),
                //       DataColumn(label: Text('Status')),
                //     ],
                //     rows: (breakEvenAnalysis['breakEvenData'] as List<dynamic>).map((
                //       data,
                //     ) {
                //       // print(data);
                //       return DataRow(
                //         cells: [
                //           DataCell(
                //             Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Text(
                //                   data['year'].toString(),
                //                   style: const TextStyle(
                //                     fontWeight: FontWeight.bold,
                //                   ),
                //                 ),
                //                 Text(
                //                   'Year ${(breakEvenAnalysis['breakEvenData'] as List<dynamic>).indexOf(data) + 1}',
                //                   style: TextStyle(color: Colors.grey[600]),
                //                 ),
                //               ],
                //             ),
                //           ),
                //           DataCell(
                //             Text(
                //               formatCurrency(data['annualRevenue']),
                //               style: const TextStyle(
                //                 fontWeight: FontWeight.bold,
                //                 color: Colors.green,
                //               ),
                //             ),
                //           ),
                //           DataCell(
                //             Text(
                //               formatCurrency(data['cumulativeRevenue']),
                //               style: const TextStyle(
                //                 fontWeight: FontWeight.bold,
                //                 color: Colors.blue,
                //               ),
                //             ),
                //           ),
                //           DataCell(
                //             Container(
                //               padding: const EdgeInsets.symmetric(
                //                 horizontal: 12,
                //                 vertical: 6,
                //               ),
                //               decoration: BoxDecoration(
                //                 color: data['isBreakEven'] == true
                //                     ? Colors.green[100]
                //                     : data['cumulativeRevenue'] >=
                //                           initialInvestment['totalInvestment'] *
                //                               0.5
                //                     ? Colors.yellow[100]
                //                     : Colors.grey[100],
                //                 borderRadius: BorderRadius.circular(20),
                //               ),
                //               child: Text(
                //                 data['isBreakEven'] == true
                //                     ? '✓ Break-Even'
                //                     : data['cumulativeRevenue'] >=
                //                           initialInvestment['totalInvestment'] *
                //                               0.5
                //                     ? '50% Recovered'
                //                     : 'In Progress',
                //                 style: TextStyle(
                //                   color: data['isBreakEven'] == true
                //                       ? Colors.green[800]
                //                       : data['cumulativeRevenue'] >=
                //                             initialInvestment['totalInvestment'] *
                //                                 0.5
                //                       ? Colors.yellow[800]
                //                       : Colors.grey[600],
                //                   fontWeight: FontWeight.bold,
                //                   fontSize: 12,
                //                 ),
                //               ),
                //             ),
                //           ),
                //         ],
                //       );
                //     }).toList(),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Asset Market Value Widget
  Widget _buildAssetMarketValue() {
    final assetMarketValue = calculateAssetMarketValue();
    final currentValue = assetMarketValue.isNotEmpty
        ? assetMarketValue[0]
        : {'totalAssetValue': 0};
    final finalValue = assetMarketValue.isNotEmpty
        ? assetMarketValue.last
        : {'totalAssetValue': 0};
    final growthMultiple =
        finalValue['totalAssetValue'] /
        (currentValue['totalAssetValue'] == 0
            ? 1
            : currentValue['totalAssetValue']);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange[50]!, Colors.red[100]!],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.orange[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, size: 40, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                'Asset Market Value Analysis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Current vs Final Asset Value
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3.5,
            ),
            itemCount: 2,
            itemBuilder: (context, index) {
              final List<Map<String, dynamic>> assets = [
                {
                  'value': formatCurrency(
                    (currentValue['totalAssetValue'] ?? 0).toDouble(),
                  ),
                  'label': 'Initial Asset Value',
                  'description':
                      '${currentValue['totalBuffaloes'] ?? 0} buffaloes × ₹1.75 Lakhs',
                  'color': Colors.blue,
                },
                {
                  'value': formatCurrency(
                    (finalValue['totalAssetValue'] ?? 0).toDouble(),
                  ),
                  'label': 'Final Asset Value',
                  'description':
                      '${finalValue['totalBuffaloes'] ?? 0} buffaloes × ₹1.75 Lakhs + CPF',
                  'color': Colors.orange,
                  'gradient': true,
                },
              ];

              final asset = assets[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: asset['gradient'] == true
                      ? Colors.orange
                      : Colors.white,
                  border: Border.all(
                    color: asset['gradient'] == true
                        ? Colors.transparent
                        : (asset['color'] as Color).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        asset['value'].toString(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: asset['gradient'] == true
                              ? Colors.white
                              : (asset['color'] as Color),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        asset['label'].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: asset['gradient'] == true
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset['description'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: asset['gradient'] == true
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Asset Growth Multiple
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Asset Growth: ${growthMultiple.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'From ${formatCurrency((currentValue['totalAssetValue'] ?? 0).toDouble())} to ${formatCurrency((finalValue['totalAssetValue'] ?? 0).toDouble())}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Yearly Asset Value Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yearly Asset Market Value',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Year')),
                      DataColumn(label: Text('Total Buffaloes')),
                      DataColumn(label: Text('Buffalo Value')),
                      DataColumn(label: Text('Total Asset Value')),
                    ],
                    rows: assetMarketValue.map((data) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['year'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Year ${assetMarketValue.indexOf(data) + 1}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              formatNumber(data['totalBuffaloes']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              formatCurrency(data['assetValue'].toDouble()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              formatCurrency(
                                data['totalAssetValue'].toDouble(),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Stats Card Widget
  Widget _buildQuickStatsCard() {
    final initialInvestment = calculateInitialInvestment();
    final breakEvenAnalysis = calculateBreakEvenAnalysis();
    final assetMarketValue = calculateAssetMarketValue();
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[500]!, Colors.purple[600]!],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch, size: 32, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                'Investment Summary',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatItem(
            'Total Investment:',
            formatCurrency(initialInvestment['totalInvestment']),
          ),
          _buildStatItem('Total Revenue:', formatCurrency(totalRevenue)),
          _buildStatItem(
            'Final Asset Value:',
            formatCurrency(
              assetMarketValue.isNotEmpty
                  ? assetMarketValue.last['totalAssetValue']
                  : 0,
            ),
          ),
          _buildStatItem(
            'Break-Even Year:',
            breakEvenAnalysis['breakEvenYear']?.toString() ?? 'Not Reached',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Production Schedule Widget
  Widget _buildProductionSchedule() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 40, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                'Staggered Revenue Distribution Schedule',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              final List<Map<String, dynamic>> phases = [
                {
                  'title': 'High Revenue Phase',
                  'value': '₹9,000',
                  'subtitle': 'per month',
                  'duration': '5 months duration',
                  'colors': [Colors.green[500]!, Colors.green[600]!],
                },
                {
                  'title': 'Medium Revenue Phase',
                  'value': '₹6,000',
                  'subtitle': 'per month',
                  'duration': '3 months duration',
                  'colors': [Colors.blue[500]!, Colors.blue[600]!],
                },
                {
                  'title': 'Rest Period',
                  'value': '₹0',
                  'subtitle': 'per month',
                  'duration': '4 months duration',
                  'colors': [Colors.grey[500]!, Colors.grey[600]!],
                },
              ];

              final phase = phases[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: phase['colors'] as List<Color>,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      phase['title'].toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      phase['value'].toString(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phase['subtitle'].toString(),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      phase['duration'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.yellow[200]!),
            ),
            child: Column(
              children: [
                Text(
                  '🎯 Staggered 6-Month Cycles | 📈 Year 1 Revenue: ₹99,000 per Unit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Each buffalo follows independent 12-month cycle: 2m rest + 5m high + 3m medium + 2m rest',
                  style: TextStyle(fontSize: 18, color: Colors.yellow[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Revenue Table Widget
  Widget _buildRevenueTable() {
    final yearlyData = widget.revenueData['yearlyData'] as List<dynamic>;
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;
    final totalMatureBuffaloYears =
        widget.revenueData['totalMatureBuffaloYears'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[600]!,
                  Colors.purple[600]!,
                  Colors.indigo[600]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Annual Herd Revenue Breakdown',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Detailed year-by-year financial analysis based on actual herd growth with staggered cycles',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue[100],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Year')),
                  DataColumn(label: Text('Total\nBuffaloes')),
                  DataColumn(label: Text('Mature\nBuffaloes')),
                  DataColumn(label: Text('Annual\nRevenue')),
                  DataColumn(label: Text('Cumulative\nRevenue')),
                ],
                rows: yearlyData.map((data) {
                  final index = yearlyData.indexOf(data);
                  final cumulativeRevenue = yearlyData
                      .sublist(0, index + 1)
                      .fold(
                        0.0,
                        (sum, item) => sum + (item['revenue'] as num).toDouble(),
                      );
                  final growthRate = index > 0
                      ? ((data['revenue'] - (yearlyData[index - 1])['revenue']) /
                                (yearlyData[index - 1])['revenue'] *
                                100)
                            .toStringAsFixed(1)
                      : '0.0';

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: 120,
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[500]!,
                                      Colors.purple[600]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    data['year'].toString(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Year ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              formatNumber(data['totalBuffaloes']),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            Text(
                              'total buffaloes',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              formatNumber(data['producingBuffaloes']),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'mature buffaloes',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              formatCurrency(data['revenue'].toDouble()),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (double.parse(growthRate) > 0)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_upward,
                                    size: 20,
                                    color: Colors.green,
                                  ),
                                  Text(
                                    '$growthRate% growth',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              formatCurrency(cumulativeRevenue),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            Text(
                              '${((cumulativeRevenue / totalRevenue) * 100).toStringAsFixed(1)}% of total',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[800]!, Colors.grey[900]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.treeData['years']} Years',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      formatNumber(
                        yearlyData.isNotEmpty
                            ? yearlyData.last['totalBuffaloes']
                            : 0,
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'final herd size',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      formatNumber(totalMatureBuffaloYears),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'mature buffalo years',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      formatCurrency(totalRevenue),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'total revenue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      formatCurrency(totalRevenue),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'final cumulative',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Additional Information Widget
  Widget _buildAdditionalInformation() {
    final initialInvestment = calculateInitialInvestment();
    final breakEvenAnalysis = calculateBreakEvenAnalysis();
    final assetMarketValue = calculateAssetMarketValue();
    final herdStats = calculateHerdStats();
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.yellow[50]!, Colors.orange[50]!],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.yellow[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          size: 40,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Investment Highlights',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ...[
                      {
                        'title': 'Initial Investment',
                        'description':
                            '${formatCurrency(initialInvestment['totalInvestment'])} (Buffaloes: ${formatCurrency(initialInvestment['buffaloCost'])} + CPF: ${formatCurrency(initialInvestment['cpfCost'])})',
                      },
                      {
                        'title': 'Break-Even Point',
                        'description':
                            breakEvenAnalysis['breakEvenYear'] != null
                            ? 'Year ${breakEvenAnalysis['breakEvenYear']}'
                            : 'Not reached within simulation period',
                      },
                      {
                        'title': 'Asset Growth',
                        'description':
                            '${((assetMarketValue.isNotEmpty ? assetMarketValue.last['totalAssetValue'] : 0) / (assetMarketValue.isNotEmpty ? assetMarketValue[0]['totalAssetValue'] : 1)).toStringAsFixed(1)}x growth in ${widget.treeData['years']} years',
                      },
                      {
                        'title': 'Total Returns',
                        'description':
                            'Revenue: ${formatCurrency(totalRevenue)} + Final Assets: ${formatCurrency(assetMarketValue.isNotEmpty ? assetMarketValue.last['totalAssetValue'] : 0)}',
                      },
                      {
                        'title': 'Herd Growth',
                        'description':
                            '${(herdStats['growthMultiple'] as double).toStringAsFixed(1)}x herd growth (${herdStats['startingBuffaloes']} → ${widget.treeData['totalBuffaloes']} buffaloes)',
                      },
                    ].asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.yellow[100]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.yellow[500],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value['title'].toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.value['description'].toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.orange[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[50]!, Colors.cyan[50]!],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.blue[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 40,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Financial Performance',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 3.5,
                          ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final List<Map<String, dynamic>> stats = [
                          {
                            'value': formatCurrency(
                              totalRevenue / (widget.treeData['years'] ?? 1),
                            ),
                            'label': 'Average Annual Revenue',
                            'color': Colors.blue,
                          },
                          {
                            'value': formatCurrency(
                              herdStats['revenuePerBuffalo'],
                            ),
                            'label': 'Revenue per Buffalo',
                            'color': Colors.green,
                          },
                          {
                            'value':
                                '${(herdStats['growthMultiple'] as double).toStringAsFixed(1)}x',
                            'label': 'Herd Growth Multiple',
                            'color': Colors.purple,
                          },
                          {
                            'value': formatCurrency(
                              (totalRevenue +
                                      (assetMarketValue.isNotEmpty
                                          ? assetMarketValue
                                                .last['totalAssetValue']
                                          : 0)) /
                                  initialInvestment['totalInvestment'],
                            ),
                            'label': 'ROI Multiple',
                            'color': Colors.orange,
                          },
                        ];

                        final stat = stats[index];
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (stat['color'] as Color).withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stat['value'].toString(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: stat['color'] as Color,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                stat['label'].toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: (stat['color'] as Color),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Graph Navigation Widget
  Widget _buildGraphNavigation() {
    final List<Map<String, dynamic>> buttons = [
      {'key': 'revenue', 'label': '💰 Revenue Trends', 'color': Colors.green},
      {'key': 'buffaloes', 'label': '🐃 Herd Growth', 'color': Colors.purple},
      {
        'key': 'nonproducing',
        'label': '📊 Production Analysis',
        'color': Colors.orange,
      },
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: buttons.map((button) {
        final isActive = _activeGraph == button['key'];
        return ElevatedButton(
          onPressed: () {
            setState(() {
              _activeGraph = button['key'];
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? button['color'] : Colors.grey[100],
            foregroundColor: isActive ? Colors.white : Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isActive
                    ? (button['color'] as Color).withOpacity(0.3)
                    : Colors.grey[300]!,
                width: 4,
              ),
            ),
            elevation: isActive ? 8 : 4,
          ),
          child: Text(button['label']),
        );
      }).toList(),
    );
  }

  // Graphs Section Widget
  Widget _buildGraphsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 64),
          Text(
            'Herd Performance Analytics',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Graph Navigation
          _buildGraphNavigation(),
          const SizedBox(height: 40),

          // Graph Display
          if (_activeGraph == 'revenue') _buildRevenueGraph(),
          if (_activeGraph == 'buffaloes') _buildBuffaloGrowthGraph(),
          if (_activeGraph == 'nonproducing') _buildProductionAnalysisGraph(),
        ],
      ),
    );
  }

  // Section Tabs after Summary Cards
  Widget _buildSectionTabs() {
    final List<Map<String, dynamic>> sections = [
      {
        'key': 'monthly',
        'label': 'Monthly Revenue Breakdown',
        'color': Colors.blue,
      },
      {
        'key': 'revenue_breakdown',
        'label': 'Revenue Break-Even',
        'color': Colors.purple,
      },
      {
        'key': 'asset_market',
        'label': 'Asset Market Value',
        'color': Colors.orange,
      },
      {
        'key': 'herd_performance',
        'label': 'Herd Performance',
        'color': Colors.green,
      },
      {
        'key': 'staggered_schedule',
        'label': 'Break-Even',
        'color': Colors.yellow[700],
      },
      {
        'key': 'annual_revenue',
        'label': 'Annual herd revenue',
        'color': Colors.indigo,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: sections.map((s) {
          final isSelected = selectedSection == s['key'];
          return GestureDetector(
            onTap: () =>
                setState(() => selectedSection = isSelected ? 'all' : s['key']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (s['color'] as Color).withOpacity(0.85)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (s['color'] as Color).withOpacity(0.9),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : s['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Price in Words Widget
  Widget _buildPriceInWords() {
    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;
    final assetMarketValue = calculateAssetMarketValue();
    final finalAssetValue = assetMarketValue.isNotEmpty
        ? assetMarketValue.last['totalAssetValue']
        : 0;
    final totalReturns = totalRevenue + finalAssetValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[500]!, Colors.purple[600]!],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Investment Returns in Words',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              formatPriceInWords(totalReturns),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '(Revenue: ${formatCurrency(totalRevenue)} + Final Assets: ${formatCurrency(finalAssetValue)})',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showCostEstimation) {
      Navigator.of(context).pop();
    }

    final totalRevenue = widget.revenueData['totalRevenue'] ?? 0;
    final units = widget.treeData['units'] ?? 0;
    final years = widget.treeData['years'] ?? 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[50]!, Colors.grey[50]!],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header
                Text(
                  'Buffalo Herd Investment Analysis',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Summary Cards
                _buildSummaryCards(),

                const SizedBox(height: 40),

                // Section Cards
                _buildSectionTabs(),

                const SizedBox(height: 12),

                if (selectedSection == 'all' ||
                    selectedSection == 'monthly') ...[
                  _buildMonthlyRevenueBreakdown(),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'revenue_breakdown') ...[
                  _buildRevenueBreakEvenAnalysis(),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'asset_market') ...[
                  _buildAssetMarketValue(),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'herd_performance') ...[
                  _buildGraphsSection(),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'staggered_schedule') ...[
                  _buildProductionSchedule(),
                  const SizedBox(height: 40),
                ],

                if (selectedSection == 'all' ||
                    selectedSection == 'annual_revenue') ...[
                  _buildRevenueTable(),
                  const SizedBox(height: 40),
                ],

                const SizedBox(height: 40),

                // Additional Information
                // _buildAdditionalInformation(),
                const SizedBox(height: 40),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[500],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 12),
                          Text('Back to Family Tree'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final csvBuffer = StringBuffer();
                        csvBuffer.writeln(
                          'Year,TotalBuffaloes,ProducingBuffaloes,Revenue',
                        );
                        final yearlyData =
                            widget.revenueData['yearlyData'] as List<dynamic>;
                        for (final y in yearlyData) {
                          csvBuffer.writeln(
                            '${y['year']},${y['totalBuffaloes']},${y['matureBuffaloes']},${y['revenue']}',
                          );
                        }
                        final csvString = csvBuffer.toString();
                        await Share.share(csvString, subject: 'Revenue CSV');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[500],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 12),
                          Text('Share Revenue CSV'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class for chart data
class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}
