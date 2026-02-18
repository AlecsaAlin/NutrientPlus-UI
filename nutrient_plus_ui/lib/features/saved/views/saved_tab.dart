import 'package:flutter/material.dart';
import '../../meal_plan/models/meal_models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class SavedRecipesTab extends StatefulWidget {
  const SavedRecipesTab({super.key});

  @override
  State<SavedRecipesTab> createState() => _SavedRecipesTabState();
}

class _SavedRecipesTabState extends State<SavedRecipesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<FavoriteRecipe> _favorites = [];
  List<UserRating> _ratings = [];
  bool _isLoadingFavorites = true;
  bool _isLoadingRatings = true;

  // Reviews sort: 'time' or 'score'
  String _reviewSort = 'time';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() {
    return Future.wait([
      _loadFavorites(),
      _loadRatings(),
    ]);
  }

  Future<void> _loadFavorites() async {
    final result = await ApiService.getFavorites();
    if (mounted) {
      setState(() {
        _isLoadingFavorites = false;
        if (result.success && result.favorites != null) {
          _favorites = result.favorites!;
        }
      });
    }
  }

  Future<void> _loadRatings() async {
    final result = await ApiService.getUserRatings();
    if (mounted) {
      setState(() {
        _isLoadingRatings = false;
        if (result.success && result.ratings != null) {
          _ratings = result.ratings!;
        }
      });
    }
  }

  List<UserRating> get _sortedRatings {
    final sorted = List<UserRating>.from(_ratings);
    if (_reviewSort == 'score') {
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
    }
    // 'time' is the default order from the API (most recent first)
    return sorted;
  }

  Future<void> _removeFavorite(FavoriteRecipe fav) async {
    setState(() {
      _favorites.remove(fav);
    });
    final success = await ApiService.removeFavorite(recipeId: fav.recipeId);
    if (!success && mounted) {
      setState(() {
        _favorites.add(fav);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove favorite')),
      );
    }
  }

  Future<void> _deleteRating(UserRating rating) async {
    setState(() {
      _ratings.remove(rating);
    });
    final success =
        await ApiService.deleteRecipeRating(recipeId: rating.recipeId);
    if (!success && mounted) {
      setState(() {
        _ratings.add(rating);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, size: 18),
                      const SizedBox(width: 6),
                      Text('Favorites (${_favorites.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, size: 18),
                      const SizedBox(width: 6),
                      Text('Reviews (${_ratings.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFavoritesPage(),
              _buildReviewsPage(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Favorites page ────────────────────────────────────

  Widget _buildFavoritesPage() {
    if (_isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'No favorites yet',
        subtitle: 'Tap the heart icon on a recipe to save it here',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final fav = _favorites[index];
          return _buildFavoriteCard(fav);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteRecipe fav) {
    final name = fav.recipeName.isNotEmpty
        ? fav.recipeName
        : 'Recipe #${fav.recipeId}';
    final timeAgo = _timeAgo(fav.createdAt);

    return Dismissible(
      key: Key('fav-${fav.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeFavorite(fav),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _onRecipeTap(fav.recipeId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.favorite, color: Colors.red[400], size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fav.calories.round()} kcal  \u2022  $timeAgo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMacroChip('P', '${fav.proteinG.toInt()}g', Colors.red[400]!),
                  const SizedBox(width: 8),
                  _buildMacroChip('C', '${fav.carbsG.toInt()}g', Colors.blue[400]!),
                  const SizedBox(width: 8),
                  _buildMacroChip('F', '${fav.fatG.toInt()}g', Colors.amber[600]!),
                  if (fav.totalTimeMinutes != null) ...[
                    const SizedBox(width: 8),
                    _buildMacroChip('', '${fav.totalTimeMinutes} min', Colors.grey[500]!,
                        icon: Icons.timer_outlined),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reviews page ──────────────────────────────────────

  Widget _buildReviewsPage() {
    if (_isLoadingRatings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ratings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_border,
        title: 'No reviews yet',
        subtitle: 'Rate a recipe to see your reviews here',
      );
    }

    final sorted = _sortedRatings;

    return Column(
      children: [
        // Sort bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              _buildSortChip('time', 'Most recent'),
              const SizedBox(width: 8),
              _buildSortChip('score', 'Highest rated'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadRatings,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                return _buildRatingCard(sorted[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String value, String label) {
    final selected = _reviewSort == value;
    return GestureDetector(
      onTap: () => setState(() => _reviewSort = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCard(UserRating rating) {
    final name = rating.recipeName.isNotEmpty
        ? rating.recipeName
        : 'Recipe #${rating.recipeId}';
    final timeAgo = _timeAgo(rating.updatedAt);

    return Dismissible(
      key: Key('rating-${rating.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteRating(rating),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _onRecipeTap(rating.recipeId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: AppColors.warning, size: 18),
                        Text(
                          rating.rating.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                i < rating.rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
                                color: AppColors.warning,
                              );
                            }),
                            _dot(),
                            Text(
                              '${rating.calories.round()} kcal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            _dot(),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMacroChip('P', '${rating.proteinG.toInt()}g', Colors.red[400]!),
                  const SizedBox(width: 8),
                  _buildMacroChip('C', '${rating.carbsG.toInt()}g', Colors.blue[400]!),
                  const SizedBox(width: 8),
                  _buildMacroChip('F', '${rating.fatG.toInt()}g', Colors.amber[600]!),
                  if (rating.totalTimeMinutes != null) ...[
                    const SizedBox(width: 8),
                    _buildMacroChip('', '${rating.totalTimeMinutes} min', Colors.grey[500]!,
                        icon: Icons.timer_outlined),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recipe detail sheet ───────────────────────────────

  Future<void> _onRecipeTap(int recipeId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final recipe = await ApiService.getRecipeById(recipeId: recipeId);
    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (recipe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load recipe details')),
      );
      return;
    }

    _showRecipeDetails(recipe);
  }

  void _showRecipeDetails(RecipeDetail recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (recipe.category != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    recipe.category!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 16),
                // Nutrition chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(
                        '${recipe.calories.round()} cal', Icons.local_fire_department),
                    _infoChip('${recipe.proteinG.round()}g P', Icons.fitness_center),
                    _infoChip('${recipe.carbsG.round()}g C', Icons.grain),
                    _infoChip('${recipe.fatG.round()}g F', Icons.opacity),
                    if (recipe.totalTimeMinutes != null)
                      _infoChip('${recipe.totalTimeMinutes} min', Icons.timer),
                  ],
                ),
                if (recipe.ingredients != null &&
                    recipe.ingredients!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (recipe.numIngredients != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${recipe.numIngredients}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cleanIngredients(recipe.ingredients!),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                if (recipe.instructions != null &&
                    recipe.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cleanInstructions(recipe.instructions!),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────

  Widget _infoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryWithOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          if (label.isNotEmpty)
            Text(
              '$label ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '\u2022',
        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // ── Text cleaning (same logic as meal_plan_tab) ──────

  String _cleanText(String text) {
    String cleaned = text;
    if (cleaned.startsWith('c(') ||
        cleaned.startsWith('c"') ||
        cleaned.startsWith("c'")) {
      cleaned = cleaned.substring(1);
    }
    cleaned = cleaned.replaceAll('"', '').replaceAll("'", '');
    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned.trim();
  }

  List<String> _parseIngredients(String ingredients) {
    String cleaned = _cleanText(ingredients);
    return cleaned
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _cleanIngredients(String ingredients) {
    final items = _parseIngredients(ingredients);
    if (items.isEmpty) return '';
    return items.map((e) => '\u2022 $e').join('\n');
  }

  String _cleanInstructions(String instructions) {
    String cleaned = _cleanText(instructions);
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\.\s*,?\s*'),
      (match) => '.\n\n',
    );
    return cleaned.trim();
  }
}
