import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/watch_viewmodel.dart';

class WatchTab extends StatefulWidget {
  const WatchTab({super.key});

  @override
  State<WatchTab> createState() => _WatchTabState();
}

class _WatchTabState extends State<WatchTab> {
  late WatchViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WatchViewModel();
    _viewModel.initHealth();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String _formatSleepDuration(double hours) {
    if (hours <= 0) return '--';
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  String _formatSteps(int steps) {
    return steps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<WatchViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2D5016)),
                  SizedBox(height: 16),
                  Text('Loading health data...'),
                ],
              ),
            );
          }

          if (!viewModel.isAuthorized) {
            return _buildPermissionScreen(viewModel);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await viewModel.fetchHealthData();
              await viewModel.fetchWeeklyData();
            },
            color: const Color(0xFF2D5016),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildDateScroller(viewModel),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInsightPill(viewModel),
                        const SizedBox(height: 20),
                        _buildActivityGrid(viewModel),
                        const SizedBox(height: 16),
                        _buildWeeklyChart(viewModel),
                        const SizedBox(height: 16),
                        _buildWeeklyCaloriesChart(viewModel),
                        const SizedBox(height: 16),
                        _buildSleepCard(viewModel),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionScreen(WatchViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.watch,
                size: 48,
                color: Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Health Sync',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to Health Connect to sync your fitness data',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => viewModel.requestPermissions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.health_and_safety),
                  SizedBox(width: 8),
                  Text('Connect Health', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final success = await viewModel.openHealthConnect();
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please open Health Connect manually from Settings'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text(
                'Open Health Connect Settings',
                style: TextStyle(color: Color(0xFF2D5016)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateScroller(WatchViewModel viewModel) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(30, (index) {
            final reversedIndex = 29 - index;
            final date = now.subtract(Duration(days: reversedIndex));
            final isSelected = reversedIndex == viewModel.selectedDayIndex;
            final isToday = reversedIndex == 0;

            String dayName;
            if (isToday) {
              dayName = 'Today';
            } else if (reversedIndex == 1) {
              dayName = 'Yday';
            } else {
              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              dayName = days[date.weekday - 1];
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => viewModel.setSelectedDayIndex(reversedIndex),
                child: Container(
                  width: 56,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2D5016) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? null : Border.all(color: Colors.grey[200]!),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFF2D5016).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      Text(
                        _getMonthAbbr(date.month),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white60 : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInsightPill(WatchViewModel viewModel) {
    final stepsPercent = (viewModel.steps / 10000 * 100).clamp(0, 100).toInt();
    String message;
    IconData icon;

    if (stepsPercent >= 100) {
      message = 'Goal achieved! You\'ve reached 10,000 steps';
      icon = Icons.emoji_events;
    } else if (stepsPercent >= 75) {
      message = 'Great progress! ${_formatSteps(10000 - viewModel.steps)} steps to go';
      icon = Icons.local_fire_department;
    } else if (stepsPercent >= 50) {
      message = 'Keep moving! You\'re halfway there';
      icon = Icons.directions_walk;
    } else {
      message = 'Let\'s get moving! ${_formatSteps(10000 - viewModel.steps)} steps to goal';
      icon = Icons.fitness_center;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFFFF9B85), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9B85).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF9B85), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid(WatchViewModel viewModel) {
    return Row(
      children: [
        // Steps Card
        Expanded(
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.directions_walk, color: Colors.blue[500], size: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${((viewModel.steps / 10000) * 100).clamp(0, 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatSteps(viewModel.steps),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Steps',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (viewModel.steps / 10000).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[500]!),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Calories Card
        Expanded(
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_fire_department, color: Colors.orange[500], size: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5016).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.trending_up, color: Color(0xFF2D5016), size: 12),
                          SizedBox(width: 2),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5016),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.caloriesBurned.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'kcal burned',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (viewModel.caloriesBurned / 2000).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[500]!),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(WatchViewModel viewModel) {
    final now = DateTime.now();
    final maxSteps = viewModel.weeklySteps.isEmpty ? 0 : viewModel.weeklySteps.reduce((a, b) => a > b ? a : b);
    final totalSteps = viewModel.weeklySteps.isEmpty ? 0 : viewModel.weeklySteps.reduce((a, b) => a + b);
    final avgSteps = viewModel.weeklySteps.isEmpty ? 0 : (totalSteps / 7).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_walk, color: Colors.blue[500], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Steps - Last 7 Days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Avg: ${_formatSteps(avgSteps)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final steps = viewModel.weeklySteps.length > index ? viewModel.weeklySteps[index] : 0;
              final barHeight = maxSteps > 0
                  ? (steps / maxSteps * 60).clamp(4.0, 60.0)
                  : 4.0;
              final isToday = index == 6;

              final date = now.subtract(Duration(days: 6 - index));
              final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final dayLabel = dayLabels[date.weekday - 1];

              String stepsLabel;
              if (steps >= 1000) {
                stepsLabel = '${(steps / 1000).toStringAsFixed(1)}k';
              } else {
                stepsLabel = '$steps';
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stepsLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isToday ? const Color(0xFF2D5016) : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF2D5016)
                              : const Color(0xFF2D5016).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isToday ? [
                            BoxShadow(
                              color: const Color(0xFF2D5016).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? const Color(0xFF2D5016) : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCaloriesChart(WatchViewModel viewModel) {
    final now = DateTime.now();
    final maxCalories = viewModel.weeklyCalories.isEmpty ? 0.0 : viewModel.weeklyCalories.reduce((a, b) => a > b ? a : b);
    final totalCalories = viewModel.weeklyCalories.isEmpty ? 0.0 : viewModel.weeklyCalories.reduce((a, b) => a + b);
    final avgCalories = viewModel.weeklyCalories.isEmpty ? 0 : (totalCalories / 7).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange[500], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Calories - Last 7 Days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Avg: $avgCalories',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final calories = viewModel.weeklyCalories.length > index ? viewModel.weeklyCalories[index] : 0.0;
              final barHeight = maxCalories > 0
                  ? (calories / maxCalories * 60).clamp(4.0, 60.0)
                  : 4.0;
              final isToday = index == 6;

              final date = now.subtract(Duration(days: 6 - index));
              final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final dayLabel = dayLabels[date.weekday - 1];

              String caloriesLabel = calories.toStringAsFixed(0);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        caloriesLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isToday ? Colors.orange[600] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.orange[500]
                              : Colors.orange[500]!.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isToday ? [
                            BoxShadow(
                              color: Colors.orange[500]!.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? Colors.orange[600] : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard(WatchViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bedtime, color: Colors.indigo[400], size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sleep',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last night',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                _formatSleepDuration(viewModel.sleepHours),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: 20,
                  child: Container(height: 14, color: Colors.indigo[500]),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 45,
                  child: Container(height: 14, color: Colors.indigo[300]),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 25,
                  child: Container(height: 14, color: Colors.purple[300]),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 10,
                  child: Container(height: 14, color: const Color(0xFFFF9B85).withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSleepLegend('Deep', Colors.indigo[500]!),
              _buildSleepLegend('Core', Colors.indigo[300]!),
              _buildSleepLegend('REM', Colors.purple[300]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
