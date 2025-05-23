import 'package:equatable/equatable.dart';

abstract class SensorEvent extends Equatable {
  const SensorEvent();

  @override
  List<Object?> get props => [];
}

class SensorDataRequested extends SensorEvent {
  const SensorDataRequested();
}

class SensorLatestDataRequested extends SensorEvent {
  const SensorLatestDataRequested();
}

class SensorDataByDateRangeRequested extends SensorEvent {
  final DateTime startDate;
  final DateTime endDate;
  final int page;
  final int pageSize;

  const SensorDataByDateRangeRequested({
    required this.startDate,
    required this.endDate,
    required this.page,
    required this.pageSize,
  });

  @override
  List<Object?> get props => [startDate, endDate, page, pageSize];
}

class SensorDataByDatePaginatedRequested extends SensorEvent {
  final DateTime date;
  final int page;
  final int pageSize;

  const SensorDataByDatePaginatedRequested({
    required this.date,
    required this.page,
    required this.pageSize,
  });

  @override
  List<Object?> get props => [date, page, pageSize];
}

class SensorStatisticsRequested extends SensorEvent {
  const SensorStatisticsRequested();
}

class SensorWebSocketConnectRequested extends SensorEvent {
  const SensorWebSocketConnectRequested();
}

class SensorWebSocketDisconnectRequested extends SensorEvent {
  const SensorWebSocketDisconnectRequested();
}

class SensorWebSocketDataReceivedEvent extends SensorEvent {
  final Map<String, dynamic> data;

  const SensorWebSocketDataReceivedEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class SensorDataClearRequested extends SensorEvent {
  const SensorDataClearRequested();
}

class SensorResetRequested extends SensorEvent {
  const SensorResetRequested();
}
