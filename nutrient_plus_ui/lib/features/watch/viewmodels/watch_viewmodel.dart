import 'package:health/health.dart';
import '../../../core/base/base_viewmodel.dart';

/// ViewModel for Watch (Health) screen
class WatchViewModel extends BaseViewModel {
  final Health _health = Health();

  bool _isAuthorized = false;
  int _selectedDayIndex = 0;

  // Health data
  int _steps = 0;
  double _caloriesBurned = 0;
  double _sleepHours = 0;

  // Weekly data for chart
  List<int> _weeklySteps = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];

  // Health types to read
  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  // Getters
  bool get isAuthorized => _isAuthorized;
  int get selectedDayIndex => _selectedDayIndex;
  int get steps => _steps;
  double get caloriesBurned => _caloriesBurned;
  double get sleepHours => _sleepHours;
  List<int> get weeklySteps => _weeklySteps;
  List<double> get weeklyCalories => _weeklyCalories;

  /// Initialize health and load data
  Future<void> initHealth() async {
    setLoading(true);

    try {
      await _health.configure();
      await fetchHealthData();
      await fetchWeeklyData();

      _isAuthorized = true;
      setLoading(false);
    } catch (e) {
      _isAuthorized = false;
      setLoading(false);
    }
  }

  /// Request health permissions
  Future<void> requestPermissions() async {
    setLoading(true);

    try {
      bool authorized = await _health.requestAuthorization(
        _types,
        permissions: _types.map((e) => HealthDataAccess.READ).toList(),
      );

      if (authorized) {
        _isAuthorized = true;
        notifyListeners();
        await fetchHealthData();
        await fetchWeeklyData();
      }
    } catch (e) {
      // Permission request error
    } finally {
      setLoading(false);
    }
  }

  /// Open Health Connect settings
  Future<bool> openHealthConnect() async {
    try {
      await _health.installHealthConnect();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set selected day index and refresh data
  void setSelectedDayIndex(int index) {
    _selectedDayIndex = index;
    notifyListeners();
    fetchHealthData();
  }

  DateTime getSelectedDate() {
    return DateTime.now().subtract(Duration(days: _selectedDayIndex));
  }

  /// Fetch health data for the selected day
  Future<void> fetchHealthData() async {
    final selectedDate = getSelectedDate();
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = _selectedDayIndex == 0
        ? DateTime.now()
        : DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

    final sleepStart = startOfDay.subtract(const Duration(hours: 12));

    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
        startTime: startOfDay,
        endTime: endOfDay,
      );

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
        // Sleep fetch error
      }

      int steps = 0;
      double calories = 0;
      double sleepMinutes = 0;

      healthData = _health.removeDuplicates(healthData);

      // Group steps by source app to avoid double-counting
      Map<String, int> stepsBySource = {};
      for (var point in healthData) {
        if (point.type == HealthDataType.STEPS) {
          final source = point.sourceName;
          final value = (point.value as NumericHealthValue).numericValue.toInt();
          stepsBySource[source] = (stepsBySource[source] ?? 0) + value;
        } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          calories += (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      // Take the maximum from any single source
      if (stepsBySource.isNotEmpty) {
        steps = stepsBySource.values.reduce((a, b) => a > b ? a : b);
      }

      Set<String> processedSleepSessions = {};
      for (var point in sleepData) {
        final key = '${point.dateFrom.toIso8601String()}-${point.dateTo.toIso8601String()}';
        if (point.type == HealthDataType.SLEEP_ASLEEP ||
            point.type == HealthDataType.SLEEP_LIGHT ||
            point.type == HealthDataType.SLEEP_DEEP ||
            point.type == HealthDataType.SLEEP_REM) {
          if (!processedSleepSessions.contains(key)) {
            processedSleepSessions.add(key);
            final duration = point.dateTo.difference(point.dateFrom);
            sleepMinutes += duration.inMinutes;
          }
        }
      }

      _steps = steps;
      _caloriesBurned = calories;
      _sleepHours = sleepMinutes / 60;
      notifyListeners();
    } catch (e) {
      // Fetch error
    }
  }

  /// Fetch weekly data for charts
  Future<void> fetchWeeklyData() async {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day - 6);

    List<int> weeklySteps = List.filled(7, 0);
    List<double> weeklyCalories = List.filled(7, 0);

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS, HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: sevenDaysAgo,
        endTime: now,
      );

      data = _health.removeDuplicates(data);

      // Group steps by day and source to avoid double-counting
      Map<int, Map<String, int>> stepsByDayAndSource = {};

      for (var point in data) {
        final daysDiff = now.difference(DateTime(point.dateFrom.year, point.dateFrom.month, point.dateFrom.day)).inDays;
        final dayIndex = 6 - daysDiff;

        if (dayIndex >= 0 && dayIndex < 7) {
          if (point.type == HealthDataType.STEPS) {
            final source = point.sourceName;
            stepsByDayAndSource[dayIndex] ??= {};
            stepsByDayAndSource[dayIndex]![source] =
                (stepsByDayAndSource[dayIndex]![source] ?? 0) +
                (point.value as NumericHealthValue).numericValue.toInt();
          } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
            weeklyCalories[dayIndex] += (point.value as NumericHealthValue).numericValue.toDouble();
          }
        }
      }

      // For each day, take the max from any single source
      for (int i = 0; i < 7; i++) {
        if (stepsByDayAndSource.containsKey(i) && stepsByDayAndSource[i]!.isNotEmpty) {
          weeklySteps[i] = stepsByDayAndSource[i]!.values.reduce((a, b) => a > b ? a : b);
        }
      }
    } catch (e) {
      // Weekly data fetch error
    }

    _weeklySteps = weeklySteps;
    _weeklyCalories = weeklyCalories;
    notifyListeners();
  }
}
