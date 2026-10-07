import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

/// Wallet reads. Session payments never deduct from the wallet on the client:
/// POST /payments/create-intent (useWallet: true) decides server-side.
class WalletRepo {
  final _apiServices = NetworkApiServices();

  /// Fetch the current wallet balance as returned by the server, or null when
  /// the response has no balance.
  Future<double?> getBalance() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final response = await _apiServices.getGetApiResponse(
      AppUrl.walletBalance,
      headers: headers,
    );
    if (response is Map) {
      final balance = response['balance'] ?? response['availableBalance'];
      if (balance is num) return balance.toDouble();
    }
    return null;
  }
}
