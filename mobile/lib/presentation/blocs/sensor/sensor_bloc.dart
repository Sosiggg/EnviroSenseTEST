import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exceptions.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/sensor_data.dart';
import '../../../domain/repositories/sensor_repository.dart';
import 'sensor_event.dart';
import 'sensor_state.dart';

class SensorBloc extends Bloc<SensorEvent, SensorState> {
  final SensorRepository sensorRepository;
  StreamSubscription<Map<String, dynamic>>? _sensorDataSubscription;

  SensorBloc({required this.sensorRepository}) : super(const SensorInitial()) {
    on<SensorDataRequested>(_onSensorDataRequested);
    on<SensorLatestDataRequested>(_onSensorLatestDataRequested);
    on<SensorDataByDateRangeRequested>(_onSensorDataByDateRangeRequested);
    on<SensorDataByDatePaginatedRequested>(
      _onSensorDataByDatePaginatedRequested,
    );
    on<SensorStatisticsRequested>(_onSensorStatisticsRequested);
    on<SensorWebSocketConnectRequested>(_onSensorWebSocketConnectRequested);
    on<SensorWebSocketDisconnectRequested>(
      _onSensorWebSocketDisconnectRequested,
    );
    on<SensorWebSocketDataReceivedEvent>(_onSensorWebSocketDataReceived);
    on<SensorDataClearRequested>(_onSensorDataClearRequested);
    on<SensorResetRequested>(_onSensorResetRequested);
  }

  Future<void> _onSensorDataRequested(
    SensorDataRequested event,
    Emitter<SensorState> emit,
  ) async {
    emit(const SensorLoading());

    try {
      final sensorDataList = await sensorRepository.getSensorData();

      final sensorData =
          sensorDataList.map((data) => SensorData.fromJson(data)).toList();

      emit(SensorDataLoaded(sensorData));
    } on ApiException catch (e) {
      emit(SensorFailure(e.message));
    } catch (e) {
      emit(SensorFailure(e.toString()));
    }
  }

  Future<void> _onSensorLatestDataRequested(
    SensorLatestDataRequested event,
    Emitter<SensorState> emit,
  ) async {
    emit(const SensorLoading());

    try {
      final sensorDataMap = await sensorRepository.getLatestSensorData();

      final sensorData = SensorData.fromJson(sensorDataMap);

      emit(SensorLatestDataLoaded(sensorData));
    } on ApiException catch (e) {
      emit(SensorFailure(e.message));
    } catch (e) {
      emit(SensorFailure(e.toString()));
    }
  }

  Future<void> _onSensorDataByDateRangeRequested(
    SensorDataByDateRangeRequested event,
    Emitter<SensorState> emit,
  ) async {
    emit(const SensorLoading());

    try {
      AppLogger.i(
        'Getting paginated sensor data for date range: ${event.startDate.toIso8601String()} to ${event.endDate.toIso8601String()} (page ${event.page})',
      );

      final response = await sensorRepository.getSensorDataByDateRangePaginated(
        startDate: event.startDate,
        endDate: event.endDate,
        page: event.page,
        pageSize: event.pageSize,
      );

      // Extract data and pagination info
      AppLogger.d('Response from API: $response');

      final dataList = response['data'] as List<dynamic>;
      AppLogger.d('Data list length: ${dataList.length}');

      final pagination = response['pagination'] as Map<String, dynamic>;
      AppLogger.d('Pagination info: $pagination');

      // Convert to SensorData objects
      final sensorData = <SensorData>[];
      for (final item in dataList) {
        try {
          final data = item as Map<String, dynamic>;
          AppLogger.d('Processing data item: $data');
          final sensorDataItem = SensorData.fromJson(data);
          sensorData.add(sensorDataItem);
        } catch (e) {
          AppLogger.e('Error converting data item: $e', e);
        }
      }

      // Get hasMoreData from pagination info
      final hasMoreData = pagination['has_next'] as bool? ?? false;

      // Log pagination details
      AppLogger.i(
        'Pagination info: page ${pagination['page']}/${pagination['total_pages']}, '
        'total items: ${pagination['total_count']}, has_next: $hasMoreData',
      );

      emit(
        SensorDataPaginatedLoaded(
          sensorData: sensorData,
          date: event.startDate, // Use startDate for compatibility
          page: event.page,
          pageSize: event.pageSize,
          hasMoreData: hasMoreData,
        ),
      );

      AppLogger.i(
        'Loaded ${sensorData.length} sensor data items for date range: ${event.startDate.toIso8601String()} to ${event.endDate.toIso8601String()} (page ${event.page})',
      );
    } on ApiException catch (e) {
      emit(SensorFailure(e.message));
    } catch (e) {
      AppLogger.e('Error loading paginated sensor data by date range: $e', e);
      emit(SensorFailure(e.toString()));
    }
  }

