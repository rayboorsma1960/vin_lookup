// feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _feedbackController = TextEditingController();
  static final _log = Logger('FeedbackScreen');
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  const Icon(
                    Icons.feedback,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We Value Your Feedback',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your feedback helps us improve the app for everyone',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Your Email (Optional)',
                      hintText: 'Enter your email for us to respond',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    enabled: !_isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        // Simple email validation
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Feedback Input
                  TextFormField(
                    controller: _feedbackController,
                    decoration: InputDecoration(
                      labelText: 'Your Feedback',
                      hintText: 'Tell us what you think or suggest improvements',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(16),
                      alignLabelWithHint: true,
                    ),
                    enabled: !_isSubmitting,
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your feedback';
                      }
                      if (value.trim().length < 10) {
                        return 'Please provide more detailed feedback';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    icon: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? 'Sending...' : 'Send Feedback'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String emailSubject = 'App Feedback';
      final String emailBody = _feedbackController.text;
      final String? userEmail = _emailController.text.isNotEmpty
          ? _emailController.text
          : null;

      // Construct mailto URL
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'ray.boorsma@gmail.com', // Replace with your email
        query: encodeQueryParameters({
          'subject': emailSubject,
          'body': emailBody,
          if (userEmail != null) 'reply-to': userEmail,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      _log.severe('Error sending feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending feedback. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }
}