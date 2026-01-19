import 'package:flutter/material.dart';
import 'package:health/health.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  final Health _health = Health();
  
  bool _isLoading = true;
  bool _isAuthorized = false;
  String? _error;
  
  // Selected date
  DateTime _selectedDate = DateTime.now();
  
  // Health data
  int _steps = 0;
  double _caloriesBurned = 0;
  double _distance = 0;
  double _sleepHours = 0;

  // Health types to read
  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    // Sleep types (only supported ones)
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  @override
  void initState() {
    super.initState();
    _initHealth();
  }

  Future<void> _initHealth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Configure health plugin
      await _health.configure();
      
      // Try to fetch data - this will tell us if we have permissions
      await _fetchHealthData();
      
      // If we got here without error, we have permissions
      setState(() {
        _isAuthorized = true;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Health init error: $e');
      // If fetch failed, we probably don't have permissions
      setState(() {
        _isAuthorized = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Request authorization
      bool authorized = await _health.requestAuthorization(
        _types,
        permissions: _types.map((e) => HealthDataAccess.READ).toList(),
      );
      
      
      if (authorized) {
        setState(() {
          _isAuthorized = true;
        });
        await _fetchHealthData();
      } else {
        // Even if it returns false, try to fetch anyway
        // Sometimes permissions are granted but check returns false
        try {
          await _fetchHealthData();
          if (_steps > 0 || _caloriesBurned > 0) {
            setState(() {
              _isAuthorized = true;
            });
          }
        } catch (e) {
          print('Fetch after auth failed: $e');
        }
      }
    } catch (e) {
      print('Permission request error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openHealthConnect() async {
    try {
      await _health.installHealthConnect();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please open Health Connect manually:\nSettings → Apps → Health Connect'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D5016),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchHealthData();
    }
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _fetchHealthData();
  }

  void _goToNextDay() {
    final now = DateTime.now();
    final tomorrow = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1);
    
    if (tomorrow.isBefore(now) || _isSameDay(tomorrow, now)) {
      setState(() {
        _selectedDate = tomorrow;
      });
      _fetchHealthData();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday() {
    return _isSameDay(_selectedDate, DateTime.now());
  }

  String _formatDate(DateTime date) {
    if (_isToday()) {
      return 'Today';
    }
    
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    }
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatSleepDuration(double hours) {
    if (hours <= 0) return '--';
    
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    
    if (h > 0 && m > 0) {
      return '${h}h ${m}m';
    } else if (h > 0) {
      return '${h}h';
    } else {
      return '${m}m';
    }
  }

  Future<void> _fetchHealthData() async {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = _isToday() 
        ? DateTime.now() 
        : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
    
    // For sleep, we need to look at the night before (sleep starts previous evening)
    final sleepStart = startOfDay.subtract(const Duration(hours: 12)); // Start from 12:00 previous day
    
    // Fetch regular health data
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
      types: [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_DELTA,
      ],
      startTime: startOfDay,
      endTime: endOfDay,
    );
    
    // Fetch sleep data with extended range
    List<HealthDataPoint> sleepData = [];
    try {
      sleepData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
        ],
        startTime: sleepStart,
        endTime: endOfDay,
      );
    } catch (e) {
      print('Sleep fetch error: $e');
    }
    
    print('Got ${healthData.length} health data points');
    print('Got ${sleepData.length} sleep data points');

    // Process the data
    int steps = 0;
    double calories = 0;
    double distance = 0;
    double sleepMinutes = 0;

    for (var point in healthData) {
      switch (point.type) {
        case HealthDataType.STEPS:
          steps += (point.value as NumericHealthValue).numericValue.toInt();
          break;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          calories += (point.value as NumericHealthValue).numericValue.toDouble();
          break;
        case HealthDataType.DISTANCE_DELTA:
          distance += (point.value as NumericHealthValue).numericValue.toDouble();
          break;
        default:
          break;
      }
    }
    
    // Process sleep data separately
    Set<String> processedSleepSessions = {}; // Avoid counting duplicates
    for (var point in sleepData) {
      // Create unique key for this sleep segment
      final key = '${point.dateFrom.toIso8601String()}-${point.dateTo.toIso8601String()}';
      
      // Only count actual sleep types, not IN_BED or SESSION (to avoid double counting)
      if (point.type == HealthDataType.SLEEP_ASLEEP ||
          point.type == HealthDataType.SLEEP_LIGHT ||
          point.type == HealthDataType.SLEEP_DEEP ||
          point.type == HealthDataType.SLEEP_REM) {
        if (!processedSleepSessions.contains(key)) {
          processedSleepSessions.add(key);
          final duration = point.dateTo.difference(point.dateFrom);
          sleepMinutes += duration.inMinutes;
          print('Sleep: ${point.type} from ${point.dateFrom} to ${point.dateTo} = ${duration.inMinutes} min');
        }
      }
    }

    setState(() {
      _steps = steps;
      _caloriesBurned = calories;
      _distance = distance;
      _sleepHours = sleepMinutes / 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    if (!_isAuthorized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.watch, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Health Connect Permission Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Grant permission to access your health data from your smartwatch',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              
              // Primary button - Request permission
              ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.health_and_safety),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'If dialog doesn\'t appear:',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Tap "Open Health Connect" below\n'
                      '2. Go to "App permissions"\n'
                      '3. Find "NutrientPlus" and enable all\n'
                      '4. Come back and tap "Grant Permission"',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Open Health Connect button
              OutlinedButton.icon(
                onPressed: _openHealthConnect,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Health Connect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D5016),
                  side: const BorderSide(color: Color(0xFF2D5016)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHealthData,
      color: const Color(0xFF2D5016),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with watch info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5016).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.watch,
                    color: Color(0xFF2D5016),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Redmi Watch 5',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Health Stats',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchHealthData().then((_) {
                      setState(() => _isLoading = false);
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  color: const Color(0xFF2D5016),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Date selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _goToPreviousDay,
                    icon: const Icon(Icons.chevron_left),
                    color: const Color(0xFF2D5016),
                  ),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2D5016).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Color(0xFF2D5016),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D5016),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isToday() ? null : _goToNextDay,
                    icon: const Icon(Icons.chevron_right),
                    color: _isToday() ? Colors.grey[300] : const Color(0xFF2D5016),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Main stats grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.directions_walk,
                    title: 'Steps',
                    value: _steps.toString(),
                    subtitle: 'Goal: 10,000',
                    progress: _steps / 10000,
                    color: const Color(0xFF2D5016),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    title: 'Calories',
                    value: _caloriesBurned.toStringAsFixed(0),
                    subtitle: 'kcal burned',
                    progress: _caloriesBurned / 500,
                    color: const Color(0xFFE85D04),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.straighten,
                    title: 'Distance',
                    value: (_distance / 1000).toStringAsFixed(2),
                    subtitle: 'km walked',
                    progress: _distance / 8000,
                    color: const Color(0xFF457B9D),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bedtime,
                    title: 'Sleep',
                    value: _formatSleepDuration(_sleepHours),
                    subtitle: 'last night',
                    progress: _sleepHours / 8,
                    color: const Color(0xFF1D3557),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use arrows or tap the date to view different days',
                      style: TextStyle(color: Colors.blue[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final double progress;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
