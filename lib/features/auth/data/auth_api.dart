import '../../../core/network/api_client.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  ApiClient get client => _client;
}
