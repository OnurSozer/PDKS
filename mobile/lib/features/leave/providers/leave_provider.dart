import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/leave_repository.dart';
import '../../auth/providers/auth_provider.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository();
});

class LeaveState {
  final bool isLoading;
  final List<Map<String, dynamic>> balances;
  final List<Map<String, dynamic>> records;
  final List<Map<String, dynamic>> leaveTypes;
  final String? error;

  const LeaveState({
    this.isLoading = false,
    this.balances = const [],
    this.records = const [],
    this.leaveTypes = const [],
    this.error,
  });

  LeaveState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? balances,
    List<Map<String, dynamic>>? records,
    List<Map<String, dynamic>>? leaveTypes,
    String? error,
  }) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
      balances: balances ?? this.balances,
      records: records ?? this.records,
      leaveTypes: leaveTypes ?? this.leaveTypes,
      error: error,
    );
  }
}

class LeaveNotifier extends StateNotifier<LeaveState> {
  final LeaveRepository _repository;
  final String? _employeeId;
  final String? _companyId;

  LeaveNotifier(this._repository, this._employeeId, this._companyId)
      : super(const LeaveState()) {
    if (_employeeId != null && _companyId != null) {
      loadAll();
    }
  }

  Future<void> loadAll() async {
    if (_employeeId == null || _companyId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final employeeId = _employeeId;
      final companyId = _companyId;
      final year = DateTime.now().year;
      final results = await Future.wait([
        _repository.getLeaveBalances(
          employeeId: employeeId,
          year: year,
        ),
        _repository.getLeaveRecords(employeeId),
        _repository.getLeaveTypes(companyId),
      ]);

      state = LeaveState(
        balances: results[0],
        records: results[1],
        leaveTypes: results[2],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> recordLeave({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.recordLeave(
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      await loadAll();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelLeave(String leaveRecordId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.cancelLeave(leaveRecordId);
      await loadAll();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final leaveProvider = StateNotifierProvider<LeaveNotifier, LeaveState>((ref) {
  final authState = ref.watch(authProvider);
  final repository = ref.watch(leaveRepositoryProvider);
  return LeaveNotifier(
    repository,
    authState.profile?.id,
    authState.profile?.companyId,
  );
});
