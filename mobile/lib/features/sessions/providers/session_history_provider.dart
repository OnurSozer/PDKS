import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/repositories/session_repository.dart';
import '../../home/providers/session_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/services/supabase_service.dart';

class _DateCache {
  final List<Map<String, dynamic>> sessions;
  final Map<String, dynamic>? dailySummary;

  _DateCache({required this.sessions, this.dailySummary});
}

class SessionHistoryState {
  final bool isLoading;
  final DateTime selectedDate;
  final int selectedYear;
  final int selectedMonth;
  final List<Map<String, dynamic>> sessions;
  final Map<String, dynamic>? dailySummary;
  final Map<String, String> monthDayStatuses; // "yyyy-MM-dd" -> "full"|"overtime"|"missing"|"leave"|"sick_leave"
  final Map<String, String> leaveTypeByDate; // "yyyy-MM-dd" -> leave type name
  final String? error;

  SessionHistoryState({
    this.isLoading = false,
    DateTime? selectedDate,
    int? selectedYear,
    int? selectedMonth,
    this.sessions = const [],
    this.dailySummary,
    this.monthDayStatuses = const {},
    this.leaveTypeByDate = const {},
    this.error,
  })  : selectedDate = selectedDate ?? DateTime.now(),
        selectedYear = selectedYear ?? DateTime.now().year,
        selectedMonth = selectedMonth ?? DateTime.now().month;

  SessionHistoryState copyWith({
    bool? isLoading,
    DateTime? selectedDate,
    int? selectedYear,
    int? selectedMonth,
    List<Map<String, dynamic>>? sessions,
    Map<String, dynamic>? dailySummary,
    bool clearDailySummary = false,
    Map<String, String>? monthDayStatuses,
    Map<String, String>? leaveTypeByDate,
    String? error,
  }) {
    return SessionHistoryState(
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      sessions: sessions ?? this.sessions,
      dailySummary: clearDailySummary ? null : (dailySummary ?? this.dailySummary),
      monthDayStatuses: monthDayStatuses ?? this.monthDayStatuses,
      leaveTypeByDate: leaveTypeByDate ?? this.leaveTypeByDate,
      error: error,
    );
  }
}

class SessionHistoryNotifier extends StateNotifier<SessionHistoryState> {
  final SessionRepository _repository;
  final String? _employeeId;
  final Map<String, _DateCache> _cache = {};
  SharedPreferences? _prefs;
  int _prefetchedMonth = 0; // tracks which month we already bulk-fetched
  int _prefetchedYear = 0;

  SessionHistoryNotifier(this._repository, this._employeeId)
      : super(SessionHistoryState()) {
    if (_employeeId != null) {
      _init();
    }
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    // Show persisted data for current month instantly
    _applyCachedMonth(now.year, now.month);
    // Pre-fetch entire month data, then show today
    _prefetchMonth(now.year, now.month).then((_) {
      loadSessionsForDate(now);
    });
    loadMonthStatuses(now.year, now.month);
  }

  String _statusKey(String monthKey) => 'cal_status_${_employeeId}_$monthKey';
  String _leaveKey(String monthKey) => 'cal_leave_${_employeeId}_$monthKey';

  Map<String, String>? _getCachedStatuses(String monthKey) {
    final raw = _prefs?.getString(_statusKey(monthKey));
    if (raw == null) return null;
    return Map<String, String>.from(json.decode(raw) as Map);
  }

  Map<String, String>? _getCachedLeaveTypes(String monthKey) {
    final raw = _prefs?.getString(_leaveKey(monthKey));
    if (raw == null) return null;
    return Map<String, String>.from(json.decode(raw) as Map);
  }

  void _saveCachedMonth(String monthKey, Map<String, String> statuses, Map<String, String> leaveTypes) {
    _prefs?.setString(_statusKey(monthKey), json.encode(statuses));
    _prefs?.setString(_leaveKey(monthKey), json.encode(leaveTypes));
  }

  void _removeCachedMonth(String monthKey) {
    _prefs?.remove(_statusKey(monthKey));
    _prefs?.remove(_leaveKey(monthKey));
  }

  void _applyCachedMonth(int year, int month) {
    final cacheKey = '$year-$month';
    final cachedStatuses = _getCachedStatuses(cacheKey);
    final cachedLeaveTypes = _getCachedLeaveTypes(cacheKey);
    if (cachedStatuses != null) {
      state = state.copyWith(
        monthDayStatuses: cachedStatuses,
        leaveTypeByDate: cachedLeaveTypes ?? {},
      );
    }
  }

