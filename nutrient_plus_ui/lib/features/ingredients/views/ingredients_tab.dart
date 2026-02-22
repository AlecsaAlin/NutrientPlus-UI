import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/ingredients_viewmodel.dart';

class IngredientsTab extends StatefulWidget {
  const IngredientsTab({super.key});

  @override
  State<IngredientsTab> createState() => _IngredientsTabState();
}

class _IngredientsTabState extends State<IngredientsTab>
    with SingleTickerProviderStateMixin {
  late IngredientsViewModel _viewModel;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel = IngredientsViewModel();
    _viewModel.loadAll();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _searchController.clear();
        _viewModel.clearIngredientSearch();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<IngredientsViewModel>(
        builder: (context, viewModel, child) {
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
                            Flexible(
                              child: Text(
                                'Liked (${viewModel.likedIngredients.length})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.block, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Excluded (${viewModel.excludedIngredients.length})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                    _buildIngredientPage(
                      viewModel: viewModel,
                      isLiked: true,
                    ),
                    _buildIngredientPage(
                      viewModel: viewModel,
                      isLiked: false,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shared page builder for both Liked and Excluded tabs
  Widget _buildIngredientPage({
    required IngredientsViewModel viewModel,
    required bool isLiked,
  }) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final searchCount = viewModel.ingredientSearchResults.length;
    final list = isLiked ? viewModel.likedIngredients : viewModel.excludedIngredients;
    final isLoading = isLiked ? viewModel.isLoadingLiked : viewModel.isLoadingIngredients;
    final color = isLiked ? Colors.green[600]! : AppColors.error;
    final icon = isLiked ? Icons.favorite : Icons.block;
    final emptyTitle = isLiked ? 'No liked ingredients' : 'No excluded ingredients';
    final emptySubtitle = isLiked
        ? 'Search and add ingredients you enjoy.'
        : 'Search and add ingredients you want to avoid in your meal plan.';
    final addIcon = isLiked ? Icons.favorite_border : Icons.block;

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLiked ? 'Liked Ingredients' : 'Excluded Ingredients',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLiked
                      ? 'Ingredients you enjoy — saved as your personal preference list.'
                      : 'Recipes with these ingredients will be excluded from your meal plan.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isLiked
                    ? 'Search ingredient to like...'
                    : 'Search ingredient to exclude...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.clearIngredientSearch();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {});
                viewModel.searchIngredients(value);
              },
            ),
          ),
        ),

        if (viewModel.isSearchingIngredients)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: LinearProgressIndicator(color: AppColors.primary),
            ),
          ),

        if (viewModel.ingredientSearchResults.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: searchCount,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    final ingredient =
                        viewModel.ingredientSearchResults[index];
                    final alreadyAdded = list.contains(ingredient);
                    return ListTile(
                      dense: true,
                      title: Text(ingredient,
                          style: const TextStyle(fontSize: 14)),
                      trailing: alreadyAdded
                          ? Icon(Icons.check_circle, color: color, size: 20)
                          : Icon(addIcon, color: Colors.grey[400], size: 20),
                      onTap: alreadyAdded
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              if (isLiked) {
                                await viewModel.addLikedIngredient(ingredient);
                              } else {
                                await viewModel.addExcludedIngredient(ingredient);
                              }
                              _searchController.clear();
                              viewModel.clearIngredientSearch();
                              setState(() {});
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '"$ingredient" added to ${isLiked ? 'liked' : 'excluded'} list'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                    );
                  },
                ),
              ),
            ),
          ),

        if (isLoading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: const Center(child: CircularProgressIndicator()),
            ),
          )

        else if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: _buildEmptyState(
                icon: isLiked ? Icons.favorite_border : Icons.no_meals_outlined,
                title: emptyTitle,
                subtitle: emptySubtitle,
              ),
            ),
          )

        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '${list.length} ${isLiked ? 'liked' : 'excluded'} ingredient${list.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ingredient = list[index];
                  return Dismissible(
                    key: Key('${isLiked ? 'liked' : 'excl'}-$ingredient'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final success = isLiked
                          ? await viewModel.removeLikedIngredient(ingredient)
                          : await viewModel.removeExcludedIngredient(ingredient);
                      if (!success) {
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Failed to remove ingredient')),
                        );
                      }
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ingredient,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline,
                                color: Colors.grey[400]),
                            onPressed: () async {
                              if (isLiked) {
                                await viewModel.removeLikedIngredient(ingredient);
                              } else {
                                await viewModel.removeExcludedIngredient(ingredient);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: list.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
