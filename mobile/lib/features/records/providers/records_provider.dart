import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/repositories/session_repository.dart';
import '../../home/providers/session_provider.dart';
import '../../leave/providers/leave_provider.dart';
import '../../sessions/providers/session_history_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/services/supabase_service.dart';

class RecordsState {
  final bool isLoading;
  final int selectedYear;
  final int selectedMonth;
  final List<Map<String, dynamic>> recentSessions;
  final String? error;

  // All values from backend API
  final int totalWorkMinutes;
  final int expectedWorkMinutes;
  final int scheduleDailyMinutes;
  final int workDays;
  final int netMinutes;
  final int deficitMinutes;
  final int overtimeValueMinutes;
  final double overtimeDaysValue;
  final double overtimePercentageValue;
  final int lateDays;
  final int absentDays;
  final int leaveDays;
  final int annualLeaveDays;
  final int sickLeaveDays;
  final double overtimeMultiplier;
  final double monthlyConstant;

  RecordsState({
    this.isLoading = false,
    int? selectedYear,
    int? selectedMonth,
    this.recentSessions = const [],
    this.error,
    this.totalWorkMinutes = 0,
    this.expectedWorkMinutes = 0,
    this.scheduleDailyMinutes = 0,
    this.workDays = 0,
    this.netMinutes = 0,
    this.deficitMinutes = 0,
    this.overtimeValueMinutes = 0,
    this.overtimeDaysValue = 0,
    this.overtimePercentageValue = 0,
    this.lateDays = 0,
    this.absentDays = 0,
    this.leaveDays = 0,
    this.annualLeaveDays = 0,
    this.sickLeaveDays = 0,
    this.overtimeMultiplier = 1.5,
    this.monthlyConstant = 21.66,
  })  : selectedYear = selectedYear ?? DateTime.now().year,
        selectedMonth = selectedMonth ?? DateTime.now().month;

  /// Total worked minutes this month
  int get totalWorkedMinutes => totalWorkMinutes;

  /// Total expected minutes
  int get totalExpectedMinutes => expectedWorkMinutes;

  /// Whether employee has extra time
  bool get hasExtra => netMinutes >= 0;

  /// Number of working days this month
  int get workDaysCount => workDays;

  /// Completion percentage
  double get completionPercentage {
    if (expectedWorkMinutes == 0) return 0;
    return (totalWorkMinutes / expectedWorkMinutes * 100).clamp(0, 200);
  }

  /// Daily average minutes (of days that had work)
  int get dailyAverageMinutes {
    if (workDays == 0) return 0;
    return totalWorkMinutes ~/ workDays;
  }

  /// Total deficit minutes
  int get totalDeficitMinutes => deficitMinutes;

  /// Late days count
  int get lateDaysCount => lateDays;

  /// Absent days count
  int get absentDaysCount => absentDays;

  /// Overtime value from backend (with proper multipliers)
  double get overtimeValue => overtimeValueMinutes.toDouble();

  /// Expected daily minutes from schedule
  double get expectedDailyMinutes => scheduleDailyMinutes.toDouble();

  /// Overtime days
  double get overtimeDays => overtimeDaysValue;

  /// Overtime percentage
  double get overtimePercentage => overtimePercentageValue;

  /// Used leave days this month
  int get usedLeaveDays => leaveDays;

  /// Annual leave days used this month
  int get usedAnnualLeaveDays => annualLeaveDays;

  /// Sick leave days used this month
  int get usedSickLeaveDays => sickLeaveDays;

  RecordsState copyWith({
    bool? isLoading,
    int? selectedYear,
    int? selectedMonth,
    List<Map<String, dynamic>>? recentSessions,
    String? error,
    int? totalWorkMinutes,
    int? expectedWorkMinutes,
    int? scheduleDailyMinutes,
    int? workDays,
    int? netMinutes,
    int? deficitMinutes,
    int? overtimeValueMinutes,
    double? overtimeDaysValue,
    double? overtimePercentageValue,
    int? lateDays,
    int? absentDays,
    int? leaveDays,
    int? annualLeaveDays,
    int? sickLeaveDays,
    double? overtimeMultiplier,
    double? monthlyConstant,
  }) {
    return RecordsState(
      isLoading: isLoading ?? this.isLoading,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      recentSessions: recentSessions ?? this.recentSessions,
      error: error,
      totalWorkMinutes: totalWorkMinutes ?? this.totalWorkMinutes,
      expectedWorkMinutes: expectedWorkMinutes ?? this.expectedWorkMinutes,
      scheduleDailyMinutes: scheduleDailyMinutes ?? this.scheduleDailyMinutes,
      workDays: workDays ?? this.workDays,
      netMinutes: netMinutes ?? this.netMinutes,
      deficitMinutes: deficitMinutes ?? this.deficitMinutes,
      overtimeValueMinutes: overtimeValueMinutes ?? this.overtimeValueMinutes,
      overtimeDaysValue: overtimeDaysValue ?? this.overtimeDaysValue,
      overtimePercentageValue: overtimePercentageValue ?? this.overtimePercentageValue,
      lateDays: lateDays ?? this.lateDays,
      absentDays: absentDays ?? this.absentDays,
      leaveDays: leaveDays ?? this.leaveDays,
      annualLeaveDays: annualLeaveDays ?? this.annualLeaveDays,
      sickLeaveDays: sickLeaveDays ?? this.sickLeaveDays,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      monthlyConstant: monthlyConstant ?? this.monthlyConstant,
    );
  }
}

