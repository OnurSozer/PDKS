import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/repositories/session_repository.dart';
import '../../home/providers/session_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/date_utils.dart';

class SessionHistoryState {
  final bool isLoading;
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final List<Map<String, dynamic>> sessions;
  final Map<String, dynamic>? dailySummary;
  final String? error;

  SessionHistoryState({
    this.isLoading = false,
    DateTime? selectedDate,
    DateTime? focusedMonth,
    this.sessions = const [],
    this.dailySummary,
    this.error,
  })  : selectedDate = selectedDate ?? DateTime.now(),
        focusedMonth = focusedMonth ?? DateTime.now();

  SessionHistoryState copyWith({
    bool? isLoading,
    DateTime? selectedDate,
    DateTime? focusedMonth,
    List<Map<String, dynamic>>? sessions,
    Map<String, dynamic>? dailySummary,
    String? error,
  }) {
    return SessionHistoryState(
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      sessions: sessions ?? this.sessions,
      dailySummary: dailySummary ?? this.dailySummary,
      error: error,
    );
  }
}

class SessionHistoryNotifier extends StateNotifier<SessionHistoryState> {
  final SessionRepository _repository;
  final String? _employeeId;

  SessionHistoryNotifier(this._repository, this._employeeId)
      : super(SessionHistoryState()) {
    if (_employeeId != null) {
      loadSessionsForDate(DateTime.now());
    }
  }

  Future<void> loadSessionsForDate(DateTime date) async {
    if (_employeeId == null) return;
    state = state.copyWith(
      isLoading: true,
      selectedDate: date,
      error: null,
    );
    try {
      final dateStr = AppDateUtils.formatDate(date);
      final sessions = await _repository.getSessionsByDateRange(
        employeeId: _employeeId,
        startDate: dateStr,
        endDate: dateStr,
      );
      final summary = await _repository.getDailySummary(
        employeeId: _employeeId,
        date: dateStr,
      );
      state = state.copyWith(
        isLoading: false,
        sessions: sessions,
        dailySummary: summary,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFocusedMonth(DateTime month) {
    state = state.copyWith(focusedMonth: month);
  }
}

final sessionHistoryProvider =
    StateNotifierProvider<SessionHistoryNotifier, SessionHistoryState>((ref) {
  final authState = ref.watch(authProvider);
  final repository = ref.watch(sessionRepositoryProvider);
  return SessionHistoryNotifier(repository, authState.profile?.id);
});
