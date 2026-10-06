import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class WalletRepo {
  final _apiServices = NetworkApiServices();

  /// Deduct [amount] from the user's wallet.
  ///
  /// [description] — human-readable reason shown in the wallet history.
  /// [idempotencyKey] — optional UUID to prevent double-charging on retries.
  Future<Map<String, dynamic>> deduct({
    required double amount,
    required String description,
    String? idempotencyKey,
  }) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    final body = {
      'amount': amount,
      'description': description,
    };
    final response = await _apiServices.getPostApiResponse(
      AppUrl.walletDeduct,
      body,
      headers,
    );
    if (response is Map<String, dynamic>) return response;
    return {'success': true, 'data': response};
  }

  /// Fetch the current wallet balance.
  Future<double> getBalance() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final response = await _apiServices.getGetApiResponse(
      AppUrl.walletBalance,
      headers: headers,
    );
    if (response is Map) {
      final balance = response['balance'] ?? response['availableBalance'];
      return (balance as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }
}
