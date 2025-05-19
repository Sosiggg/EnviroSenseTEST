import 'package:logger/logger.dart';

/// A utility class for logging in the application.
///
/// This class provides a centralized way to log messages with different
/// levels of severity. It uses the `logger` package to format and filter logs.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.debug,
  );

  /// Logs a debug message.
  ///
  /// Use this for detailed information that is useful during development.
  static void d(String message) {
    _logger.d(message);
  }

  /// Logs an info message.
  ///
  /// Use this for general information about app operation.
  static void i(String message) {
    _logger.i(message);
  }

  /// Logs a warning message.
  ///
  /// Use this for potentially harmful situations.
  static void w(String message) {
    _logger.w(message);
  }

  /// Logs an error message.
  ///
  /// Use this for errors that will prevent normal execution.
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a trace message.
  ///
  /// Use this for even more detailed information than debug.
  static void t(String message) {
    _logger.t(message);
  }

  /// Logs a WTF (What a Terrible Failure) message.
  ///
  /// Use this for exceptional failures that should never happen.
  static void wtf(String message) {
    _logger.f(message);
  }
}
