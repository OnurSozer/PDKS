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

  RecordsState({
    this.isLoading = false,
    int? selectedYear,
    int? selectedMonth,
    this.recentSessions = const [],
    this.dailySummaries = const [],
    this.error,
    this.overtimeMultiplier = 1.5,
    this.monthlyConstant = 21.66,
  })  : selectedYear = selectedYear ?? DateTime.now().year,
        selectedMonth = selectedMonth ?? DateTime.now().month;

  /// Total worked minutes this month
  int get totalWorkedMinutes => dailySummaries.fold(
      0, (sum, s) => sum + (s['total_work_minutes'] as int? ?? 0));

  /// Total expected minutes this month
  int get totalExpectedMinutes => dailySummaries.fold(
      0, (sum, s) => sum + (s['expected_work_minutes'] as int? ?? 0));

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

  /// Total deficit minutes
  int get totalDeficitMinutes => dailySummaries.fold(
      0, (sum, s) => sum + (s['deficit_minutes'] as int? ?? 0));

  /// Late days count
  int get lateDaysCount =>
      dailySummaries.where((s) => s['is_late'] == true).length;

  /// Absent days count (absent but not on leave)
  int get absentDaysCount =>
      dailySummaries.where((s) => s['is_absent'] == true && s['is_leave'] != true).length;

  /// Net minutes (positive = surplus, negative = deficit)
  int get netMinutes => totalWorkedMinutes - totalExpectedMinutes;

  /// Overtime value using monthly formula
  double get overtimeValue {
    if (netMinutes <= 0) return 0;
    return netMinutes * overtimeMultiplier;
  }

  /// Expected daily minutes
  double get expectedDailyMinutes {
    if (workDaysCount == 0) return 0;
    return totalExpectedMinutes / workDaysCount;
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
    );
  }
}

class RecordsNotifier extends StateNotifier<RecordsState> {
  final SessionRepository _repository;
  final String? _employeeId;
  final String? _companyId;

  RecordsNotifier(this._repository, this._employeeId, this._companyId) : super(RecordsState()) {
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
      final endDate = (state.selectedYear == now.year && state.selectedMonth == now.month)
          ? now
          : DateTime(state.selectedYear, state.selectedMonth + 1, 0);
      final startStr = AppDateUtils.formatDate(monthDate);
      final endStr = AppDateUtils.formatDate(endDate);

      final sessions = await _repository.getSessionsByDateRange(
        employeeId: _employeeId,
        startDate: startStr,
        endDate: endStr,
      );

      final summaries = await _repository.getMonthDailySummaries(
        _employeeId,
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

      state = state.copyWith(
        isLoading: false,
        recentSessions: sessions,
        dailySummaries: summaries,
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
    authState.profile?.companyId,
  );

  // Reload records when session state changes (clock in/out)
  ref.listen<SessionState>(sessionProvider, (prev, next) {
    if (prev == null) return;
    // Reload when loading finishes (a mutation just completed)
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
