import 'package:equatable/equatable.dart';

import '../../../domain/entities/sensor_data.dart';

abstract class SensorState extends Equatable {
  const SensorState();

  @override
  List<Object?> get props => [];
}

class SensorInitial extends SensorState {
  const SensorInitial();
}

class SensorLoading extends SensorState {
  const SensorLoading();
}

class SensorDataLoaded extends SensorState {
  final List<SensorData> sensorData;

  const SensorDataLoaded(this.sensorData);

  @override
  List<Object?> get props => [sensorData];
}

class SensorDataPaginatedLoaded extends SensorState {
  final List<SensorData> sensorData;
  final DateTime date;
  final int page;
  final int pageSize;
  final bool hasMoreData;

  const SensorDataPaginatedLoaded({
    required this.sensorData,
    required this.date,
    required this.page,
    required this.pageSize,
    required this.hasMoreData,
  });

  @override
  List<Object?> get props => [sensorData, date, page, pageSize, hasMoreData];
}

class SensorLatestDataLoaded extends SensorState {
  final SensorData sensorData;

  const SensorLatestDataLoaded(this.sensorData);

  @override
  List<Object?> get props => [sensorData];
}

class SensorStatisticsLoaded extends SensorState {
  final Map<String, dynamic> statistics;

  const SensorStatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

class SensorWebSocketConnected extends SensorState {
  const SensorWebSocketConnected();
}

class SensorWebSocketDisconnected extends SensorState {
  const SensorWebSocketDisconnected();
}

class SensorWebSocketDataReceived extends SensorState {
  final SensorData sensorData;

  const SensorWebSocketDataReceived(this.sensorData);

  @override
  List<Object?> get props => [sensorData];
}

class SensorFailure extends SensorState {
  final String message;

  const SensorFailure(this.message);

  @override
  List<Object?> get props => [message];
}
