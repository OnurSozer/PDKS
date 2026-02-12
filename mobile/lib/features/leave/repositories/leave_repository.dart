import 'dart:convert';
import '../../../core/services/supabase_service.dart';

class LeaveRepository {
  final _client = SupabaseService.client;

  Future<List<Map<String, dynamic>>> getLeaveBalances({
    required String employeeId,
    required int year,
  }) async {
    final response = await _client
        .from('leave_balances')
        .select('*, leave_type:leave_types(*)')
        .eq('employee_id', employeeId)
        .eq('year', year);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getLeaveRecords(String employeeId) async {
    final response = await _client
        .from('leave_records')
        .select('*, leave_type:leave_types(*)')
        .eq('employee_id', employeeId)
        .order('start_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getLeaveTypes(String companyId) async {
    final response = await _client
        .from('leave_types')
        .select()
        .eq('company_id', companyId)
        .eq('is_active', true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> recordLeave({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    final response = await _client.functions.invoke(
      'record-leave',
      body: {
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return jsonDecode(response.data as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelLeave(String leaveRecordId) async {
    final response = await _client.functions.invoke(
      'cancel-leave',
      body: {'leave_record_id': leaveRecordId},
    );
    return jsonDecode(response.data as String) as Map<String, dynamic>;
  }
}
