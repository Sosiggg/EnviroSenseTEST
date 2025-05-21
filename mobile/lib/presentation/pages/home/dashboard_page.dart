import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/sensor_data.dart';
import '../../blocs/sensor/sensor_bloc.dart';
import '../../blocs/sensor/sensor_event.dart';
import '../../blocs/sensor/sensor_state.dart';
import '../../widgets/simple_sensor_history_view.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<SensorData> _sensorData = [];
  SensorData? _latestData;

  // Timers for periodic updates
  Timer? _refreshTimer;
  Timer? _statusUpdateTimer;

  // Helper method to get minimum temperature from chart data
  double _getMinTemperature(List<SensorData> data) {
    if (data.isEmpty) return 20.0; // Default min if no data

    // Get the actual minimum value
    double minValue = data
        .map((e) => e.temperature)
        .reduce((a, b) => a < b ? a : b);

    // Round down to nearest 0.5 to create a clean starting point
    return (minValue * 10).floor() / 10;
  }

  // Helper method to get maximum temperature from chart data
  double _getMaxTemperature(List<SensorData> data) {
    if (data.isEmpty) return 30.0; // Default max if no data

    // Get the actual maximum value
    double maxValue = data
        .map((e) => e.temperature)
        .reduce((a, b) => a > b ? a : b);

    // Round up to nearest 0.5 to create a clean ending point
    return (maxValue * 10).ceil() / 10;
  }

  // Helper method to get minimum humidity from chart data
  double _getMinHumidity(List<SensorData> data) {
    if (data.isEmpty) return 40.0; // Default min if no data

    // Get the actual minimum value
    double minValue = data
        .map((e) => e.humidity)
        .reduce((a, b) => a < b ? a : b);

    // Round down to nearest 0.5 to create a clean starting point
    return (minValue * 10).floor() / 10;
  }

  // Helper method to get maximum humidity from chart data
  double _getMaxHumidity(List<SensorData> data) {
    if (data.isEmpty) return 80.0; // Default max if no data

    // Get the actual maximum value
    double maxValue = data
        .map((e) => e.humidity)
        .reduce((a, b) => a > b ? a : b);

    // Round up to nearest 0.5 to create a clean ending point
    return (maxValue * 10).ceil() / 10;
  }

  @override
  void initState() {
    super.initState();

    // Reset sensor data first to ensure we don't have any stale data
    context.read<SensorBloc>().add(const SensorResetRequested());

    // Wait a moment for the reset to complete
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Load fresh sensor data
        context.read<SensorBloc>().add(const SensorDataRequested());
        context.read<SensorBloc>().add(const SensorLatestDataRequested());

        // Ensure WebSocket is connected with fresh credentials
        context.read<SensorBloc>().add(const SensorWebSocketConnectRequested());
      }
    });

    // Set up a timer to periodically refresh data (as a fallback)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<SensorBloc>().add(const SensorLatestDataRequested());
      }
    });

    // Set up a timer to periodically update the status indicator
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild of the status indicator
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel all timers
    _refreshTimer?.cancel();
    _refreshTimer = null;

    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;

    super.dispose();
  }

  // Build a text widget that shows the last updated time
  Widget _buildLastUpdatedText(BuildContext context) {
    return Builder(
      builder: (context) {
        // This will be rebuilt every time setState is called by the timer
        if (_latestData == null) {
          return const Text(
            'Last updated: -',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          );
        }

        // Calculate time difference
        final now = DateTime.now();
        final dataTime = _latestData!.timestamp.add(const Duration(hours: 8));
        final diff = now.difference(dataTime);

        // Format the timestamp in Manila time
        final formattedTime = DateFormat(
          'MMM dd, yyyy hh:mm:ss a',
        ).format(dataTime);

        // Show different text based on how recent the data is
        String timeText;
        if (_latestData!.temperature == 0.0 && _latestData!.humidity == 0.0) {
          // If we have default values (no real data), show "-"
          timeText = '-';
        } else if (diff.inSeconds < 60) {
          timeText = '${diff.inSeconds} seconds ago';
        } else if (diff.inMinutes < 60) {
          timeText = '${diff.inMinutes} minutes ago';
        } else {
          timeText = formattedTime;
        }

        return Text(
          'Last updated: $timeText',
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  // Build an animated sensor card with visual feedback for updates
  Widget _buildAnimatedSensorCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isUpdated,
  }) {
    // Define fixed heights for consistent card sizing
    const double cardHeight = 120.0;
    const double valueTextHeight = 40.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: cardHeight, // Fixed height container
      child: Card(
        elevation: 4, // Fixed elevation
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background pulse animation when data updates
              if (isUpdated)
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: (1.0 - value) * 0.3, // Fade out from 0.3 to 0
                        child: Container(
                          color: color.withAlpha(50), // ~0.2 opacity
                        ),
                      );
                    },
                  ),
                ),

              // Card content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row with icon
                    Row(
                      children: [
                        // Animated icon that pulses when data updates
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: isUpdated ? 1.2 : 1.0,
                            end: 1.0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Icon(icon, color: color, size: 24),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Value display with animation
                    SizedBox(
                      height: valueTextHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: isUpdated ? 1.1 : 1.0,
                            end: 1.0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          builder: (context, scaleValue, child) {
                            return Transform.scale(
                              scale: scaleValue,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                value, // This is the string value from the parameter
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Add a subtle indicator for obstacle detection
                    if (title == 'Obstacle' && value == 'Detected')
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, child) {
                          return Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  color.withAlpha(
                                    (value * 204).toInt(),
                                  ), // ~0.8 opacity
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    // We use screenWidth directly in the UI for responsive adjustments

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SensorBloc>().add(const SensorDataRequested());
        context.read<SensorBloc>().add(const SensorLatestDataRequested());
      },
      child: BlocConsumer<SensorBloc, SensorState>(
        listener: (context, state) {
          if (state is SensorDataLoaded) {
            setState(() {
              // Replace the entire list with fresh data
              _sensorData = state.sensorData;

              // Safety check: If we have data, ensure it's all from the same user
              if (_sensorData.isNotEmpty) {
                final userId = _sensorData[0].userId;
                // Filter out any data from different users
                _sensorData =
                    _sensorData.where((data) => data.userId == userId).toList();
                AppLogger.d(
                  'DashboardPage: Filtered sensor data for user ID: $userId',
                );
              }
            });
          } else if (state is SensorLatestDataLoaded) {
            setState(() {
              _latestData = state.sensorData;
            });
          } else if (state is SensorWebSocketDataReceived) {
            // Update state with new data
            setState(() {
              _latestData = state.sensorData;

              // Only add the new data if it's for the current user
              // Check user_id to ensure we're not mixing data from different users
              if (_sensorData.isEmpty ||
                  (_sensorData.isNotEmpty &&
                      _sensorData[0].userId == state.sensorData.userId)) {
                _sensorData = [state.sensorData, ..._sensorData];
              } else {
                // If user_id doesn't match, this might be stale data from a previous user
                // Clear the list and start fresh
                _sensorData = [state.sensorData];
              }
            });
          } else if (state is SensorInitial) {
            // Reset all data when SensorBloc is reset
            setState(() {
              _sensorData = [];
              _latestData = null;
            });
          } else if (state is SensorFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Latest Readings Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Latest Readings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Debug button to show WebSocket state
                    IconButton(
                      icon: const Icon(Icons.bug_report, size: 20),
                      onPressed: () {
                        final state = context.read<SensorBloc>().state;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'WebSocket State: ${state.runtimeType}',
                            ),
                            duration: const Duration(seconds: 3),
                            action: SnackBarAction(
                              label: 'Reconnect',
                              onPressed: () {
                                context.read<SensorBloc>().add(
                                  const SensorWebSocketConnectRequested(),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      tooltip: 'Debug WebSocket',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Latest Sensor Cards
                Builder(
                  builder: (context) {
                    if (_latestData == null) {
                      return const Center(
                        child: Text('No sensor data available'),
                      );
                    }

                    // Use AnimatedContainer for smooth transitions
                    return Column(
                      children: [
                        // Responsive layout for sensor cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Use column layout for small screens
                            if (constraints.maxWidth < 400) {
                              return Column(
                                children: [
                                  _buildAnimatedSensorCard(
                                    context,
                                    title: 'Temperature',
                                    value:
                                        '${_latestData!.temperature.toStringAsFixed(1)}°C',
                                    icon: Icons.thermostat,
                                    color: AppTheme.chartColors[0],
                                    isUpdated:
                                        context.watch<SensorBloc>().state
                                            is SensorWebSocketDataReceived,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildAnimatedSensorCard(
                                    context,
                                    title: 'Humidity',
                                    value:
                                        '${_latestData!.humidity.toStringAsFixed(1)}%',
                                    icon: Icons.water_drop,
                                    color: AppTheme.chartColors[1],
                                    isUpdated:
                                        context.watch<SensorBloc>().state
                                            is SensorWebSocketDataReceived,
                                  ),
                                ],
                              );
                            } else {
                              // Use row layout for larger screens
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildAnimatedSensorCard(
                                      context,
                                      title: 'Temperature',
                                      value:
                                          '${_latestData!.temperature.toStringAsFixed(1)}°C',
                                      icon: Icons.thermostat,
                                      color: AppTheme.chartColors[0],
                                      isUpdated:
                                          context.watch<SensorBloc>().state
                                              is SensorWebSocketDataReceived,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildAnimatedSensorCard(
                                      context,
                                      title: 'Humidity',
                                      value:
                                          '${_latestData!.humidity.toStringAsFixed(1)}%',
                                      icon: Icons.water_drop,
                                      color: AppTheme.chartColors[1],
                                      isUpdated:
                                          context.watch<SensorBloc>().state
                                              is SensorWebSocketDataReceived,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity, // Full width
                          child: _buildAnimatedSensorCard(
                            context,
                            title: 'Obstacle',
                            value: _latestData!.obstacle ? 'Detected' : 'None',
                            icon: Icons.warning,
                            color:
                                _latestData!.obstacle
                                    ? Colors.red
                                    : Colors.green,
                            isUpdated:
                                context.watch<SensorBloc>().state
                                    is SensorWebSocketDataReceived,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              // Use a stateful builder that rebuilds every second
                              child: _buildLastUpdatedText(context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 16),
                              onPressed: () {
                                // Manually reconnect WebSocket and refresh data
                                context.read<SensorBloc>().add(
                                  const SensorWebSocketConnectRequested(),
                                );
                                context.read<SensorBloc>().add(
                                  const SensorLatestDataRequested(),
                                );

                                // Show a snackbar to indicate reconnection attempt
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reconnecting to server...'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              tooltip: 'Reconnect',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            // Simple status indicator based on latest data
                            Builder(
                              builder: (context) {
                                // Determine status based on latest data and refresh timer
                                String statusText;
                                Color statusColor;

                                // If we have latest data and it's recent (within last 10 seconds)
                                if (_latestData != null) {
                                  final now = DateTime.now();
                                  // Adjust timestamp to Manila time (UTC+8)
                                  final manilaTimestamp = _latestData!.timestamp
                                      .add(const Duration(hours: 8));
                                  final diff = now.difference(manilaTimestamp);

                                  if (diff.inSeconds < 10) {
                                    statusText = 'Live';
                                    statusColor = Colors.green;
                                  } else {
                                    statusText = 'Connected';
                                    statusColor = Colors.blue;
                                  }
                                } else {
                                  statusText = 'Waiting...';
                                  statusColor = Colors.orange;
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(50),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor.withAlpha(100),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Animated pulse for "Live" status
                                      if (statusText == 'Live')
                                        TweenAnimationBuilder<double>(
                                          tween: Tween<double>(
                                            begin: 0.5,
                                            end: 1.0,
                                          ),
                                          duration: const Duration(
                                            milliseconds: 1000,
                                          ),
                                          curve: Curves.easeInOut,
                                          builder: (context, value, child) {
                                            return Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: statusColor.withAlpha(
                                                  (value * 255).toInt(),
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: statusColor
                                                        .withAlpha(
                                                          (value * 100).toInt(),
                                                        ),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      else
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      Text(
                                        statusText,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Temperature Chart with responsive title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Temperature History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        // Smaller font on small screens
                        fontSize: screenWidth < 360 ? 16 : null,
                      ),
                    ),
                    // Refresh button for chart data
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        // Smaller icon on small screens
                        size: screenWidth < 360 ? 18 : 20,
                      ),
                      onPressed: () {
                        context.read<SensorBloc>().add(
                          const SensorDataRequested(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Refreshing chart data...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      tooltip: 'Refresh chart data',
                      visualDensity:
                          screenWidth < 360
                              ? const VisualDensity(
                                horizontal: -1,
                                vertical: -1,
                              )
                              : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BlocBuilder<SensorBloc, SensorState>(
                  builder: (context, state) {
                    if (state is SensorLoading && _sensorData.isEmpty) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (_sensorData.isEmpty) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No temperature data available'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<SensorBloc>().add(
                                    const SensorDataRequested(),
                                  );
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Sort data by timestamp
                    final sortedData = List<SensorData>.from(_sensorData)
                      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                    // Take only the last 20 readings for the chart
                    final chartData =
                        sortedData.length > 20
                            ? sortedData.sublist(sortedData.length - 20)
                            : sortedData;

                    // Adjust chart height based on screen width
                    final chartHeight = screenWidth < 360 ? 180.0 : 200.0;

                    // Adjust interval based on screen width
                    final labelInterval = screenWidth < 360 ? 5 : 4;

                    // Adjust left title reserved size based on screen width
                    final leftReservedSize = screenWidth < 360 ? 35.0 : 45.0;

                    return SizedBox(
                      height: chartHeight,
                      child: LineChart(
                        LineChartData(
                          minY:
                              _getMinTemperature(chartData) -
                              0.2, // Add small padding below min value for precise scale
                          maxY:
                              _getMaxTemperature(chartData) +
                              0.2, // Add small padding above max value for precise scale
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: leftReservedSize,
                                interval:
                                    0.2, // Show labels every 0.2 unit for precise temperature readings
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: screenWidth < 360 ? 8 : 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval:
                                    labelInterval
                                        .toDouble(), // Adjust interval based on screen size
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < chartData.length &&
                                      value.toInt() % labelInterval == 0) {
                                    // Only show labels at the interval
                                    final date =
                                        chartData[value.toInt()].timestamp;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        DateFormat(
                                          'h:mm a', // Shorter format without leading zero
                                        ).format(
                                          date.add(const Duration(hours: 8)),
                                        ),
                                        style: TextStyle(
                                          fontSize: screenWidth < 360 ? 8 : 10,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                chartData.length,
                                (index) => FlSpot(
                                  index.toDouble(),
                                  chartData[index].temperature,
                                ),
                              ),
                              isCurved: true,
                              color: AppTheme.chartColors[0],
                              barWidth:
                                  screenWidth < 360
                                      ? 2
                                      : 3, // Thinner line on small screens
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.chartColors[0].withAlpha(
                                  51,
                                ), // 0.2 * 255 = 51
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Humidity Chart with responsive title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Humidity History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        // Smaller font on small screens
                        fontSize: screenWidth < 360 ? 16 : null,
                      ),
                    ),
                    // Refresh button for chart data
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        // Smaller icon on small screens
                        size: screenWidth < 360 ? 18 : 20,
                      ),
                      onPressed: () {
                        context.read<SensorBloc>().add(
                          const SensorDataRequested(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Refreshing chart data...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      tooltip: 'Refresh chart data',
                      visualDensity:
                          screenWidth < 360
                              ? const VisualDensity(
                                horizontal: -1,
                                vertical: -1,
                              )
                              : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BlocBuilder<SensorBloc, SensorState>(
                  builder: (context, state) {
                    if (state is SensorLoading && _sensorData.isEmpty) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (_sensorData.isEmpty) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No humidity data available'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<SensorBloc>().add(
                                    const SensorDataRequested(),
                                  );
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Sort data by timestamp
                    final sortedData = List<SensorData>.from(_sensorData)
                      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                    // Take only the last 20 readings for the chart
                    final chartData =
                        sortedData.length > 20
                            ? sortedData.sublist(sortedData.length - 20)
                            : sortedData;

                    // Adjust chart height based on screen width
                    final chartHeight = screenWidth < 360 ? 180.0 : 200.0;

                    // Adjust interval based on screen width
                    final labelInterval = screenWidth < 360 ? 5 : 4;

                    // Adjust left title reserved size based on screen width
                    final leftReservedSize = screenWidth < 360 ? 35.0 : 45.0;

                    return SizedBox(
                      height: chartHeight,
                      child: LineChart(
                        LineChartData(
                          minY:
                              _getMinHumidity(chartData) -
                              0.2, // Add small padding below min value for precise scale
                          maxY:
                              _getMaxHumidity(chartData) +
                              0.2, // Add small padding above max value for precise scale
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: leftReservedSize,
                                interval:
                                    0.2, // Show labels every 0.2 unit for precise humidity readings
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: screenWidth < 360 ? 8 : 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval:
                                    labelInterval
                                        .toDouble(), // Adjust interval based on screen size
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < chartData.length &&
                                      value.toInt() % labelInterval == 0) {
                                    // Only show labels at the interval
                                    final date =
                                        chartData[value.toInt()].timestamp;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        DateFormat(
                                          'h:mm a', // Shorter format without leading zero
                                        ).format(
                                          date.add(const Duration(hours: 8)),
                                        ),
                                        style: TextStyle(
                                          fontSize: screenWidth < 360 ? 8 : 10,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                chartData.length,
                                (index) => FlSpot(
                                  index.toDouble(),
                                  chartData[index].humidity,
                                ),
                              ),
                              isCurved: true,
                              color: AppTheme.chartColors[1],
                              barWidth:
                                  screenWidth < 360
                                      ? 2
                                      : 3, // Thinner line on small screens
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.chartColors[1].withAlpha(
                                  51,
                                ), // 0.2 * 255 = 51
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Simple Sensor History View
                const SizedBox(height: 32),
                const SimpleSensorHistoryView(),
              ],
            ),
          );
        },
      ),
    );
  }
}
