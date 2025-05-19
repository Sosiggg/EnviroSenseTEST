import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sensor_data.dart';
import '../../blocs/sensor/sensor_bloc.dart';
import '../../blocs/sensor/sensor_event.dart';
import '../../blocs/sensor/sensor_state.dart';

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

  @override
  void initState() {
    super.initState();

    // Load sensor data
    context.read<SensorBloc>().add(const SensorDataRequested());
    context.read<SensorBloc>().add(const SensorLatestDataRequested());

    // Ensure WebSocket is connected
    context.read<SensorBloc>().add(const SensorWebSocketConnectRequested());

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
            'Last updated: Never',
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
        if (diff.inSeconds < 60) {
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

  // Build a simple sensor card without any animations
  Widget _buildAnimatedSensorCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isUpdated, // Kept for compatibility but not used
  }) {
    // Define fixed heights for consistent card sizing
    const double cardHeight = 120.0;
    const double valueTextHeight = 40.0;

    return SizedBox(
      height: cardHeight, // Fixed height container
      child: Card(
        elevation: 4, // Fixed elevation
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Use minimum space needed
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(), // Use spacer instead of SizedBox for flexible spacing
              SizedBox(
                height: valueTextHeight, // Fixed height for value text
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
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
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SensorBloc>().add(const SensorDataRequested());
        context.read<SensorBloc>().add(const SensorLatestDataRequested());
      },
      child: BlocConsumer<SensorBloc, SensorState>(
        listener: (context, state) {
          if (state is SensorDataLoaded) {
            setState(() {
              _sensorData = state.sensorData;
            });
          } else if (state is SensorLatestDataLoaded) {
            setState(() {
              _latestData = state.sensorData;
            });
          } else if (state is SensorWebSocketDataReceived) {
            // Update state with new data
            setState(() {
              _latestData = state.sensorData;
              _sensorData = [state.sensorData, ..._sensorData];
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

                                return Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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

                // Temperature Chart
                Text(
                  'Temperature History',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('No temperature data available'),
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

                    return SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
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
                                interval: 4, // Only show every 4th label
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < chartData.length &&
                                      value.toInt() % 4 == 0) {
                                    // Only show every 4th label
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
                                        style: const TextStyle(fontSize: 10),
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
                              barWidth: 3,
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

                // Humidity Chart
                Text(
                  'Humidity History',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('No humidity data available'),
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

                    return SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
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
                                interval: 4, // Only show every 4th label
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < chartData.length &&
                                      value.toInt() % 4 == 0) {
                                    // Only show every 4th label
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
                                        style: const TextStyle(fontSize: 10),
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
                              barWidth: 3,
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

                // Data History Log
                const SizedBox(height: 32),
                Text(
                  'Data History Log',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                      return const SizedBox(
                        height: 200,
                        child: Center(child: Text('No sensor data available')),
                      );
                    }

                    // Sort data by timestamp in descending order (newest first)
                    final sortedData = List<SensorData>.from(_sensorData)
                      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    // Take only the last 20 readings for the list
                    final listData =
                        sortedData.length > 20
                            ? sortedData.sublist(0, 20)
                            : sortedData;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      height: 300, // Fixed height for the list
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: listData.length,
                        separatorBuilder:
                            (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final data = listData[index];
                          // Adjust timestamp to Manila time (UTC+8)
                          final manilaTime = data.timestamp.add(
                            const Duration(hours: 8),
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // For small screens, use a more compact layout
                                if (constraints.maxWidth < 400) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Time row
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              DateFormat(
                                                'MMM dd, yyyy - hh:mm a',
                                              ).format(manilaTime),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Data row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          // Temperature
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.thermostat,
                                                color: AppTheme.chartColors[0],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${data.temperature.toStringAsFixed(1)}°C',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                          // Humidity
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.water_drop,
                                                color: AppTheme.chartColors[1],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${data.humidity.toStringAsFixed(1)}%',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                          // Obstacle
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.warning,
                                                color:
                                                    data.obstacle
                                                        ? Colors.red
                                                        : Colors.green,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                data.obstacle ? 'Yes' : 'No',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                } else {
                                  // For larger screens, use the original row layout
                                  return Row(
                                    children: [
                                      // Time column
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(manilaTime),
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                            ),
                                            Text(
                                              DateFormat(
                                                'hh:mm:ss a',
                                              ).format(manilaTime),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Temperature column
                                      Expanded(
                                        flex: 1,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.thermostat,
                                              color: AppTheme.chartColors[0],
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${data.temperature.toStringAsFixed(1)}°C',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Humidity column
                                      Expanded(
                                        flex: 1,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.water_drop,
                                              color: AppTheme.chartColors[1],
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${data.humidity.toStringAsFixed(1)}%',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Obstacle column
                                      Expanded(
                                        flex: 1,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.warning,
                                              color:
                                                  data.obstacle
                                                      ? Colors.red
                                                      : Colors.green,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              data.obstacle ? 'Yes' : 'No',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
