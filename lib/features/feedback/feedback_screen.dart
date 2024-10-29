// feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';

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
  void initState() {
    super.initState();
    _log.info('FeedbackScreen initialized');
  }

  @override
  void dispose() {
    _log.info('FeedbackScreen disposing');
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log.info('Building FeedbackScreen widget');
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
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          _log.info('Email validation failed: $value');
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
                        _log.info('Feedback validation failed: Empty feedback');
                        return 'Please enter your feedback';
                      }
                      if (value.trim().length < 10) {
                        _log.info('Feedback validation failed: Too short');
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
    _log.info('Starting feedback submission process');

    if (!_formKey.currentState!.validate()) {
      //_Log.info('Form validation failed');
      return;
    }

    //_Log.info('Form validation passed');
    setState(() {
      _isSubmitting = true;
      //_Log.info('Set _isSubmitting to true');
    });

    try {
      final String emailSubject = 'App Feedback';
      final String emailBody = _feedbackController.text;
      final String? userEmail = _emailController.text.isNotEmpty
          ? _emailController.text
          : null;

      //_Log.info('Preparing email with subject: $emailSubject');
      //_Log.info('Email body length: ${emailBody.length}');
      if (userEmail != null) {
        //_Log.info('Reply-to email: $userEmail');
      }

      // Construct mailto URL
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'ray.boorsma@gmail.com',
        query: encodeQueryParameters({
          'subject': emailSubject,
          'body': emailBody,
          if (userEmail != null) 'reply-to': userEmail,
        }),
      );

      //_Log.info('Constructed email URI: ${emailUri.toString()}');
      //_Log.info('Checking if can launch URL...');

      if (await canLaunchUrl(emailUri)) {
        //_Log.info('canLaunchUrl returned true, launching email client...');

        await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );

        //_Log.info('Email client launched successfully');

        if (mounted) {
          //_Log.info('Widget still mounted, showing success message');
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          //_Log.info('Success message shown and screen popped');
        } else {
          //_Log.warning('Widget not mounted after email launch');
        }
      } else {
        //_Log.severe('canLaunchUrl returned false');
        throw 'Could not launch email client';
      }
    } catch (e, stackTrace) {
      //_Log.severe('Error in feedback submission: $e');
      //_Log.severe('Stack trace: $stackTrace');

      if (mounted) {
        //_Log.info('Showing error message to user');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending feedback: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          //_Log.info('Reset _isSubmitting to false');
        });
      } else {
        //_Log.warning('Widget not mounted in finally block');
      }
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    //_Log.info('Encoding query parameters: $params');
    final encoded = params.entries
        .map((e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    //_Log.info('Encoded parameters: $encoded');
    return encoded;
  }
}