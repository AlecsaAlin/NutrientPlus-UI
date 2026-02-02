import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/auth_repository.dart';
import '../models/user.dart';

/// ViewModel for Register screen
class RegisterViewModel extends BaseViewModel {
  final AuthRepository _authRepository;

  RegisterViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  String _email = '';
  String _username = '';
  String _password = '';
  String _confirmPassword = '';
  User? _user;

  String get email => _email;
  String get username => _username;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  User? get user => _user;

  void setEmail(String value) {
    _email = value;
    clearError();
  }

  void setUsername(String value) {
    _username = value;
    clearError();
  }

  void setPassword(String value) {
    _password = value;
    clearError();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    clearError();
  }

  /// Validate input fields
  bool validate() {
    if (_username.isEmpty) {
      setError('Please enter a username');
      return false;
    }
    if (_username.length < 3) {
      setError('Username must be at least 3 characters');
      return false;
    }
    if (_email.isEmpty) {
      setError('Please enter your email');
      return false;
    }
    if (!_email.contains('@')) {
      setError('Please enter a valid email');
      return false;
    }
    if (_password.isEmpty) {
      setError('Please enter a password');
      return false;
    }
    if (_password.length < 6) {
      setError('Password must be at least 6 characters');
      return false;
    }
    if (_password != _confirmPassword) {
      setError('Passwords do not match');
      return false;
    }
    return true;
  }

  /// Attempt registration
  Future<bool> register() async {
    if (!validate()) return false;

    setLoading(true);
    clearError();

    try {
      final result = await _authRepository.register(
        email: _email,
        username: _username,
        password: _password,
      );

      setLoading(false);

      if (result.success) {
        _user = result.user;
        return true;
      } else {
        setError(result.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      setLoading(false);
      setError('Eroare de conexiune: $e');
      return false;
    }
  }
}
