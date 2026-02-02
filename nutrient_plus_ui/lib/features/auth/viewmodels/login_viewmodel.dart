import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/auth_repository.dart';
import '../models/user.dart';

/// ViewModel for Login screen
class LoginViewModel extends BaseViewModel {
  final AuthRepository _authRepository;

  LoginViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  String _email = '';
  String _password = '';
  User? _user;

  String get email => _email;
  String get password => _password;
  User? get user => _user;

  void setEmail(String value) {
    _email = value;
    clearError();
  }

  void setPassword(String value) {
    _password = value;
    clearError();
  }

  /// Validate input fields
  bool validate() {
    if (_email.isEmpty) {
      setError('Please enter your email');
      return false;
    }
    if (!_email.contains('@')) {
      setError('Please enter a valid email');
      return false;
    }
    if (_password.isEmpty) {
      setError('Please enter your password');
      return false;
    }
    if (_password.length < 6) {
      setError('Password must be at least 6 characters');
      return false;
    }
    return true;
  }

  /// Attempt login
  Future<bool> login() async {
    if (!validate()) return false;

    setLoading(true);
    clearError();

    try {
      final result = await _authRepository.login(
        email: _email,
        password: _password,
      );

      setLoading(false);

      if (result.success) {
        _user = result.user;
        return true;
      } else {
        setError(result.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      setLoading(false);
      setError('Connection error: $e');
      return false;
    }
  }
}
