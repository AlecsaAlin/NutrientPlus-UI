import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../auth/models/user.dart';

class HomeViewModel extends BaseViewModel {
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  HomeViewModel({
    UserRepository? userRepository,
    AuthRepository? authRepository,
  })  : _userRepository = userRepository ?? UserRepository(),
        _authRepository = authRepository ?? AuthRepository();

  User? _user;
  int _selectedIndex = 0;

  User? get user => _user;
  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  Future<void> loadUser() async {
    setLoading(true);
    clearError();
    try {
      _user = await _userRepository.getCurrentUser();
    } catch (e) {
      setError('Error loading user: $e');
    }
    setLoading(false);
  }

  void onUserUpdated(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _userRepository.clearCache();
    _user = null;
  }
}
