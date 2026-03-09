import '../../../core/network/api_client.dart';

class ProductApi {
  final ApiClient _client;

  ProductApi(this._client);

  ApiClient get client => _client;
}