class RecordsNotifier extends StateNotifier<RecordsState> {
  final SessionRepository _repository;
  final String? _employeeId;
  SharedPreferences? _prefs;

  RecordsNotifier(this._repository, this._employeeId) : super(RecordsState()) {
    if (_employeeId != null) {
      _init();
    }
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    // Show cached data for current month instantly
    _applyCachedStats(state.selectedYear, state.selectedMonth);
    loadRecords();
  }

  String _cacheKey(int year, int month) => 'records_stats_${_employeeId}_$year-$month';

  Map<String, dynamic>? _getCachedStats(int year, int month) {
    final raw = _prefs?.getString(_cacheKey(year, month));
    if (raw == null) return null;
    return Map<String, dynamic>.from(json.decode(raw) as Map);
  }

  void _saveCachedStats(int year, int month, Map<String, dynamic> data) {
    _prefs?.setString(_cacheKey(year, month), json.encode(data));
  }

  void _applyCachedStats(int year, int month) {
    final cached = _getCachedStats(year, month);
    if (cached == null) return;
    state = state.copyWith(
      isLoading: false,
      selectedYear: year,
      selectedMonth: month,
      totalWorkMinutes: cached['totalWorkMinutes'] as int? ?? 0,
      expectedWorkMinutes: cached['expectedWorkMinutes'] as int? ?? 0,
      scheduleDailyMinutes: cached['scheduleDailyMinutes'] as int? ?? 0,
      workDays: cached['workDays'] as int? ?? 0,
      netMinutes: cached['netMinutes'] as int? ?? 0,
      deficitMinutes: cached['deficitMinutes'] as int? ?? 0,
      overtimeValueMinutes: cached['overtimeValueMinutes'] as int? ?? 0,
      overtimeDaysValue: (cached['overtimeDaysValue'] as num?)?.toDouble() ?? 0,
      overtimePercentageValue: (cached['overtimePercentageValue'] as num?)?.toDouble() ?? 0,
      lateDays: cached['lateDays'] as int? ?? 0,
      absentDays: cached['absentDays'] as int? ?? 0,
      leaveDays: cached['leaveDays'] as int? ?? 0,
      annualLeaveDays: cached['annualLeaveDays'] as int? ?? 0,
      sickLeaveDays: cached['sickLeaveDays'] as int? ?? 0,
      overtimeMultiplier: (cached['overtimeMultiplier'] as num?)?.toDouble() ?? 1.5,
      monthlyConstant: (cached['monthlyConstant'] as num?)?.toDouble() ?? 21.66,
    );
  }

