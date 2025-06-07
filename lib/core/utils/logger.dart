import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final AppLogger appLogger = AppLogger();

class AppLogger {
  static final Logger _logger = Logger('App');

  AppLogger() {
    Logger.root.level =
        kDebugMode ? Level.ALL : Level.OFF; // Configure log levels
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        // In debug mode, print to console
        // You can customize the format or use a more sophisticated logger like `talker`
        // for better formatting and features if needed.
        // ignore: avoid_print
        print(
          '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
        );
        if (record.error != null) {
          // ignore: avoid_print
          print('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          // ignore: avoid_print
          print('StackTrace: ${record.stackTrace}');
        }
      }
    });
  }

  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.fine(message, error, stackTrace);
  }

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  void wtf(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.shout(message, error, stackTrace);
  }
}
