import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../config/constants.dart';
import 'api_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient({AppConfig config = AppConfig.prod})
      : dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
          ),
        ) {
    dio.interceptors.add(ApiInterceptor());
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    return dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path, dynamic data) async {
    return dio.post(path, data: data);
  }
}
