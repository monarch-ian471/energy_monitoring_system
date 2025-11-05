import 'package:flutter/material.dart';

class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class ErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const ErrorScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F33),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We apologize for the inconvenience. Please restart the app.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // In production, you might want to send error logs to a server
                },
                child: const Text('Report Issue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
