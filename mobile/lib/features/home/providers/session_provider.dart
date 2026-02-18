import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/session_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/date_utils.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

// Session state
class SessionState {
  final bool isLoading;
  final List<Map<String, dynamic>> todaySessions;
  final Map<String, dynamic>? activeSession;
  final Map<String, dynamic>? dailySummary;
  final String? error;

  const SessionState({
    this.isLoading = false,
    this.todaySessions = const [],
    this.activeSession,
    this.dailySummary,
    this.error,
  });

  SessionState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? todaySessions,
    Map<String, dynamic>? activeSession,
    Map<String, dynamic>? dailySummary,
    String? error,
    bool clearActiveSession = false,
  }) {
    return SessionState(
      isLoading: isLoading ?? this.isLoading,
      todaySessions: todaySessions ?? this.todaySessions,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      dailySummary: dailySummary ?? this.dailySummary,
      error: error,
    );
  }

  bool get isClockedIn => activeSession != null;
}

class SessionNotifier extends StateNotifier<SessionState> {
  final SessionRepository _repository;
  final String? _employeeId;
  StreamSubscription? _subscription;

  SessionNotifier(this._repository, this._employeeId) : super(const SessionState()) {
    if (_employeeId != null) {
      loadTodayData();
      _startRealtimeSubscription();
    }
  }

  void _startRealtimeSubscription() {
    if (_employeeId == null) return;
    _subscription = _repository.subscribeToSessions(_employeeId).listen((_) {
      loadTodayData();
    });
  }

  Future<void> loadTodayData() async {
    if (_employeeId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _repository.getTodaySessions(_employeeId);
      final activeSession = await _repository.getActiveSession(_employeeId);
      final todayStr = AppDateUtils.formatDate(DateTime.now());
      final summary = await _repository.getDailySummary(
        employeeId: _employeeId,
        date: todayStr,
      );

      state = SessionState(
        isLoading: false,
        todaySessions: sessions,
        activeSession: activeSession,
        dailySummary: summary,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> clockIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.clockIn();
      await loadTodayData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> clockOut() async {
    final sessionId = state.activeSession?['id'] as String?;
    if (sessionId == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.clockOut(sessionId);
      // Immediately clear active session so button flips to Start
      state = state.copyWith(isLoading: false, clearActiveSession: true);
      // Refresh full data in background
      loadTodayData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> submitMissedClockOut({
    required String sessionId,
    required DateTime clockOutTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.submitMissedClockOut(
        sessionId: sessionId,
        clockOutTime: clockOutTime.toIso8601String(),
      );
      await loadTodayData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkMissedClockOut() async {
    if (_employeeId == null) return null;
    try {
      final activeSession = await _repository.getActiveSession(_employeeId);
      if (activeSession != null) {
        final clockIn = DateTime.parse(activeSession['clock_in'] as String);
        if (!AppDateUtils.isToday(clockIn)) {
          return activeSession;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> notifyMealReady() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.notifyMealReady();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final authState = ref.watch(authProvider);
  final repository = ref.watch(sessionRepositoryProvider);
  return SessionNotifier(repository, authState.profile?.id);
});
