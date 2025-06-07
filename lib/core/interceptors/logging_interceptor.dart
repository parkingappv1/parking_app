import 'package:dio/dio.dart';
import 'package:parking_app/core/utils/logger.dart'; // Import the logger

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    appLogger.info('REQUEST[${options.method}] => PATH: ${options.path}');
    if (options.data != null) {
      appLogger.debug('Data: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      appLogger.debug('Query: ${options.queryParameters}');
    }
    if (options.headers.isNotEmpty) {
      appLogger.debug('Headers: ${options.headers}');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    appLogger.info(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    appLogger.debug('Response Data: ${response.data}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    appLogger.error(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      err,
      err.stackTrace,
    );
    if (err.response != null) {
      appLogger.debug('Error Response Data: ${err.response?.data}');
    }
    return handler.next(err);
  }
}