  Future<void> _onSensorDataByDatePaginatedRequested(
    SensorDataByDatePaginatedRequested event,
    Emitter<SensorState> emit,
  ) async {
    emit(const SensorLoading());

    try {
      AppLogger.i(
        'Getting paginated sensor data for date: ${event.date.toIso8601String()} (page ${event.page})',
      );

      final response = await sensorRepository.getSensorDataByDatePaginated(
        date: event.date,
        page: event.page,
        pageSize: event.pageSize,
      );

      // Extract data and pagination info
      AppLogger.d('Response from API: $response');

      final dataList = response['data'] as List<dynamic>;
      AppLogger.d('Data list length: ${dataList.length}');

      final pagination = response['pagination'] as Map<String, dynamic>;
      AppLogger.d('Pagination info: $pagination');

      // Convert to SensorData objects
      final sensorData = <SensorData>[];
      for (final item in dataList) {
        try {
          final data = item as Map<String, dynamic>;
          AppLogger.d('Processing data item: $data');
          final sensorDataItem = SensorData.fromJson(data);
          sensorData.add(sensorDataItem);
        } catch (e) {
          AppLogger.e('Error converting data item: $e', e);
        }
      }

      // Get hasMoreData from pagination info
      final hasMoreData = pagination['has_next'] as bool? ?? false;

      // Log pagination details
      AppLogger.i(
        'Pagination info: page ${pagination['page']}/${pagination['total_pages']}, '
        'total items: ${pagination['total_count']}, has_next: $hasMoreData',
      );

      emit(
        SensorDataPaginatedLoaded(
          sensorData: sensorData,
          date: event.date,
          page: event.page,
          pageSize: event.pageSize,
          hasMoreData: hasMoreData,
        ),
      );

      AppLogger.i(
        'Loaded ${sensorData.length} sensor data items for date: ${event.date.toIso8601String()} (page ${event.page})',
      );
    } on ApiException catch (e) {
      emit(SensorFailure(e.message));
    } catch (e) {
      AppLogger.e('Error loading paginated sensor data: $e', e);
      emit(SensorFailure(e.toString()));
    }
  }

  Future<void> _onSensorStatisticsRequested(
    SensorStatisticsRequested event,
    Emitter<SensorState> emit,
  ) async {
    emit(const SensorLoading());

    try {
      final statistics = await sensorRepository.getSensorDataStatistics();

      emit(SensorStatisticsLoaded(statistics));
    } on ApiException catch (e) {
      emit(SensorFailure(e.message));
    } catch (e) {
      emit(SensorFailure(e.toString()));
    }
  }

  Future<void> _onSensorWebSocketConnectRequested(
    SensorWebSocketConnectRequested event,
    Emitter<SensorState> emit,
  ) async {
    // Always emit loading state to ensure UI updates
    emit(const SensorLoading());
    AppLogger.d('SensorBloc: Emitted SensorLoading state');

    try {
      AppLogger.d('SensorBloc: Attempting to connect to WebSocket');

      // Cancel existing subscription if any
      await _sensorDataSubscription?.cancel();
      _sensorDataSubscription = null;

      // Connect to WebSocket
      await sensorRepository.connectToWebSocket();
      AppLogger.i('SensorBloc: WebSocket connected successfully');

      // Emit connected state
      emit(const SensorWebSocketConnected());
      AppLogger.d('SensorBloc: Emitted SensorWebSocketConnected state');

      // Listen for data from the WebSocket
      _sensorDataSubscription = sensorRepository.getSensorDataStream().listen(
        (data) {
          // Process incoming WebSocket data
          AppLogger.d('SensorBloc: Received data from WebSocket: $data');
          add(SensorWebSocketDataReceivedEvent(data));
        },
        onError: (error) {
          // Handle errors from the WebSocket stream
          AppLogger.e('SensorBloc: WebSocket stream error: $error', error);

          // First emit failure state
          emit(SensorFailure(error.toString()));
          AppLogger.d('SensorBloc: Emitted SensorFailure state');

          // Then emit disconnected state
          emit(const SensorWebSocketDisconnected());
          AppLogger.d('SensorBloc: Emitted SensorWebSocketDisconnected state');

          // Try to reconnect after error
          Future.delayed(const Duration(seconds: 2), () {
            add(const SensorWebSocketConnectRequested());
          });
        },
        onDone: () {
          // WebSocket connection closed, try to reconnect
          AppLogger.w(
            'SensorBloc: WebSocket stream done, attempting to reconnect',
          );

          // Emit disconnected state
          emit(const SensorWebSocketDisconnected());
          AppLogger.d('SensorBloc: Emitted SensorWebSocketDisconnected state');

          // Try to reconnect after a delay
          Future.delayed(const Duration(seconds: 2), () {
            add(const SensorWebSocketConnectRequested());
          });
        },
      );
    } on ApiException catch (e) {
      AppLogger.e(
        'SensorBloc: API Exception during WebSocket connection: ${e.message}',
        e,
      );
      emit(SensorFailure(e.message));
      AppLogger.d('SensorBloc: Emitted SensorFailure state');

      // Also emit disconnected state
      emit(const SensorWebSocketDisconnected());
      AppLogger.d('SensorBloc: Emitted SensorWebSocketDisconnected state');
    } catch (e) {
      AppLogger.e('SensorBloc: Exception during WebSocket connection: $e', e);
      emit(SensorFailure(e.toString()));
      AppLogger.d('SensorBloc: Emitted SensorFailure state');

      // Also emit disconnected state
      emit(const SensorWebSocketDisconnected());
      AppLogger.d('SensorBloc: Emitted SensorWebSocketDisconnected state');
    }
  }

