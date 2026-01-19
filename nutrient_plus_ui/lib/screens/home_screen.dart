import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'watch_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  User? _user;
  bool _isLoadingUser = true;
  
  // Selected day for the week view
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0 = Monday

  // Inventory items
  final List<InventoryItem> _inventoryItems = [
    InventoryItem(name: 'Eggs', quantity: '12', category: 'Dairy', emoji: '🥚'),
    InventoryItem(name: 'Milk', quantity: '1L', category: 'Dairy', emoji: '🥛'),
    InventoryItem(name: 'Chicken Breast', quantity: '500g', category: 'Meat', emoji: '🍗'),
    InventoryItem(name: 'Broccoli', quantity: '2', category: 'Vegetables', emoji: '🥦'),
    InventoryItem(name: 'Rice', quantity: '1kg', category: 'Grains', emoji: '🍚'),
    InventoryItem(name: 'Apples', quantity: '6', category: 'Fruits', emoji: '🍎'),
  ];

  // TODO: This will be replaced with AI-generated meals from backend
  // For now, using placeholder data
  final Map<int, DayMealPlan> _weeklyMeals = {
    0: DayMealPlan( // Monday
      breakfast: MealItem(name: 'Oatmeal with Berries', calories: 350, emoji: '🥣'),
      lunch: MealItem(name: 'Grilled Chicken Salad', calories: 450, emoji: '🥗'),
      snack: MealItem(name: 'Greek Yogurt', calories: 150, emoji: '🥛'),
      dinner: MealItem(name: 'Salmon with Vegetables', calories: 550, emoji: '🐟'),
    ),
    1: DayMealPlan( // Tuesday
      breakfast: MealItem(name: 'Scrambled Eggs & Toast', calories: 400, emoji: '🍳'),
      lunch: MealItem(name: 'Turkey Sandwich', calories: 480, emoji: '🥪'),
      snack: MealItem(name: 'Apple & Almond Butter', calories: 200, emoji: '🍎'),
      dinner: MealItem(name: 'Pasta Primavera', calories: 520, emoji: '🍝'),
    ),
    2: DayMealPlan( // Wednesday
      breakfast: MealItem(name: 'Smoothie Bowl', calories: 380, emoji: '🫐'),
      lunch: MealItem(name: 'Buddha Bowl', calories: 500, emoji: '🥙'),
      snack: MealItem(name: 'Protein Bar', calories: 180, emoji: '🍫'),
      dinner: MealItem(name: 'Grilled Steak & Potatoes', calories: 650, emoji: '🥩'),
    ),
    3: DayMealPlan( // Thursday
      breakfast: MealItem(name: 'Avocado Toast', calories: 320, emoji: '🥑'),
      lunch: MealItem(name: 'Chicken Wrap', calories: 450, emoji: '🌯'),
      snack: MealItem(name: 'Mixed Nuts', calories: 170, emoji: '🥜'),
      dinner: MealItem(name: 'Fish Tacos', calories: 480, emoji: '🌮'),
    ),
    4: DayMealPlan( // Friday
      breakfast: MealItem(name: 'Pancakes & Fruit', calories: 450, emoji: '🥞'),
      lunch: MealItem(name: 'Sushi Bowl', calories: 520, emoji: '🍱'),
      snack: MealItem(name: 'Hummus & Veggies', calories: 160, emoji: '🥕'),
      dinner: MealItem(name: 'Pizza Night', calories: 700, emoji: '🍕'),
    ),
    5: DayMealPlan( // Saturday
      breakfast: MealItem(name: 'French Toast', calories: 420, emoji: '🍞'),
      lunch: MealItem(name: 'Burger & Fries', calories: 750, emoji: '🍔'),
      snack: MealItem(name: 'Fruit Smoothie', calories: 200, emoji: '🍓'),
      dinner: MealItem(name: 'BBQ Chicken', calories: 580, emoji: '🍗'),
    ),
    6: DayMealPlan( // Sunday
      breakfast: MealItem(name: 'Eggs Benedict', calories: 480, emoji: '🍳'),
      lunch: MealItem(name: 'Roast Chicken', calories: 550, emoji: '🍖'),
      snack: MealItem(name: 'Cheese & Crackers', calories: 220, emoji: '🧀'),
      dinner: MealItem(name: 'Soup & Salad', calories: 380, emoji: '🥗'),
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ApiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error loading user: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'NutrientPlus',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          if (!_isLoadingUser && _user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF2D5016),
                        child: Text(
                          _user!.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _user!.username,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF1A1A1A)),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_user!.username),
                            Text(
                              _user!.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    _logout();
                  }
                },
              ),
            ),
          if (_isLoadingUser)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2D5016),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2D5016),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Meal Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.watch),
            label: 'Watch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildWeeklyMealPlan();
      case 1:
        return _buildInventoryPage();
      case 2:
        return const WatchScreen();
      case 3:
        return _buildProfilePage();
      default:
        return _buildWeeklyMealPlan();
    }
  }

  Widget _buildWeeklyMealPlan() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = DateTime.now().weekday - 1;
    
    // Calculate dates for the current week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    // Get meals for selected day
    final dayMeals = _weeklyMeals[_selectedDayIndex];
    final totalCalories = dayMeals != null 
        ? dayMeals.breakfast.calories + dayMeals.lunch.calories + 
          dayMeals.snack.calories + dayMeals.dinner.calories
        : 0;
    
    return Column(
      children: [
        // Week day selector
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isSelected = index == _selectedDayIndex;
              final isToday = index == today;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: Container(
                  width: 46,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF2D5016) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF2D5016), width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                              ? Colors.white 
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        
        // Selected day content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day header with total calories
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullDays[_selectedDayIndex],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDayIndex == today ? 'Today' : '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5016).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Color(0xFF2D5016),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalCalories kcal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5016),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Meal cards
                if (dayMeals != null) ...[
                  _buildMealCard(
                    mealType: 'Breakfast',
                    time: '7:00 - 9:00',
                    meal: dayMeals.breakfast,
                    color: const Color(0xFFFFB347),
                  ),
                  _buildMealCard(
                    mealType: 'Lunch',
                    time: '12:00 - 14:00',
                    meal: dayMeals.lunch,
                    color: const Color(0xFF4CAF50),
                  ),
                  _buildMealCard(
                    mealType: 'Snack',
                    time: '16:00 - 17:00',
                    meal: dayMeals.snack,
                    color: const Color(0xFF9C27B0),
                  ),
                  _buildMealCard(
                    mealType: 'Dinner',
                    time: '19:00 - 21:00',
                    meal: dayMeals.dinner,
                    color: const Color(0xFF2196F3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required String mealType,
    required String time,
    required MealItem meal,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          // Emoji container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                meal.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Meal info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mealType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          // Calories
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${meal.calories} kcal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF2D5016),
            child: Text(
              _user?.username[0].toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _user?.username ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryPage() {
    // Group items by category
    final Map<String, List<InventoryItem>> groupedItems = {};
    for (var item in _inventoryItems) {
      if (!groupedItems.containsKey(item.category)) {
        groupedItems[item.category] = [];
      }
      groupedItems[item.category]!.add(item);
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Inventory',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_inventoryItems.length} items in your fridge',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: _inventoryItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.kitchen_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your inventory is empty',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add items',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groupedItems.keys.length,
                  itemBuilder: (context, index) {
                    final category = groupedItems.keys.elementAt(index);
                    final items = groupedItems[category]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...items.map((item) => _buildInventoryItem(item)),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInventoryItem(InventoryItem item) {
    return Dismissible(
      key: Key(item.name),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _inventoryItems.remove(item);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _inventoryItems.add(item);
                });
              },
            ),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              item.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.quantity,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    String selectedCategory = 'Vegetables';
    String selectedEmoji = '🥦';

    final categories = {
      'Vegetables': '🥦',
      'Fruits': '🍎',
      'Meat': '🍗',
      'Dairy': '🥛',
      'Grains': '🍚',
      'Other': '🍽️',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. Tomatoes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g. 500g, 2L, 6',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: categories.keys.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Text(categories[cat]!),
                          const SizedBox(width: 8),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                      selectedEmoji = categories[value]!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                  setState(() {
                    _inventoryItems.add(InventoryItem(
                      name: nameController.text,
                      quantity: quantityController.text,
                      category: selectedCategory,
                      emoji: selectedEmoji,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// Data models for meals
class MealItem {
  final String name;
  final int calories;
  final String emoji;

  MealItem({
    required this.name,
    required this.calories,
    required this.emoji,
  });
}

class DayMealPlan {
  final MealItem breakfast;
  final MealItem lunch;
  final MealItem snack;
  final MealItem dinner;

  DayMealPlan({
    required this.breakfast,
    required this.lunch,
    required this.snack,
    required this.dinner,
  });
}

class InventoryItem {
  final String name;
  final String quantity;
  final String category;
  final String emoji;

  InventoryItem({
    required this.name,
    required this.quantity,
    required this.category,
    required this.emoji,
  });
}
