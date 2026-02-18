import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/repositories/session_repository.dart';
import '../../home/providers/session_provider.dart';
import '../../sessions/providers/session_history_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/services/supabase_service.dart';

class RecordsState {
  final bool isLoading;
  final int selectedYear;
  final int selectedMonth;
  final List<Map<String, dynamic>> recentSessions;
  final List<Map<String, dynamic>> dailySummaries;
  final String? error;
  final double overtimeMultiplier;
  final double monthlyConstant;
  final int scheduleExpectedMinutes; // expected from schedule
  final int scheduleDailyMinutes; // expected per work day from schedule
  final int scheduleWorkDaysInRange; // total schedule work days up to cutoff
  final int calculatedAbsentDays; // work days with no session and no leave

  RecordsState({
    this.isLoading = false,
    int? selectedYear,
    int? selectedMonth,
    this.recentSessions = const [],
    this.dailySummaries = const [],
    this.error,
    this.overtimeMultiplier = 1.5,
    this.monthlyConstant = 21.66,
    this.scheduleExpectedMinutes = 0,
    this.scheduleDailyMinutes = 0,
    this.scheduleWorkDaysInRange = 0,
    this.calculatedAbsentDays = 0,
  })  : selectedYear = selectedYear ?? DateTime.now().year,
        selectedMonth = selectedMonth ?? DateTime.now().month;

  /// Total worked minutes this month
  int get totalWorkedMinutes => dailySummaries.fold(
      0, (sum, s) => sum + (s['total_work_minutes'] as int? ?? 0));

  /// Total expected minutes — use schedule-based calculation
  int get totalExpectedMinutes => scheduleExpectedMinutes;

  /// Total overtime minutes this month
  int get totalOvertimeMinutes => dailySummaries.fold(
      0, (sum, s) => sum + (s['total_overtime_minutes'] as int? ?? 0));

  /// Difference: positive = extra, negative = missing
  int get differenceMinutes => totalWorkedMinutes - totalExpectedMinutes;

  /// Whether employee has extra time
  bool get hasExtra => differenceMinutes > 0;

  /// Number of working days this month
  int get workDaysCount =>
      dailySummaries.where((s) => (s['total_work_minutes'] as int? ?? 0) > 0).length;

  /// Completion percentage
  double get completionPercentage {
    if (totalExpectedMinutes == 0) return 0;
    return (totalWorkedMinutes / totalExpectedMinutes * 100).clamp(0, 200);
  }

  /// Daily average minutes (of days that had work)
  int get dailyAverageMinutes {
    if (workDaysCount == 0) return 0;
    return totalWorkedMinutes ~/ workDaysCount;
  }

  /// Total deficit minutes (negative difference, clamped to 0+)
  int get totalDeficitMinutes {
    final diff = totalExpectedMinutes - totalWorkedMinutes;
    return diff > 0 ? diff : 0;
  }

  /// Late days count
  int get lateDaysCount =>
      dailySummaries.where((s) => s['is_late'] == true).length;

  /// Absent days count — schedule work days with no work and no leave
  int get absentDaysCount => calculatedAbsentDays;

  /// Net minutes (positive = surplus, negative = deficit)
  int get netMinutes => totalWorkedMinutes - totalExpectedMinutes;

  /// Overtime value using monthly formula
  double get overtimeValue {
    if (netMinutes <= 0) return 0;
    return netMinutes * overtimeMultiplier;
  }

  /// Expected daily minutes from schedule
  double get expectedDailyMinutes {
    if (scheduleDailyMinutes > 0) return scheduleDailyMinutes.toDouble();
    return 0;
  }

  /// Overtime days
  double get overtimeDays {
    if (expectedDailyMinutes <= 0) return 0;
    return overtimeValue / expectedDailyMinutes;
  }

  /// Overtime percentage
  double get overtimePercentage {
    if (monthlyConstant <= 0) return 0;
    return (overtimeDays / monthlyConstant) * 100;
  }