  Future<void> _onSensorWebSocketDisconnectRequested(
    SensorWebSocketDisconnectRequested event,
    Emitter<SensorState> emit,
  ) async {
    emit(const SensorLoading());

    try {
      await sensorRepository.disconnectFromWebSocket();
      await _sensorDataSubscription?.cancel();
      _sensorDataSubscription = null;

      emit(const SensorWebSocketDisconnected());
    } on ApiException catch (e) {
      emit(SensorFailure(e.message));
    } catch (e) {
      emit(SensorFailure(e.toString()));
    }
  }

  void _onSensorWebSocketDataReceived(
    SensorWebSocketDataReceivedEvent event,
    Emitter<SensorState> emit,
  ) {
    try {
      AppLogger.d('SensorBloc: Processing WebSocket data: ${event.data}');

      // The SensorData.fromJson method now handles missing fields
      final sensorData = SensorData.fromJson(event.data);
      AppLogger.d(
        'SensorBloc: Parsed sensor data: temp=${sensorData.temperature}, humidity=${sensorData.humidity}, obstacle=${sensorData.obstacle}',
      );

      // Emit the state with the new sensor data
      emit(SensorWebSocketDataReceived(sensorData));
      AppLogger.d('SensorBloc: Emitted SensorWebSocketDataReceived state');
    } catch (e) {
      // Handle any errors during data processing
      AppLogger.e('SensorBloc: Error processing WebSocket data: $e', e);
      emit(SensorFailure(e.toString()));
    }
  }

  Future<void> _onSensorDataClearRequested(
    SensorDataClearRequested event,
    Emitter<SensorState> emit,
  ) async {
    try {
      AppLogger.i('SensorBloc: Clearing all sensor data');

      // Cancel existing subscription if any
      await _sensorDataSubscription?.cancel();
      _sensorDataSubscription = null;

      // Use the repository's clearAllSensorData method to ensure complete cleanup
      await sensorRepository.clearAllSensorData();

      // Emit initial state to clear any cached data
      emit(const SensorInitial());

      // Emit a loading state to indicate that we're starting fresh
      emit(const SensorLoading());

      AppLogger.i('SensorBloc: Sensor data cleared successfully');
    } catch (e) {
      AppLogger.e('SensorBloc: Error clearing sensor data: $e', e);
      emit(SensorFailure(e.toString()));
    }
  }

  Future<void> _onSensorResetRequested(
    SensorResetRequested event,
    Emitter<SensorState> emit,
  ) async {
    try {
      AppLogger.i('SensorBloc: Performing complete reset');

      // First disconnect WebSocket if connected
      if (sensorRepository.isWebSocketConnected()) {
        await sensorRepository.disconnectFromWebSocket();
        AppLogger.i('SensorBloc: WebSocket disconnected during reset');
      }

      // Cancel existing subscription if any
      await _sensorDataSubscription?.cancel();
      _sensorDataSubscription = null;

      // Use the repository's clearAllSensorData method to ensure complete cleanup
      await sensorRepository.clearAllSensorData();

      // Emit initial state to clear any cached data
      emit(const SensorInitial());

      // Log the reset completion
      AppLogger.i('SensorBloc: Reset completed successfully');

      // Wait a moment to ensure all cleanup is complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Emit a loading state to indicate that we're starting fresh
      emit(const SensorLoading());
    } catch (e) {
      AppLogger.e('SensorBloc: Error during reset: $e', e);
      emit(SensorFailure(e.toString()));

      // Even if there's an error, try to reset to initial state
      emit(const SensorInitial());
    }
  }

  @override
  Future<void> close() {
    _sensorDataSubscription?.cancel();
    return super.close();
  }
}
