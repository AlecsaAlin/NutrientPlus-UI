import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/user_repository.dart';

class IngredientsViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  IngredientsViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  List<String> _excludedIngredients = [];
  bool _isLoadingIngredients = true;

  List<String> _likedIngredients = [];
  bool _isLoadingLiked = true;

  List<String> _ingredientSearchResults = [];
  bool _isSearchingIngredients = false;

  List<String> get excludedIngredients => _excludedIngredients;
  bool get isLoadingIngredients => _isLoadingIngredients;
  List<String> get likedIngredients => _likedIngredients;
  bool get isLoadingLiked => _isLoadingLiked;
  List<String> get ingredientSearchResults => _ingredientSearchResults;
  bool get isSearchingIngredients => _isSearchingIngredients;

  Future<void> loadAll() {
    return Future.wait([
      loadExcludedIngredients(),
      loadLikedIngredients(),
    ]);
  }

  Future<void> loadExcludedIngredients() async {
    _excludedIngredients = await _userRepository.getExcludedIngredients();
    _isLoadingIngredients = false;
    notifyListeners();
  }

  Future<void> loadLikedIngredients() async {
    _likedIngredients = await _userRepository.getLikedIngredients();
    _isLoadingLiked = false;
    notifyListeners();
  }

  Future<void> searchIngredients(String query) async {
    if (query.trim().isEmpty) {
      _ingredientSearchResults = [];
      notifyListeners();
      return;
    }

    _isSearchingIngredients = true;
    notifyListeners();

    _ingredientSearchResults =
        await _userRepository.searchIngredients(query: query);
    _isSearchingIngredients = false;
    notifyListeners();
  }

  void clearIngredientSearch() {
    _ingredientSearchResults = [];
    notifyListeners();
  }

  Future<bool> addExcludedIngredient(String ingredient) async {
    if (_excludedIngredients.contains(ingredient)) return true;

    _excludedIngredients = [..._excludedIngredients, ingredient];
    notifyListeners();

    final success =
        await _userRepository.addExcludedIngredient(ingredient: ingredient);
    if (!success) {
      _excludedIngredients =
          _excludedIngredients.where((i) => i != ingredient).toList();
      notifyListeners();
    }
    return success;
  }

  Future<bool> removeExcludedIngredient(String ingredient) async {
    _excludedIngredients =
        _excludedIngredients.where((i) => i != ingredient).toList();
    notifyListeners();

    final success =
        await _userRepository.removeExcludedIngredient(ingredient: ingredient);
    if (!success) {
      _excludedIngredients = [..._excludedIngredients, ingredient];
      notifyListeners();
    }
    return success;
  }

  Future<bool> addLikedIngredient(String ingredient) async {
    if (_likedIngredients.contains(ingredient)) return true;

    _likedIngredients = [..._likedIngredients, ingredient];
    notifyListeners();

    final success =
        await _userRepository.addLikedIngredient(ingredient: ingredient);
    if (!success) {
      _likedIngredients =
          _likedIngredients.where((i) => i != ingredient).toList();
      notifyListeners();
    }
    return success;
  }

  Future<bool> removeLikedIngredient(String ingredient) async {
    _likedIngredients =
        _likedIngredients.where((i) => i != ingredient).toList();
    notifyListeners();

    final success =
        await _userRepository.removeLikedIngredient(ingredient: ingredient);
    if (!success) {
      _likedIngredients = [..._likedIngredients, ingredient];
      notifyListeners();
    }
    return success;
  }
}
