import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  static const String baseUrl = 'https://backend-production-0935.up.railway.app';

  static final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ));
}
