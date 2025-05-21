import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/sensor_data.dart';
import '../blocs/sensor/sensor_bloc.dart';
import '../blocs/sensor/sensor_event.dart';
import '../blocs/sensor/sensor_state.dart';

class SensorHistoryDateView extends StatefulWidget {
  const SensorHistoryDateView({super.key});

  @override
  State<SensorHistoryDateView> createState() => _SensorHistoryDateViewState();
}

class _SensorHistoryDateViewState extends State<SensorHistoryDateView> {
  int _currentPage = 1;
  static const int _pageSize = 50; // Show more data at once for last 24 hours
  List<SensorData> _sensorData = [];
  bool _hasMoreData = false;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    AppLogger.i('SensorHistoryDateView: Initializing with last 24 hours data');

    _loadData();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMoreData && !_isLoading) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadData() async {
    AppLogger.i('SensorHistoryDateView: Loading data for last 24 hours');

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _sensorData = [];
    });

    // Calculate the date range for the last 24 hours
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    // Request data for the last 24 hours
    context.read<SensorBloc>().add(
      SensorDataByDateRangeRequested(
        startDate: yesterday,
        endDate: now,
        page: _currentPage,
        pageSize: _pageSize,
      ),
    );
  }

  Future<void> _loadMoreData() async {
    if (_hasMoreData && !_isLoading) {
      setState(() {
        _isLoading = true;
        _currentPage++;
      });

      // Calculate the date range for the last 24 hours
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      context.read<SensorBloc>().add(
        SensorDataByDateRangeRequested(
          startDate: yesterday,
          endDate: now,
          page: _currentPage,
          pageSize: _pageSize,
        ),
      );
    }
  }

  // Debug method to check API directly
  Future<void> _checkApiDirectly() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Show a message that we're checking the API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking API directly...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Create a direct API client
      final dio = Dio();

      // Calculate the date range for the last 24 hours
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      // Build the URL with query parameters
      final url = '${ApiConstants.baseUrl}${ApiConstants.sensorData}';
      final queryParameters = {
        'start_date': yesterday.toIso8601String(),
        'end_date': now.toIso8601String(),
        'page': '1',
        'page_size': _pageSize.toString(),
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
          setState(() {
            _isLoading = false;
          });
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
                title: const Text('API Response'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('URL: $url'),
                      const SizedBox(height: 8),
                      Text('Query: $queryParameters'),
                      const SizedBox(height: 16),
                      const Text(
                        'Response:',
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      // After checking, try to load the data again
                      _loadData();
                    },
                    child: const Text('Close and Refresh'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Error: $e'), backgroundColor: Colors.red),
        );
      }
      AppLogger.e('Error checking API directly: $e', e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date selector and title
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withAlpha(76), // 0.3 * 255 = ~76
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sensor History (Last 24 Hours)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Showing detailed sensor readings from the last 24 hours',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh data',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _checkApiDirectly,
                    icon: const Icon(Icons.bug_report),
                    tooltip: 'Debug API',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sensor data list with pagination
        BlocConsumer<SensorBloc, SensorState>(
          listener: (context, state) {
            if (state is SensorDataPaginatedLoaded) {
              AppLogger.i(
                'SensorHistoryDateView: Received SensorDataPaginatedLoaded state',
              );
              AppLogger.i(
                'SensorHistoryDateView: Data items: ${state.sensorData.length}, page: ${state.page}, hasMoreData: ${state.hasMoreData}',
              );

              setState(() {
                if (state.page == 1) {
                  // First page, replace data
                  _sensorData = state.sensorData;
                  AppLogger.i(
                    'SensorHistoryDateView: Replaced data with ${_sensorData.length} items',
                  );
                } else {
                  // Subsequent pages, append data
                  _sensorData = [..._sensorData, ...state.sensorData];
                  AppLogger.i(
                    'SensorHistoryDateView: Appended data, now have ${_sensorData.length} items',
                  );
                }
                _hasMoreData = state.hasMoreData;
                _isLoading = false;
              });
            } else if (state is SensorFailure) {
              AppLogger.e(
                'SensorHistoryDateView: Received SensorFailure state: ${state.message}',
              );
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else {
              AppLogger.d(
                'SensorHistoryDateView: Received state: ${state.runtimeType}',
              );
            }
          },
          builder: (context, state) {
            if (state is SensorLoading && _sensorData.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_sensorData.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sensor data available for the last 24 hours',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check if your sensor is connected and sending data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Refresh'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _checkApiDirectly,
                          child: const Text('Debug API'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              height:
                  500, // Increased height to accommodate the new card design
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _sensorData.length + (_hasMoreData ? 1 : 0),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  // Show loading indicator at the bottom when loading more data
                  if (index == _sensorData.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final data = _sensorData[index];
                  // Adjust timestamp to Manila time (UTC+8)
                  final manilaTime = data.timestamp.add(
                    const Duration(hours: 8),
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ID and Date/Time row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ID
                              Text(
                                'ID: ${data.id}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              // Date and Time
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy hh:mm:ss a',
                                ).format(manilaTime),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(),
                          // Sensor data with emojis
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(height: 1.5),
                                children: [
                                  // Temperature with emoji
                                  const TextSpan(
                                    text: '🌡️ ',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  TextSpan(
                                    text:
                                        '${data.temperature.toStringAsFixed(2)} °C, ',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Humidity with emoji
                                  const TextSpan(
                                    text: '💧 ',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  TextSpan(
                                    text:
                                        '${data.humidity.toStringAsFixed(2)} %, ',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Obstacle with emoji
                                  const TextSpan(
                                    text: '🚧 ',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  TextSpan(
                                    text:
                                        'Obstacle: ${data.obstacle ? "YES" : "NO"}',
                                    style: TextStyle(
                                      color:
                                          data.obstacle
                                              ? Colors.red
                                              : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // User ID row
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'User ID: ${data.userId}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
