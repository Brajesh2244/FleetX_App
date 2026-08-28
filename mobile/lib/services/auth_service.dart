import '../core/api_client.dart';
import '../core/auth_store.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService._();

  static final ApiClient _api = ApiClient.instance;

  /// Signs in and persists the session. Returns the signed-in user.
  static Future<AppUser> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    }) as Map<String, dynamic>;
    return _persist(data);
  }

  static Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _api.post('/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
    }) as Map<String, dynamic>;
    return _persist(data);
  }

  /// Re-reads the profile from the server (used by the profile screen).
  static Future<AppUser> me() async {
    final data = await _api.get('/auth/me') as Map<String, dynamic>;
    final user = AppUser.fromJson(data);
    await AuthStore.instance.updateUser(user);
    return user;
  }

  /// Simulated - the backend just returns a message, no email is sent.
  static Future<String> forgotPassword(String email) async {
    final data = await _api.post('/auth/forgot-password', {
      'email': email.trim(),
    }) as Map<String, dynamic>;
    return data['message'] as String? ?? 'Reset link sent.';
  }

  /// Simulated OTP - the demo code is always 123456.
  static Future<String> sendOtp(String phone) async {
    final data =
        await _api.post('/auth/otp/send', {'phone': phone}) as Map<String, dynamic>;
    return data['message'] as String? ?? 'OTP sent.';
  }

  static Future<String> verifyOtp(String phone, String otp) async {
    final data = await _api.post('/auth/otp/verify', {
      'phone': phone,
      'otp': otp,
    }) as Map<String, dynamic>;
    return data['message'] as String? ?? 'OTP verified.';
  }

  static Future<void> logout() => AuthStore.instance.logout();

  static Future<AppUser> _persist(Map<String, dynamic> authResponse) async {
    final user = AppUser.fromJson(authResponse);
    await AuthStore.instance.save(authResponse['token'] as String, user);
    return user;
  }
}
