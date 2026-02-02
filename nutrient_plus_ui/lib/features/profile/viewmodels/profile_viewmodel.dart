import 'dart:io';
import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/user_repository.dart';
import '../../auth/models/user.dart';

/// ViewModel for Profile screen
class ProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  ProfileViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  User? _user;
  File? _profileImage;

  User? get user => _user;
  File? get profileImage => _profileImage;

  /// Load user data
  Future<void> loadUser({bool forceRefresh = false}) async {
    setLoading(true);
    clearError();

    try {
      _user = await _userRepository.getCurrentUser(forceRefresh: forceRefresh);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      setError('Error loading profile: $e');
    }
  }

  /// Update profile image locally
  void setProfileImage(File image) {
    _profileImage = image;
    notifyListeners();
  }

  /// Update gender
  Future<void> updateGender(String gender) async {
    // Optimistic update
    _user = _user?.copyWith(gender: gender);
    notifyListeners();

    final result = await _userRepository.updateProfile(gender: gender);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update current weight
  Future<void> updateCurrentWeight(double weight) async {
    _user = _user?.copyWith(currentWeight: weight);
    notifyListeners();

    final result = await _userRepository.updateProfile(currentWeight: weight);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update goal weight
  Future<void> updateGoalWeight(double weight) async {
    _user = _user?.copyWith(goalWeight: weight);
    notifyListeners();

    final result = await _userRepository.updateProfile(goalWeight: weight);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update height
  Future<void> updateHeight(double height) async {
    _user = _user?.copyWith(height: height);
    notifyListeners();

    final result = await _userRepository.updateProfile(height: height);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update age
  Future<void> updateAge(int age) async {
    _user = _user?.copyWith(age: age);
    notifyListeners();

    final result = await _userRepository.updateProfile(age: age);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update profile image path
  Future<void> updateProfileImagePath(String path) async {
    final result = await _userRepository.updateProfile(profileImagePath: path);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }
}
