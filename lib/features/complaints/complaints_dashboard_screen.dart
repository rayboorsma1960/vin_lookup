// lib/features/complaints/complaints_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'complaints_charts.dart';
import 'detailed_complaints_screen.dart';

class ComplaintsDashboardScreen extends StatefulWidget {
  final String make;
  final String model;
  final int year;

  const ComplaintsDashboardScreen({
    super.key,
    required this.make,
    required this.model,
    required this.year,
  });

  @override
  State<ComplaintsDashboardScreen> createState() => _ComplaintsDashboardScreenState();
}

class _ComplaintsDashboardScreenState extends State<ComplaintsDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = _fetchComplaints();
  }

  Future<List<Map<String, dynamic>>> _fetchComplaints() async {
    try {
      final encodedMake = Uri.encodeComponent(widget.make);
      final encodedModel = Uri.encodeComponent(widget.model);
      final url = 'https://api.nhtsa.gov/complaints/complaintsByVehicle'
          '?make=$encodedMake&model=$encodedModel&modelYear=${widget.year}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['count'] > 0 && data['results'] is List) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load complaints: $e');
    }
  }

  Map<String, dynamic> _generateInsights(List<Map<String, dynamic>> complaints) {
    final componentCounts = <String, int>{};
    for (var complaint in complaints) {
      final component = complaint['components']?.toString() ?? 'Unknown';
      componentCounts[component] = (componentCounts[component] ?? 0) + 1;
    }

    final sortedComponents = componentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalComplaints = complaints.length;
    final crashCount = complaints.where((c) => c['crash'] == true).length;
    final fireCount = complaints.where((c) => c['fire'] == true).length;
    final safetyRate = totalComplaints > 0
        ? ((crashCount + fireCount) / totalComplaints * 100)
        : 0.0;

    final majorConcerns = sortedComponents.take(3).map((e) => {
      'component': e.key,
      'count': e.value,
      'percentage': totalComplaints > 0
          ? (e.value / totalComplaints * 100).toStringAsFixed(1)
          : '0.0',
    }).toList();

    return {
      'topIssues': majorConcerns,
      'safetyIncidents': {
        'crashes': crashCount,
        'fires': fireCount,
        'rate': safetyRate.toStringAsFixed(1),
      },
      'totalComplaints': totalComplaints,
    };
  }

  Widget _buildInsightsSection(Map<String, dynamic> insights, List<Map<String, dynamic>> complaints) {
    return Column(
      children: [
        ComplaintsCharts(complaints: complaints),

        // Safety Insights Card
        Card(
          elevation: 2,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Based on ${insights['totalComplaints']} total reports:',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Safety Incidents Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade900),
                          const SizedBox(width: 8),
                          Text(
                            'Safety Incidents',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crashes: ${insights['safetyIncidents']['crashes']}',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                      Text(
                        'Fires: ${insights['safetyIncidents']['fires']}',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                      Text(
                        'Safety Incident Rate: ${insights['safetyIncidents']['rate']}%',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Owner Advisory Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade900),
                          const SizedBox(width: 8),
                          Text(
                            'Owner Advisory',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (insights['topIssues'].isNotEmpty)
                        Text(
                          'Pay special attention to the ${(insights['topIssues'] as List).first['component'].toString().toLowerCase()} '
                              'system, as it accounts for ${(insights['topIssues'] as List).first['percentage']}% of all complaints. '
                              'Regular maintenance and early attention to warning signs in these areas may help prevent serious issues.',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailedComplaintsScreen(
                            complaints: complaints,
                            make: widget.make,
                            model: widget.model,
                            year: widget.year,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('View Detailed Complaints'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.year} ${widget.make} ${widget.model}\nReliability Insights'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading complaints:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _complaintsFuture = _fetchComplaints();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No complaints found for this vehicle'),
            );
          }

          return SingleChildScrollView(
            child: _buildInsightsSection(
                _generateInsights(snapshot.data!),
                snapshot.data!
            ),
          );
        },
      ),
    );
  }
}