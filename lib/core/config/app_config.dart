import 'env.dart';

class AppConfig {
  final String baseUrl;

  const AppConfig({required this.baseUrl});

  static const AppConfig prod = AppConfig(baseUrl: Env.baseUrl);
}
