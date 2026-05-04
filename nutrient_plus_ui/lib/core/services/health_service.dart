import 'package:health/health.dart';

class HealthService {
  static final Health _health = Health();

  
  static Future<List<int>> fetchDailySteps({int days = 7, DateTime? endDate}) async {
    final reference = endDate ?? DateTime.now();
    final endDay = DateTime(reference.year, reference.month, reference.day, 23, 59, 59);
    final startDate = DateTime(endDay.year, endDay.month, endDay.day)
        .subtract(Duration(days: days - 1));

    final result = List<int>.filled(days, 0);

    try {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startDate,
        endTime: endDay,
      );
      data = _health.removeDuplicates(data);

      final Map<int, Map<String, int>> byDayAndSource = {};
      for (final point in data) {
        final daysDiff = endDay
            .difference(DateTime(
                point.dateFrom.year, point.dateFrom.month, point.dateFrom.day))
            .inDays;
        final index = (days - 1) - daysDiff;
        if (index >= 0 && index < days) {
          final source = point.sourceName;
          byDayAndSource[index] ??= {};
          byDayAndSource[index]![source] =
              (byDayAndSource[index]![source] ?? 0) +
                  (point.value as NumericHealthValue).numericValue.toInt();
        }
      }

      for (int i = 0; i < days; i++) {
        final sources = byDayAndSource[i];
        if (sources != null && sources.isNotEmpty) {
          result[i] = sources.values.reduce((a, b) => a > b ? a : b);
        }
      }
    } catch (_) {

    }

    return result;
  }

 
  static Future<int> fetchAvgDailySteps({int days = 7, DateTime? endDate}) async {
    final daily = await fetchDailySteps(days: days, endDate: endDate);
    if (daily.isEmpty) return 0;
    return daily.reduce((a, b) => a + b) ~/ daily.length;
  }
}
