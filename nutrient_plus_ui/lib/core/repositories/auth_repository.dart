import '../services/auth_service.dart';

/// Repository for authentication operations
class AuthRepository {
  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
  }) async {
    return await AuthService.register(
      email: email,
      username: username,
      password: password,
    );
  }

  /// Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return await AuthService.login(
      email: email,
      password: password,
    );
  }

  /// Logout user
  Future<void> logout() async {
    await AuthService.logout();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await AuthService.isLoggedIn();
  }

  /// Get authentication token
  Future<String?> getToken() async {
    return await AuthService.getToken();
  }
}
