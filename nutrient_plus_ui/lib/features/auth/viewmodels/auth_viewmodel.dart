import '../../../core/base/base_viewmodel.dart';
import '../models/user.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/user_repository.dart';

class AuthViewModel extends BaseViewModel {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthViewModel({AuthRepository? authRepository, UserRepository? userRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository();

  User? _user;
  User? get user => _user;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );

      if (result.success) {
        _user = result.user;
        _isAuthenticated = true;
        setLoading(false);
        return true;
      } else {
        setError(result.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      setError('Connection error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authRepository.register(
        email: email,
        username: username,
        password: password,
      );

      if (result.success) {
        _user = result.user;
        _isAuthenticated = true;
        setLoading(false);
        return true;
      } else {
        setError(result.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      setError('Connection error: $e');
      return false;
    }
  }

  Future<bool> checkAuthStatus() async {
    setLoading(true);

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        _user = await _userRepository.getCurrentUser();
        _isAuthenticated = _user != null;
      } else {
        _isAuthenticated = false;
      }

      setLoading(false);
      return _isAuthenticated;
    } catch (e) {
      _isAuthenticated = false;
      setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
