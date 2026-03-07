import 'package:dio/dio.dart';

class ApiResponse<T> {
  final T? data;
  final int? statusCode;
  final String? message;

  const ApiResponse({this.data, this.statusCode, this.message});

  factory ApiResponse.fromResponse(Response response, T data) {
    return ApiResponse(
      data: data,
      statusCode: response.statusCode,
      message: response.statusMessage,
    );
  }
}