  Future<void> loadRecords() async {
    if (_employeeId == null) return;

    // Only show loading spinner if we have no cached data
    final hasCached = _getCachedStats(state.selectedYear, state.selectedMonth) != null;
    if (!hasCached) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final monthStr = '${state.selectedYear}-${state.selectedMonth.toString().padLeft(2, '0')}';
      final monthDate = DateTime(state.selectedYear, state.selectedMonth, 1);
      final now = DateTime.now();
      final isCurrentMonth = state.selectedYear == now.year && state.selectedMonth == now.month;
      final endDate = isCurrentMonth
          ? now
          : DateTime(state.selectedYear, state.selectedMonth + 1, 0);
      final startStr = AppDateUtils.formatDate(monthDate);
      final endStr = AppDateUtils.formatDate(endDate);

      // Fetch recent sessions for display
      final sessions = await _repository.getSessionsByDateRange(
        employeeId: _employeeId!,
        startDate: startStr,
        endDate: endStr,
      );

      // Call backend get-monthly-summary for all calculations
      final response = await SupabaseService.client.functions.invoke(
        'get-monthly-summary',
        body: {'month': monthStr},
      );

      final data = response.data is String
          ? <String, dynamic>{}
          : (response.data as Map<String, dynamic>);

      final summaries = (data['summaries'] as List<dynamic>?) ?? [];
      final settings = (data['settings'] as Map<String, dynamic>?) ?? {};

      // Extract employee summary (the API returns our own data for employee role)
      Map<String, dynamic>? empSummary;
      if (summaries.isNotEmpty) {
        empSummary = Map<String, dynamic>.from(summaries[0] as Map);
      }

      final otMultiplier = double.tryParse(settings['overtime_multiplier']?.toString() ?? '') ?? 1.5;
      final monthlyConst = double.tryParse(settings['monthly_work_days_constant']?.toString() ?? '') ?? 21.66;

      final freshTotalWork = empSummary?['total_work_minutes'] as int? ?? 0;
      final freshExpected = empSummary?['expected_work_minutes'] as int? ?? 0;
      final freshScheduleDaily = empSummary?['schedule_daily_expected'] as int? ?? 0;
      final freshWorkDays = empSummary?['work_days'] as int? ?? 0;
      final freshNet = empSummary?['net_minutes'] as int? ?? 0;
      final freshDeficit = empSummary?['deficit_minutes'] as int? ?? 0;
      final freshOtValue = empSummary?['overtime_value'] as int? ?? 0;
      final freshOtDays = (empSummary?['overtime_days'] as num?)?.toDouble() ?? 0;
      final freshOtPct = (empSummary?['overtime_percentage'] as num?)?.toDouble() ?? 0;
      final freshLate = empSummary?['late_days'] as int? ?? 0;
      final freshAbsent = empSummary?['absent_days'] as int? ?? 0;
      final freshLeave = empSummary?['leave_days'] as int? ?? 0;
      final freshAnnual = empSummary?['annual_leave_days'] as int? ?? 0;
      final freshSick = empSummary?['sick_leave_days'] as int? ?? 0;

      state = state.copyWith(
        isLoading: false,
        recentSessions: sessions,
        totalWorkMinutes: freshTotalWork,
        expectedWorkMinutes: freshExpected,
        scheduleDailyMinutes: freshScheduleDaily,
        workDays: freshWorkDays,
        netMinutes: freshNet,
        deficitMinutes: freshDeficit,
        overtimeValueMinutes: freshOtValue,
        overtimeDaysValue: freshOtDays,
        overtimePercentageValue: freshOtPct,
        lateDays: freshLate,
        absentDays: freshAbsent,
        leaveDays: freshLeave,
        annualLeaveDays: freshAnnual,
        sickLeaveDays: freshSick,
        overtimeMultiplier: otMultiplier,
        monthlyConstant: monthlyConst,
      );

      // Persist to cache
      _saveCachedStats(state.selectedYear, state.selectedMonth, {
        'totalWorkMinutes': freshTotalWork,
        'expectedWorkMinutes': freshExpected,
        'scheduleDailyMinutes': freshScheduleDaily,
        'workDays': freshWorkDays,
        'netMinutes': freshNet,
        'deficitMinutes': freshDeficit,
        'overtimeValueMinutes': freshOtValue,
        'overtimeDaysValue': freshOtDays,
        'overtimePercentageValue': freshOtPct,
        'lateDays': freshLate,
        'absentDays': freshAbsent,
        'leaveDays': freshLeave,
        'annualLeaveDays': freshAnnual,
        'sickLeaveDays': freshSick,
        'overtimeMultiplier': otMultiplier,
        'monthlyConstant': monthlyConst,
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadRecordsForMonth(int year, int month) async {
    _applyCachedStats(year, month);
    state = state.copyWith(selectedYear: year, selectedMonth: month);
    await loadRecords();
  }
}

final recordsProvider =
    StateNotifierProvider<RecordsNotifier, RecordsState>((ref) {
  final authState = ref.watch(authProvider);
  final repository = ref.watch(sessionRepositoryProvider);
  final notifier = RecordsNotifier(
    repository,
    authState.profile?.id,
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

  // Reload records when leave changes (record/cancel leave)
  ref.listen<LeaveState>(leaveProvider, (prev, next) {
    if (prev == null) return;
    if (prev.isLoading && !next.isLoading && next.error == null) {
      notifier.loadRecords();
    }
  });

  return notifier;
});
