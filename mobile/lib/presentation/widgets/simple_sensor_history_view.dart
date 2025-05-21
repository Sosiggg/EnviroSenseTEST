import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/utils/app_logger.dart';

class SimpleSensorHistoryView extends StatefulWidget {
  const SimpleSensorHistoryView({super.key});

  @override
  State<SimpleSensorHistoryView> createState() =>
      _SimpleSensorHistoryViewState();
}

class _SimpleSensorHistoryViewState extends State<SimpleSensorHistoryView> {
  bool _isLoading = false;

  // Method to show raw data history
  Future<void> _showRawDataHistory() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Show a loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading sensor history data...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Create a direct API client
      final dio = Dio();

      // Calculate the date range for the last 24 hours
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      // Build the URL with query parameters
      final url = '${ApiConstants.baseUrl}/sensor/data';
      final queryParameters = {
        'start_date': yesterday.toIso8601String(),
        'end_date': now.toIso8601String(),
        'page': '1',
        'page_size': '100',
      };

      // Get the token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No authentication token found. Please log in again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Make the API request
      final response = await dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Show the response in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Sensor Data History'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Time Range: ${yesterday.toString()} to ${now.toString()}',
                      ),
                      const SizedBox(height: 8),
                      Text('Query: $queryParameters'),
                      const SizedBox(height: 16),
                      const Text(
                        'Raw Data:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        const JsonEncoder.withIndent(
                          '  ',
                        ).convert(response.data),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching sensor history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      AppLogger.e('Error fetching sensor history: $e', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(76),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Sensor History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _showRawDataHistory,
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.data_array),
            label: Text(_isLoading ? 'Loading...' : 'View Raw Data History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View the last 24 hours of raw sensor data',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