  /// Used leave days this month
  int get usedLeaveDays => dailySummaries
      .where((s) => (s['status'] as String?) == 'leave')
      .length;

  RecordsState copyWith({
    bool? isLoading,
    int? selectedYear,
    int? selectedMonth,
    List<Map<String, dynamic>>? recentSessions,
    List<Map<String, dynamic>>? dailySummaries,
    String? error,
    double? overtimeMultiplier,
    double? monthlyConstant,
    int? scheduleExpectedMinutes,
    int? scheduleDailyMinutes,
    int? scheduleWorkDaysInRange,
    int? calculatedAbsentDays,
  }) {
    return RecordsState(
      isLoading: isLoading ?? this.isLoading,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      recentSessions: recentSessions ?? this.recentSessions,
      dailySummaries: dailySummaries ?? this.dailySummaries,
      error: error,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      monthlyConstant: monthlyConstant ?? this.monthlyConstant,
      scheduleExpectedMinutes: scheduleExpectedMinutes ?? this.scheduleExpectedMinutes,
      scheduleDailyMinutes: scheduleDailyMinutes ?? this.scheduleDailyMinutes,
      scheduleWorkDaysInRange: scheduleWorkDaysInRange ?? this.scheduleWorkDaysInRange,
      calculatedAbsentDays: calculatedAbsentDays ?? this.calculatedAbsentDays,
    );
  }
}

class RecordsNotifier extends StateNotifier<RecordsState> {
  final SessionRepository _repository;
  final String? _employeeId;
  final String? _companyId;
  final bool Function() _isClockedIn;

  RecordsNotifier(this._repository, this._employeeId, this._companyId, this._isClockedIn) : super(RecordsState()) {
    if (_employeeId != null) {
      loadRecords();
    }
  }

