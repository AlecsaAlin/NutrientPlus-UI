import 'package:flutter/foundation.dart';

/// Base ViewModel class that all ViewModels should extend
/// Provides common functionality like loading state, error handling, and disposal
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Set loading state and notify listeners
  void setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message and notify listeners
  void setError(String? message) {
    if (_isDisposed) return;
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    setError(null);
  }

  /// Safe notify listeners (checks if disposed)
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
