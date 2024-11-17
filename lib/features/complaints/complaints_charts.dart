// lib/features/complaints/complaints_charts.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ComplaintsCharts extends StatelessWidget {
  final List<Map<String, dynamic>> complaints;

  const ComplaintsCharts({super.key, required this.complaints});

  Map<String, List<ComplaintDetail>> _analyzeComplaints() {
    debugPrint('\n=== Analyzing ${complaints.length} complaints ===');

    final Map<String, List<ComplaintDetail>> categoryData = {
      'Brakes': [],
      'Air Bags': [],
      'Transmission': [],
      'Electrical': [],
      'Steering': [],
      'Seat Belts': [],
      'Engine': [],
      'Structure': [],
      'Fuel System': [],
      'Suspension': [],
    };

    for (var complaint in complaints) {
      final component = complaint['components']?.toString().toLowerCase() ?? 'unknown';
      final description = complaint['complaintDesc']?.toString() ??
          complaint['description']?.toString() ??
          complaint['complaintDescription']?.toString() ??
          complaint['complaintText']?.toString() ??
          complaint['summary']?.toString() ?? '';

      if (component.contains('brake') || component.contains('abs')) {
        categoryData['Brakes']!.add(ComplaintDetail(description));
      } else if (component.contains('air bag') || component.contains('airbag')) {
        categoryData['Air Bags']!.add(ComplaintDetail(description));
      } else if (component.contains('transmission') || component.contains('gear')) {
        categoryData['Transmission']!.add(ComplaintDetail(description));
      } else if (component.contains('electrical') || component.contains('wiring')) {
        categoryData['Electrical']!.add(ComplaintDetail(description));
      } else if (component.contains('steering')) {
        categoryData['Steering']!.add(ComplaintDetail(description));
      } else if (component.contains('seat belt') || component.contains('seatbelt')) {
        categoryData['Seat Belts']!.add(ComplaintDetail(description));
      } else if (component.contains('engine')) {
        categoryData['Engine']!.add(ComplaintDetail(description));
      } else if (component.contains('structure') || component.contains('frame') || component.contains('body')) {
        categoryData['Structure']!.add(ComplaintDetail(description));
      } else if (component.contains('fuel')) {
        categoryData['Fuel System']!.add(ComplaintDetail(description));
      } else if (component.contains('suspension')) {
        categoryData['Suspension']!.add(ComplaintDetail(description));
      }
    }

    // Print final counts
    categoryData.forEach((key, value) {
      if (value.isNotEmpty) {
        debugPrint('$key: ${value.length} complaints');
      }
    });

    return categoryData;
  }

  Widget _buildBarChart(Map<String, List<ComplaintDetail>> categoryData) {
    final complaintCounts = categoryData.map((key, value) =>
        MapEntry(key, value.length)).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: complaintCounts.map((e) => e.value.toDouble()).reduce(
                    (a, b) => a > b ? a : b) * 1.2,
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= complaintCounts.length) return const Text('');
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Transform.rotate(
                        angle: -0.785398, // 45 degrees
                        child: Text(
                          complaintCounts[value.toInt()].key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                  reservedSize: 70,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
                left: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            gridData: FlGridData(
              show: true,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            barGroups: List.generate(
              complaintCounts.length,
                  (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: complaintCounts[index].value.toDouble(),
                    color: Colors.blue.shade400,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  List<ProblemSummary> _getCategoryProblems(String category, List<ComplaintDetail> complaints) {
    debugPrint('\nAnalyzing ${complaints.length} complaints for $category');

    switch (category) {
      case 'Air Bags':
        final patterns = {
          'Non-deployment in Accident': (String desc) =>
          desc.toLowerCase().contains('not deploy') ||
              desc.toLowerCase().contains('failed to deploy') ||
              desc.toLowerCase().contains('no deployment') ||
              desc.toLowerCase().contains('did not deploy') ||
              desc.toLowerCase().contains('didn\'t deploy'),
          'Unexpected Deployment': (String desc) =>
          desc.toLowerCase().contains('unexpected') ||
              desc.toLowerCase().contains('without impact') ||
              desc.toLowerCase().contains('unintended') ||
              desc.toLowerCase().contains('deployed unexpectedly'),
          'Deployment Injuries': (String desc) =>
          desc.toLowerCase().contains('injury') ||
              desc.toLowerCase().contains('burn') ||
              desc.toLowerCase().contains('chemical') ||
              desc.toLowerCase().contains('hurt'),
        };
        return _analyzePatternsForCategory(complaints, patterns);

      case 'Brakes':
        final patterns = {
          'ABS System Failure': (String desc) =>
          desc.toLowerCase().contains('abs') ||
              desc.toLowerCase().contains('anti-lock') ||
              desc.toLowerCase().contains('antilock'),
          'Extended Stopping Distance': (String desc) =>
          desc.toLowerCase().contains('stopping distance') ||
              desc.toLowerCase().contains('pedal') ||
              desc.toLowerCase().contains('soft') ||
              desc.toLowerCase().contains('long distance') ||
              desc.toLowerCase().contains('won\'t stop'),
          'Premature Wear': (String desc) =>
          desc.toLowerCase().contains('wear') ||
              desc.toLowerCase().contains('rotor') ||
              desc.toLowerCase().contains('pad') ||
              desc.toLowerCase().contains('early replacement'),
        };
        return _analyzePatternsForCategory(complaints, patterns);

      case 'Electrical':
        final patterns = {
          'Electrical Failures': (String desc) =>
          desc.toLowerCase().contains('electrical') ||
              desc.toLowerCase().contains('short') ||
              desc.toLowerCase().contains('failure') ||
              desc.toLowerCase().contains('malfunction'),
          'Warning Lights': (String desc) =>
          desc.toLowerCase().contains('light') ||
              desc.toLowerCase().contains('warning') ||
              desc.toLowerCase().contains('indicator') ||
              desc.toLowerCase().contains('dashboard'),
          'Battery Issues': (String desc) =>
          desc.toLowerCase().contains('battery') ||
              desc.toLowerCase().contains('charging') ||
              desc.toLowerCase().contains('power') ||
              desc.toLowerCase().contains('dead'),
        };
        return _analyzePatternsForCategory(complaints, patterns);

      case 'Steering':
        final patterns = {
          'Power Steering Issues': (String desc) =>
          desc.toLowerCase().contains('power steering') ||
              desc.toLowerCase().contains('assist') ||
              desc.toLowerCase().contains('fluid') ||
              desc.toLowerCase().contains('pump') ||
              desc.toLowerCase().contains('hard to steer') ||
              desc.toLowerCase().contains('heavy') ||
              desc.toLowerCase().contains('difficult to turn'),
          'Steering Lock': (String desc) =>
          desc.toLowerCase().contains('lock') ||
              desc.toLowerCase().contains('stuck') ||
              desc.toLowerCase().contains('frozen') ||
              desc.toLowerCase().contains('won\'t turn') ||
              desc.toLowerCase().contains('seize') ||
              desc.toLowerCase().contains('jammed'),
          'Control Problems': (String desc) =>
          desc.toLowerCase().contains('control') ||
              desc.toLowerCase().contains('drift') ||
              desc.toLowerCase().contains('pull') ||
              desc.toLowerCase().contains('wander') ||
              desc.toLowerCase().contains('alignment') ||
              desc.toLowerCase().contains('vibration') ||
              desc.toLowerCase().contains('shake') ||
              desc.toLowerCase().contains('noise') ||
              desc.toLowerCase().contains('loose'),
        };
        return _analyzePatternsForCategory(complaints, patterns);

      case 'Engine':
        final patterns = {
          'Stalling Issues': (String desc) =>
          desc.toLowerCase().contains('stall') ||
              desc.toLowerCase().contains('dies') ||
              desc.toLowerCase().contains('shut off'),
          'Engine Failure': (String desc) =>
          desc.toLowerCase().contains('failure') ||
              desc.toLowerCase().contains('seized') ||
              desc.toLowerCase().contains('blown'),
          'Oil Consumption': (String desc) =>
          desc.toLowerCase().contains('oil') ||
              desc.toLowerCase().contains('burning') ||
              desc.toLowerCase().contains('consumption'),
        };
        return _analyzePatternsForCategory(complaints, patterns);

      case 'Structure':
        final patterns = {
          'Body Integrity': (String desc) =>
          desc.toLowerCase().contains('rust') ||
              desc.toLowerCase().contains('corrosion') ||
              desc.toLowerCase().contains('deterioration'),
          'Door Issues': (String desc) =>
          desc.toLowerCase().contains('door') ||
              desc.toLowerCase().contains('latch') ||
              desc.toLowerCase().contains('hinge'),
          'Frame Problems': (String desc) =>
          desc.toLowerCase().contains('frame') ||
              desc.toLowerCase().contains('structural') ||
              desc.toLowerCase().contains('crack'),
        };
        return _analyzePatternsForCategory(complaints, patterns);

      case 'Fuel System':
        final patterns = {
          'Fuel Leaks': (String desc) =>
          desc.toLowerCase().contains('leak') ||
              desc.toLowerCase().contains('seep') ||
              desc.toLowerCase().contains('smell'),
          'Fuel Pump Issues': (String desc) =>
          desc.toLowerCase().contains('pump') ||
              desc.toLowerCase().contains('pressure') ||
              desc.toLowerCase().contains('delivery'),
          'Tank Problems': (String desc) =>
          desc.toLowerCase().contains('tank') ||
              desc.toLowerCase().contains('gauge') ||
              desc.toLowerCase().contains('capacity'),
        };
        return _analyzePatternsForCategory(complaints, patterns);

      default:
        return [ProblemSummary('General Issues', complaints.length)];
    }
  }

  List<ProblemSummary> _analyzePatternsForCategory(
      List<ComplaintDetail> complaints,
      Map<String, bool Function(String)> patterns) {

    final problemCounts = <String, int>{};

    for (var complaint in complaints) {
      for (var pattern in patterns.entries) {
        if (pattern.value(complaint.description)) {
          problemCounts[pattern.key] = (problemCounts[pattern.key] ?? 0) + 1;
        }
      }
    }

    if (problemCounts.isEmpty) {
      return [ProblemSummary('General Issues', complaints.length)];
    }

    final sortedProblems = problemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedProblems.take(3).map((e) =>
        ProblemSummary(e.key, e.value)).toList();
  }

  String _getProblemDescription(String category, String problem) {
    final descriptions = {
      // Air Bags
      'Non-deployment in Accident': 'Airbags failed to deploy in frontal collisions',
      'Unexpected Deployment': 'Airbags deployed without impact or in minor incidents',
      'Deployment Injuries': 'Injuries caused by airbag deployment force or chemical burns',

      // Brakes
      'ABS System Failure': 'Complete failure or malfunction of ABS system, often during adverse weather or emergency braking',
      'Extended Stopping Distance': 'Vehicle requires unusually long distance to stop, brake pedal feels soft or goes to floor',
      'Premature Wear': 'Rotors, pads, and calipers wearing out much earlier than expected',

      // Electrical
      'Electrical Failures': 'Problems with vehicle electrical systems including shorts and system failures',
      'Warning Lights': 'Issues with dashboard warning lights and indicators',
      'Battery Issues': 'Problems with battery performance, charging, or premature failure',

      // Steering
      'Power Steering Issues': 'Problems with power steering system including loss of assist, fluid leaks, or pump failures',
      'Steering Lock': 'Steering wheel becomes difficult to turn or locks up while driving',
      'Control Problems': 'Issues with vehicle control including pulling, drifting, vibration, or alignment problems',

      // Engine
      'Stalling Issues': 'Engine stalls while driving or fails to maintain idle',
      'Engine Failure': 'Complete engine failure requiring major repair or replacement',
      'Oil Consumption': 'Excessive oil consumption requiring frequent additions',

      // Structure
      'Body Integrity': 'Issues with body panels, rust, or structural integrity',
      'Door Issues': 'Problems with door mechanisms, latches, or hinges',
      'Frame Problems': 'Structural issues with the vehicle frame',

      // Fuel System
      'Fuel Leaks': 'Fuel system leaks or fuel odors',
      'Fuel Pump Issues': 'Problems with fuel delivery or pump operation',
      'Tank Problems': 'Issues with fuel tank or fuel gauge accuracy',

      // General
      'General Issues': 'Various reported problems within this category',
    };

    return descriptions[problem] ?? 'Specific issues related to $problem in the $category system';
  }

  Widget _buildDetailedBreakdown(Map<String, List<ComplaintDetail>> categoryData) {
    final topCategories = categoryData.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topCategories.map((category) {
        final problems = _getCategoryProblems(category.key, category.value);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.key} (Total: ${category.value.length} complaints)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...problems.map((problem) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${problem.name} (${problem.count} cases)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _getProblemDescription(category.key, problem.name),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = _analyzeComplaints();

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complaint Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildBarChart(categoryData),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Problems by Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailedBreakdown(categoryData),
            ],
          ),
        ),
      ],
    );
  }
}

class ComplaintDetail {
  final String description;
  ComplaintDetail(this.description);
}

class ProblemSummary {
  final String name;
  final int count;
  ProblemSummary(this.name, this.count);
}