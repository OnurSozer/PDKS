import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      monthlyConstant: monthlyConstant ?? this.monthlyConstant,
    );
  }
}

class RecordsNotifier extends StateNotifier<RecordsState> {
  final SessionRepository _repository;
  final String? _employeeId;

  RecordsNotifier(this._repository, this._employeeId) : super(RecordsState()) {
    if (_employeeId != null) {
      loadRecords();
    }
  }

  Future<void> loadRecords() async {
    if (_employeeId == null) return;
    state = state.copyWith(isLoading: true, error: null);
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

      state = state.copyWith(
        isLoading: false,
        recentSessions: sessions,
        totalWorkMinutes: empSummary?['total_work_minutes'] as int? ?? 0,
        expectedWorkMinutes: empSummary?['expected_work_minutes'] as int? ?? 0,
        scheduleDailyMinutes: empSummary?['schedule_daily_expected'] as int? ?? 0,
        workDays: empSummary?['work_days'] as int? ?? 0,
        netMinutes: empSummary?['net_minutes'] as int? ?? 0,
        deficitMinutes: empSummary?['deficit_minutes'] as int? ?? 0,
        overtimeValueMinutes: empSummary?['overtime_value'] as int? ?? 0,
        overtimeDaysValue: (empSummary?['overtime_days'] as num?)?.toDouble() ?? 0,
        overtimePercentageValue: (empSummary?['overtime_percentage'] as num?)?.toDouble() ?? 0,
        lateDays: empSummary?['late_days'] as int? ?? 0,
        absentDays: empSummary?['absent_days'] as int? ?? 0,
        leaveDays: empSummary?['leave_days'] as int? ?? 0,
        overtimeMultiplier: otMultiplier,
        monthlyConstant: monthlyConst,
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