  /// Bulk-fetch all sessions + daily summaries for a month, filling the cache.
  Future<void> _prefetchMonth(int year, int month) async {
    if (_employeeId == null) return;
    if (_prefetchedYear == year && _prefetchedMonth == month) return;

    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // last day of month
      final startStr = AppDateUtils.formatDate(startDate);
      final endStr = AppDateUtils.formatDate(endDate);

      // Fetch all sessions and all daily summaries for the month in parallel
      final results = await Future.wait([
        _repository.getSessionsByDateRange(
          employeeId: _employeeId!,
          startDate: startStr,
          endDate: endStr,
        ),
        _repository.getMonthDailySummaries(_employeeId!, startDate),
      ]);

      final allSessions = results[0] as List<Map<String, dynamic>>;
      final allSummaries = results[1] as List<Map<String, dynamic>>;

      // Group sessions by date
      final sessionsByDate = <String, List<Map<String, dynamic>>>{};
      for (final session in allSessions) {
        final dateStr = session['session_date'] as String;
        sessionsByDate.putIfAbsent(dateStr, () => []).add(session);
      }

      // Index summaries by date
      final summaryByDate = <String, Map<String, dynamic>>{};
      for (final summary in allSummaries) {
        final dateStr = summary['summary_date'] as String;
        summaryByDate[dateStr] = summary;
      }

      // Fill cache for every day in the month
      for (int day = 1; day <= endDate.day; day++) {
        final d = DateTime(year, month, day);
        final dateStr = AppDateUtils.formatDate(d);
        _cache[dateStr] = _DateCache(
          sessions: sessionsByDate[dateStr] ?? [],
          dailySummary: summaryByDate[dateStr],
        );
      }

      _prefetchedYear = year;
      _prefetchedMonth = month;
    } catch (_) {
      // Prefetch failed — individual loads will still work as fallback
    }
  }

  Future<void> loadSessionsForDate(DateTime date) async {
    if (_employeeId == null) return;

    final dateStr = AppDateUtils.formatDate(date);
    final cached = _cache[dateStr];

    if (cached != null) {
      // Show cached data instantly
      state = state.copyWith(
        isLoading: false,
        selectedDate: date,
        sessions: cached.sessions,
        dailySummary: cached.dailySummary,
        clearDailySummary: cached.dailySummary == null,
        error: null,
      );
      // Background refresh to catch any changes
      _fetchAndUpdate(date, dateStr);
    } else {
      // No cache — show loading, fetch
      state = state.copyWith(
        isLoading: true,
        selectedDate: date,
        sessions: [],
        clearDailySummary: true,
        error: null,
      );
      await _fetchAndUpdate(date, dateStr);
    }
  }

  Future<void> _fetchAndUpdate(DateTime date, String dateStr) async {
    try {
      final sessions = await _repository.getSessionsByDateRange(
        employeeId: _employeeId!,
        startDate: dateStr,
        endDate: dateStr,
      );
      final summary = await _repository.getDailySummary(
        employeeId: _employeeId!,
        date: dateStr,
      );

      // Update cache
      _cache[dateStr] = _DateCache(sessions: sessions, dailySummary: summary);

      // Only update state if still viewing this date
      if (AppDateUtils.formatDate(state.selectedDate) == dateStr) {
        state = state.copyWith(
          isLoading: false,
          sessions: sessions,
          dailySummary: summary,
          clearDailySummary: summary == null,
        );
      }
    } catch (e) {
      if (AppDateUtils.formatDate(state.selectedDate) == dateStr) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> loadMonthStatuses(int year, int month) async {
    if (_employeeId == null) return;

    final cacheKey = '$year-$month';
    final cachedStatuses = _getCachedStatuses(cacheKey);
    final cachedLeaveTypes = _getCachedLeaveTypes(cacheKey);

    // Show cached data immediately (or empty if first load)
    state = state.copyWith(
      selectedYear: year,
      selectedMonth: month,
      monthDayStatuses: cachedStatuses ?? {},
      leaveTypeByDate: cachedLeaveTypes ?? {},
    );

    try {
      final monthDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      final startStr = AppDateUtils.formatDate(monthDate);
      final endStr = AppDateUtils.formatDate(endDate);

      final summaries = await _repository.getMonthDailySummaries(
        _employeeId!,
        monthDate,
      );

      // Fetch leave records for the month to identify leave types
      final leaveTypeByDate = <String, String>{};
      try {
        final leaveRecords = await SupabaseService.client
            .from('leave_records')
            .select('start_date, end_date, leave_type:leave_types(name)')
            .eq('employee_id', _employeeId!)
            .eq('status', 'active')
            .lte('start_date', endStr)
            .gte('end_date', startStr);

        for (final lr in leaveRecords) {
          final leaveType = lr['leave_type'] as Map<String, dynamic>?;
          final typeName = leaveType?['name'] as String? ?? '';
          final lrStart = lr['start_date'] as String;
          final lrEnd = lr['end_date'] as String;

          // Fill each date in the leave range that falls within the month
          var cursor = DateTime.parse(lrStart);
          final rangeEnd = DateTime.parse(lrEnd);
          while (!cursor.isAfter(rangeEnd)) {
            final cursorStr = AppDateUtils.formatDate(cursor);
            if (cursorStr.compareTo(startStr) >= 0 && cursorStr.compareTo(endStr) <= 0) {
              leaveTypeByDate[cursorStr] = typeName;
            }
            cursor = cursor.add(const Duration(days: 1));
          }
        }
      } catch (_) {
        // Non-critical — fall back to no leave type differentiation
      }

      final statuses = <String, String>{};
      for (final s in summaries) {
        final dateStr = s['summary_date'] as String;
        final totalWork = (s['total_work_minutes'] as num?)?.toInt() ?? 0;
        final overtime = (s['total_overtime_minutes'] as num?)?.toInt() ?? 0;
        final expected = (s['expected_work_minutes'] as num?)?.toInt() ?? 0;
        final dayStatus = s['status'] as String? ?? '';

        if (dayStatus == 'leave') {
          // Check if it's sick leave
          final leaveTypeName = leaveTypeByDate[dateStr]?.toLowerCase() ?? '';
          if (leaveTypeName.contains('hastalık') || leaveTypeName.contains('sick')) {
            statuses[dateStr] = 'sick_leave';
          } else {
            statuses[dateStr] = 'leave';
          }
        } else if (dayStatus == 'holiday') {
          final workDayType = s['work_day_type'] as String? ?? '';
          statuses[dateStr] = workDayType == 'half_holiday' ? 'half_holiday' : 'holiday';
        } else if (s['is_holiday'] == true) {
          final workDayType = s['work_day_type'] as String? ?? '';
          statuses[dateStr] = workDayType == 'half_holiday' ? 'half_holiday' : 'holiday';
        } else if (overtime > 0) {
          statuses[dateStr] = 'overtime';
        } else if (totalWork > 0 && totalWork >= expected) {
          statuses[dateStr] = 'full';
        } else if (totalWork > 0 && totalWork < expected) {
          statuses[dateStr] = 'missing';
        }
      }
      // Cache the results
      _saveCachedMonth(cacheKey, statuses, leaveTypeByDate);

      // Only update state if still viewing this month
      if (state.selectedYear == year && state.selectedMonth == month) {
        state = state.copyWith(
          monthDayStatuses: statuses,
          leaveTypeByDate: leaveTypeByDate,
        );
      }
    } catch (_) {
      // Silently fail — statuses are visual only
    }
  }

  void setFocusedMonth(DateTime month) {
    // Pre-fetch the new month's data when user swipes calendar
    _prefetchMonth(month.year, month.month);
    loadMonthStatuses(month.year, month.month);
  }

  void _invalidateMonthStatusCache(int year, int month) {
    _removeCachedMonth('$year-$month');
  }

  Future<void> editSession({
    required String sessionId,
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    if (_employeeId == null) throw Exception('Not authenticated');

    final clockIn = DateTime(date.year, date.month, date.day, startHour, startMinute);
    final clockOut = DateTime(date.year, date.month, date.day, endHour, endMinute);

    if (clockOut.isBefore(clockIn) || clockOut.isAtSameMomentAs(clockIn)) {
      throw Exception('exit_before_entry');
    }

    await _repository.updateSession(
      sessionId: sessionId,
      clockIn: clockIn.toIso8601String(),
      clockOut: clockOut.toIso8601String(),
    );

    final dateStr = AppDateUtils.formatDate(date);
    _cache.remove(dateStr);

    await loadSessionsForDate(date);
    _invalidateMonthStatusCache(state.selectedYear, state.selectedMonth);
    await loadMonthStatuses(state.selectedYear, state.selectedMonth);
  }

  Future<void> createManualSession({
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    if (_employeeId == null) throw Exception('Not authenticated');

    final dateStr = AppDateUtils.formatDate(date);
    final clockIn = DateTime(date.year, date.month, date.day, startHour, startMinute);
    final clockOut = DateTime(date.year, date.month, date.day, endHour, endMinute);

    if (clockOut.isBefore(clockIn) || clockOut.isAtSameMomentAs(clockIn)) {
      throw Exception('exit_before_entry');
    }

    await _repository.createManualSession(
      sessionDate: dateStr,
      clockIn: clockIn.toIso8601String(),
      clockOut: clockOut.toIso8601String(),
    );

    // Invalidate cache for this date
    _cache.remove(dateStr);

    // Refresh data
    await loadSessionsForDate(date);
    _invalidateMonthStatusCache(state.selectedYear, state.selectedMonth);
    await loadMonthStatuses(state.selectedYear, state.selectedMonth);
  }

  Future<void> deleteSession(String sessionId, DateTime date) async {
    final dateStr = AppDateUtils.formatDate(date);
    _cache.remove(dateStr);

    await _repository.deleteSession(sessionId);
    await loadSessionsForDate(date);
    _invalidateMonthStatusCache(state.selectedYear, state.selectedMonth);
    await loadMonthStatuses(state.selectedYear, state.selectedMonth);
  }
}

final sessionHistoryProvider =
    StateNotifierProvider<SessionHistoryNotifier, SessionHistoryState>((ref) {
  final authState = ref.watch(authProvider);
  final repository = ref.watch(sessionRepositoryProvider);
  return SessionHistoryNotifier(repository, authState.profile?.id);
});
