import '../core/api_client.dart';
import '../models/wallet.dart';

class WalletService {
  WalletService._();

  static final ApiClient _api = ApiClient.instance;

  static Future<Wallet> get() async {
    final data = await _api.get('/wallet') as Map<String, dynamic>;
    return Wallet.fromJson(data);
  }

  static Future<Wallet> recharge(double amount) async {
    final data =
        await _api.post('/wallet/recharge', {'amount': amount}) as Map<String, dynamic>;
    return Wallet.fromJson(data);
  }

  static Future<List<WalletTransaction>> transactions() async {
    final data = await _api.get('/wallet/transactions') as List<dynamic>;
    return data
        .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