  Future<void> loadRecords() async {
    if (_employeeId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final monthDate = DateTime(state.selectedYear, state.selectedMonth, 1);
      final now = DateTime.now();
      final isCurrentMonth = state.selectedYear == now.year && state.selectedMonth == now.month;
      final endDate = isCurrentMonth
          ? now
          : DateTime(state.selectedYear, state.selectedMonth + 1, 0);
      final startStr = AppDateUtils.formatDate(monthDate);
      final endStr = AppDateUtils.formatDate(endDate);

      final sessions = await _repository.getSessionsByDateRange(
        employeeId: _employeeId!,
        startDate: startStr,
        endDate: endStr,
      );

      final summaries = await _repository.getMonthDailySummaries(
        _employeeId!,
        monthDate,
      );

      // Fetch company work settings for OT calculation
      double otMultiplier = 1.5;
      double monthlyConst = 21.66;
      if (_companyId != null) {
        final wsResponse = await SupabaseService.client
            .from('company_work_settings')
            .select('overtime_multiplier, monthly_work_days_constant')
            .eq('company_id', _companyId)
            .maybeSingle();
        if (wsResponse != null) {
          otMultiplier = double.tryParse(wsResponse['overtime_multiplier']?.toString() ?? '') ?? 1.5;
          monthlyConst = double.tryParse(wsResponse['monthly_work_days_constant']?.toString() ?? '') ?? 21.66;
        }
      }

      // Fetch employee schedule for expected calculation
      int scheduleExpected = 0;
      int dailyExpected = 0;
      int absentDays = 0;
      int scheduleWorkDays = 0;
      final schedule = await SupabaseService.client
          .from('employee_schedules')
          .select('*, shift_template:shift_templates(*)')
          .eq('employee_id', _employeeId!)
          .lte('effective_from', endStr)
          .or('effective_to.is.null,effective_to.gte.$startStr')
          .order('effective_from', ascending: false)
          .limit(1)
          .maybeSingle();

      if (schedule != null) {
        final template = schedule['shift_template'] as Map<String, dynamic>?;
        final workDays = (template?['work_days'] ?? schedule['custom_work_days']) as List<dynamic>?;
        final startTime = (template?['start_time'] ?? schedule['custom_start_time']) as String?;
        final endTime = (template?['end_time'] ?? schedule['custom_end_time']) as String?;
        final breakMinutes = (template?['break_duration_minutes'] ?? schedule['custom_break_duration_minutes'] ?? 0) as int;

        if (workDays != null && startTime != null && endTime != null) {
          // Calculate daily expected minutes from shift times
          final startParts = startTime.split(':');
          final endParts = endTime.split(':');
          final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          dailyExpected = endMin - startMin - breakMinutes;

          // Determine cutoff date for expected calculation
          // Current month: exclude today unless user has clocked out today (completed session)
          // Past months: include all days
          DateTime cutoffDate;
          if (isCurrentMonth) {
            if (_isClockedIn()) {
              // Still clocked in — don't count today yet
              cutoffDate = DateTime(now.year, now.month, now.day - 1);
            } else {
              // Not clocked in — include today only if there's a completed session
              final todayStr = AppDateUtils.formatDate(now);
              final hasTodaySummary = summaries.any((s) =>
                  s['summary_date'] == todayStr &&
                  (s['total_work_minutes'] as int? ?? 0) > 0);
              if (hasTodaySummary) {
                cutoffDate = now;
              } else {
                // Today hasn't been worked yet — exclude it
                cutoffDate = DateTime(now.year, now.month, now.day - 1);
              }
            }
          } else {
            cutoffDate = DateTime(state.selectedYear, state.selectedMonth + 1, 0);
          }

          // Count schedule work days in range and track absent days
          final workDayNums = workDays.map((d) => d is int ? d : int.parse(d.toString())).toSet();

          // Build set of dates that have work or leave
          final coveredDates = <String>{};
          for (final s in summaries) {
            final dateStr = s['summary_date'] as String;
            final worked = s['total_work_minutes'] as int? ?? 0;
            final status = s['status'] as String? ?? '';
            if (worked > 0 || status == 'leave') {
              coveredDates.add(dateStr);
            }
          }

          int workDaysInRange = 0;
          int absentCount = 0;
          for (var d = monthDate;
              !d.isAfter(cutoffDate);
              d = d.add(const Duration(days: 1))) {
            if (workDayNums.contains(d.weekday)) {
              workDaysInRange++;
              final dStr = AppDateUtils.formatDate(d);
              if (!coveredDates.contains(dStr)) {
                absentCount++;
              }
            }
          }

          scheduleExpected = workDaysInRange * dailyExpected;
          absentDays = absentCount;
          scheduleWorkDays = workDaysInRange;
        }
      }

      state = state.copyWith(
        isLoading: false,
        recentSessions: sessions,
        dailySummaries: summaries,
        overtimeMultiplier: otMultiplier,
        monthlyConstant: monthlyConst,
        scheduleExpectedMinutes: scheduleExpected,
        scheduleDailyMinutes: dailyExpected,
        scheduleWorkDaysInRange: scheduleWorkDays,
        calculatedAbsentDays: absentDays,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadRecordsForMonth(int year, int month) async {
    state = state.copyWith(selectedYear: year, selectedMonth: month);
    await loadRecords();
  }
}

final recordsProvider =
    StateNotifierProvider<RecordsNotifier, RecordsState>((ref) {
  final authState = ref.watch(authProvider);
  final repository = ref.watch(sessionRepositoryProvider);
  final sessionState = ref.watch(sessionProvider);
  final notifier = RecordsNotifier(
    repository,
    authState.profile?.id,
    authState.profile?.companyId,
    () => sessionState.isClockedIn,
  );

  // Reload records when session state changes (clock in/out)
  ref.listen<SessionState>(sessionProvider, (prev, next) {
    if (prev == null) return;
    if (prev.isLoading && !next.isLoading && next.error == null) {
      notifier.loadRecords();
    }
  });

  // Reload records when session history changes (manual session create/delete)
  ref.listen<SessionHistoryState>(sessionHistoryProvider, (prev, next) {
    if (prev == null) return;
    if (prev.isLoading && !next.isLoading && next.error == null) {
      notifier.loadRecords();
    }
  });

  return notifier;
});
