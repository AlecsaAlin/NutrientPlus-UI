import 'package:health/health.dart';
import '../../../core/base/base_viewmodel.dart';
import '../../../core/services/health_service.dart';

class WatchViewModel extends BaseViewModel {
  final Health _health = Health();

  bool _isAuthorized = false;
  int _selectedDayIndex = 0;

  int _steps = 0;
  double _caloriesBurned = 0;
  double _sleepHours = 0;

  List<int> _weeklySteps = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];

  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  bool get isAuthorized => _isAuthorized;
  int get selectedDayIndex => _selectedDayIndex;
  int get steps => _steps;
  double get caloriesBurned => _caloriesBurned;
  double get sleepHours => _sleepHours;
  List<int> get weeklySteps => _weeklySteps;
  List<double> get weeklyCalories => _weeklyCalories;

  Future<void> initHealth() async {
    setLoading(true);

    try {
      await _health.configure();

      final hasPerms = await _health.hasPermissions(
        _types,
        permissions: _types.map((e) => HealthDataAccess.READ).toList(),
      );

      if (hasPerms == true) {
        _isAuthorized = true;
        await fetchHealthData();
        await fetchWeeklyData();
      } else {
        _isAuthorized = false;
      }
    } catch (e) {
      _isAuthorized = false;
    } finally {
      setLoading(false);
    }
  }

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

  void setSelectedDayIndex(int index) {
    _selectedDayIndex = index;
    notifyListeners();
    fetchHealthData();
  }

  DateTime getSelectedDate() {
    return DateTime.now().subtract(Duration(days: _selectedDayIndex));
  }

  Future<void> fetchHealthData() async {
    final selectedDate = getSelectedDate();
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = _selectedDayIndex == 0
        ? DateTime.now()
        : DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

    final sleepStart = startOfDay.subtract(const Duration(hours: 12));
  
    final sleepEndCandidate = startOfDay.add(const Duration(hours: 14));
    final sleepEnd = sleepEndCandidate.isAfter(DateTime.now())
        ? DateTime.now()
        : sleepEndCandidate;

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
          endTime: sleepEnd,
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

      if (stepsBySource.isNotEmpty) {
        steps = stepsBySource.values.reduce((a, b) => a > b ? a : b);
      }

      final sleepTypes = {
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
      };
      final intervals = sleepData
          .where((p) => sleepTypes.contains(p.type))
          .map((p) => [p.dateFrom, p.dateTo])
          .toList()
        ..sort((a, b) => a[0].compareTo(b[0]));

      final merged = <List<DateTime>>[];
      for (final iv in intervals) {
        if (merged.isEmpty || iv[0].isAfter(merged.last[1])) {
          merged.add([iv[0], iv[1]]);
        } else if (iv[1].isAfter(merged.last[1])) {
          merged.last[1] = iv[1];
        }
      }
      for (final iv in merged) {
        sleepMinutes += iv[1].difference(iv[0]).inMinutes;
      }

      _steps = steps;
      _caloriesBurned = calories;
      _sleepHours = sleepMinutes / 60;
      notifyListeners();
    } catch (e) {
      // Fetch error
    }
  }

  Future<void> fetchWeeklyData() async {
    final now = DateTime.now();
    // Use yesterday as the end so the current (incomplete) day is excluded.
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    final sevenDaysAgo = DateTime(now.year, now.month, now.day - 7);

    List<double> weeklyCalories = List.filled(7, 0);

    try {
      List<HealthDataPoint> calorieData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: sevenDaysAgo,
        endTime: endOfYesterday,
      );
      calorieData = _health.removeDuplicates(calorieData);

      for (var point in calorieData) {
        // Index 0 = 7 days ago … index 6 = yesterday
        final daysDiff = endOfYesterday
            .difference(DateTime(point.dateFrom.year, point.dateFrom.month, point.dateFrom.day))
            .inDays;
        final dayIndex = 6 - daysDiff;
        if (dayIndex >= 0 && dayIndex < 7) {
          weeklyCalories[dayIndex] += (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
    } catch (_) {
      // Weekly calorie fetch error
    }

    _weeklySteps = await HealthService.fetchDailySteps(days: 7, endDate: yesterday);
    _weeklyCalories = weeklyCalories;
    notifyListeners();
  }
}
