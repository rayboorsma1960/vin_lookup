// lib/screens/complaints/complaints_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/complaints_dashboard_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.year} ${widget.make} ${widget.model}\nComplaints'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ComplaintsDashboardWidget(
                complaints: snapshot.data!,
                showFullList: true,
              ),
            ),
          );
        },
      ),
    );
  }
}