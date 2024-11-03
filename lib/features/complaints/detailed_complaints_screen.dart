// lib/features/complaints/detailed_complaints_screen.dart

import 'package:flutter/material.dart';

class DetailedComplaintsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> complaints;
  final String make;
  final String model;
  final int year;

  const DetailedComplaintsScreen({
    super.key,
    required this.complaints,
    required this.make,
    required this.model,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${year} ${make} ${model}\nDetailed Complaints'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: complaints.length,
        itemBuilder: (context, index) {
          final complaint = complaints[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Component
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      complaint['components']?.toString() ?? 'Unknown Component',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Crash/Fire Indicators
                  if (complaint['crash'] == true || complaint['fire'] == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          if (complaint['crash'] == true)
                            Chip(
                              label: const Text('Crash'),
                              backgroundColor: Colors.red.shade100,
                              labelStyle: TextStyle(color: Colors.red.shade900),
                            ),
                          if (complaint['crash'] == true && complaint['fire'] == true)
                            const SizedBox(width: 8),
                          if (complaint['fire'] == true)
                            Chip(
                              label: const Text('Fire'),
                              backgroundColor: Colors.orange.shade100,
                              labelStyle: TextStyle(color: Colors.orange.shade900),
                            ),
                        ],
                      ),
                    ),

                  // Description
                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      complaint['summary']?.toString() ??
                          complaint['complaintDescription']?.toString() ??
                          complaint['complaintText']?.toString() ??
                          complaint['complaintDesc']?.toString() ??
                          'No description available'
                  ),

                  const SizedBox(height: 8),

                  // Date
                  if (complaint['dateOfComplaint'] != null)
                    Text(
                      'Date: ${complaint['dateOfComplaint']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}