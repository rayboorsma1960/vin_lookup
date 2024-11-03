// lib/widgets/complaints_dashboard_widget.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ComplaintsDashboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> complaints;
  final bool showFullList;

  const ComplaintsDashboardWidget({
    super.key,
    required this.complaints,
    this.showFullList = true,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _calculateSummary();
    final size = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewSection(summary, isSmallScreen),
                const SizedBox(height: 16),
                isPortrait
                    ? _buildVerticalLayout(summary, size, isSmallScreen)
                    : _buildHorizontalLayout(summary, size, isSmallScreen),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewSection(Map<String, dynamic> summary, bool isSmallScreen) {
    return GridView.count(
      crossAxisCount: isSmallScreen ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: isSmallScreen ? 1.1 : 1.3,
      children: [
        _buildStatCard(
          'Total Complaints',
          summary['totalComplaints'].toString(),
          Colors.blue,
          Icons.topic,
          isSmallScreen,
        ),
        _buildStatCard(
          'Safety Issues',
          '${summary['crashCount']} crashes\n${summary['fireCount']} fires',
          Colors.red,
          Icons.warning_amber,
          isSmallScreen,
        ),
        _buildStatCard(
          'Injuries & Deaths',
          '${summary['totalInjuries']} inj.\n${summary['totalDeaths']} deaths',
          Colors.orange,
          Icons.local_hospital,
          isSmallScreen,
        ),
        _buildStatCard(
          'Incident Rate',
          '${((summary['incidentRate'] * 100).toStringAsFixed(1))}%',
          Colors.purple,
          Icons.assessment,
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(Map<String, dynamic> summary, Size size, bool isSmallScreen) {
    return Column(
      children: [
        _buildChartSection(summary, size, isSmallScreen),
        if (showFullList) ...[
          const SizedBox(height: 16),
          _buildDetailedList(summary, isSmallScreen),
        ],
      ],
    );
  }

  Widget _buildHorizontalLayout(Map<String, dynamic> summary, Size size, bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildChartSection(summary, size, isSmallScreen),
        ),
        if (showFullList) ...[
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildDetailedList(summary, isSmallScreen),
          ),
        ],
      ],
    );
  }

  Widget _buildChartSection(Map<String, dynamic> summary, Size size, bool isSmallScreen) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, isSmallScreen ? 8.0 : 16.0,
            isSmallScreen ? 8.0 : 16.0,
            isSmallScreen ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Most Reported Issues',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Top ${summary['componentData'].length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: size.height * (isSmallScreen ? 0.3 : 0.35),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth < 200
                      ? _buildSimpleBarList(summary)
                      : _buildBarChart(summary, constraints);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> summary, BoxConstraints constraints) {
    final isVerySmall = constraints.maxWidth < 300;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (summary['maxComponentCount'] as int) * 1.2,
        barGroups: _generateBarGroups(summary['componentData'] as List<Map<String, dynamic>>),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= (summary['componentData'] as List).length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      (summary['componentData'] as List)[value.toInt()]['name'],
                      style: TextStyle(
                        fontSize: isVerySmall ? 8 : 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
              reservedSize: isVerySmall ? 20 : 30,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<Map<String, dynamic>> componentData) {
    final List<Color> barColors = [
      Colors.blue.shade700,
      Colors.blue.shade600,
      Colors.blue.shade500,
      Colors.blue.shade400,
      Colors.blue.shade300,
    ];

    return List.generate(
      componentData.length,
          (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (componentData[index]['count'] as int).toDouble(),
            color: barColors[index],
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: (componentData[index]['count'] as int).toDouble(),
              color: Colors.transparent,
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      ),
    );
  }

  Widget _buildSimpleBarList(Map<String, dynamic> summary) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: (summary['componentData'] as List).length,
      itemBuilder: (context, index) {
        final component = (summary['componentData'] as List)[index];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  component['name'],
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  component['count'].toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedList(Map<String, dynamic> summary, bool isSmallScreen) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Component Breakdown',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(summary['componentData'] as List<Map<String, dynamic>>).map((component) {
              final percentage = (component['count'] as int) / (summary['totalComplaints'] as int);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            component['fullName'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (component['count'] as int).toString(),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.blue.shade50,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}% of total',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, MaterialColor color, IconData icon, bool isSmallScreen) {
    return Card(
      elevation: 1,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 11,
                color: color.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateSummary() {
    final totalComplaints = complaints.length;
    final crashCount = complaints.where((c) => c['crash'] == true).length;
    final fireCount = complaints.where((c) => c['fire'] == true).length;

    final totalInjuries = complaints.fold<int>(
      0,
          (sum, c) => sum + ((c['numberOfInjuries'] as num?)?.toInt() ?? 0),
    );
    final totalDeaths = complaints.fold<int>(
      0,
          (sum, c) => sum + ((c['numberOfDeaths'] as num?)?.toInt() ?? 0),
    );

    final componentCounts = <String, int>{};
    for (var complaint in complaints) {
      final component = complaint['components']?.toString() ?? 'UNKNOWN';
      componentCounts[component] = (componentCounts[component] ?? 0) + 1;
    }

    final sortedComponents = componentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topComponents = sortedComponents.take(5).map((e) => {
      'name': e.key.length > 15 ? '${e.key.substring(0, 12)}...' : e.key,
      'fullName': e.key,
      'count': e.value,
    }).toList();

    return {
      'totalComplaints': totalComplaints,
      'crashCount': crashCount,
      'fireCount': fireCount,
      'totalInjuries': totalInjuries,
      'totalDeaths': totalDeaths,
      'incidentRate': (crashCount + fireCount) / totalComplaints,
      'componentData': topComponents,
      'maxComponentCount': topComponents.isNotEmpty ? topComponents.first['count'] : 0,
    };
  }
}