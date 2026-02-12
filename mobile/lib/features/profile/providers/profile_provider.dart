import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';

class ScheduleState {
  final bool isLoading;
  final Map<String, dynamic>? schedule;
  final Map<String, dynamic>? shiftTemplate;
  final String? error;

  const ScheduleState({
    this.isLoading = false,
    this.schedule,
    this.shiftTemplate,
    this.error,
  });
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final String? _employeeId;

  ScheduleNotifier(this._employeeId) : super(const ScheduleState()) {
    if (_employeeId != null) {
      loadSchedule();
    }
  }

  Future<void> loadSchedule() async {
    if (_employeeId == null) return;
    state = const ScheduleState(isLoading: true);
    try {
      final response = await SupabaseService.client
          .from('employee_schedules')
          .select('*, shift_template:shift_templates(*)')
          .eq('employee_id', _employeeId)
          .isFilter('effective_to', null)
          .order('effective_from', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        state = ScheduleState(
          schedule: response,
          shiftTemplate: response['shift_template'] as Map<String, dynamic>?,
        );
      } else {
        state = const ScheduleState();
      }
    } catch (e) {
      state = ScheduleState(error: e.toString());
    }
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final authState = ref.watch(authProvider);
  return ScheduleNotifier(authState.profile?.id);
});
