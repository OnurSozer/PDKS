import '../../../core/services/supabase_service.dart';

class SessionRepository {
  final _client = SupabaseService.client;

  Map<String, dynamic> _parseResponse(dynamic data) {
    return data is String
        ? (Map<String, dynamic>.from(data as dynamic))
        : data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> clockIn({DateTime? customTime}) async {
    final body = <String, dynamic>{};
    if (customTime != null) {
      body['clock_in_time'] = customTime.toIso8601String();
    }
    final response = await _client.functions.invoke(
      'clock-in',
      body: body,
    );
    return _parseResponse(response.data);
  }

  Future<Map<String, dynamic>> clockOut(String sessionId, {DateTime? customTime}) async {
    final body = <String, dynamic>{'session_id': sessionId};
    if (customTime != null) {
      body['clock_out_time'] = customTime.toIso8601String();
    }
    final response = await _client.functions.invoke(
      'clock-out',
      body: body,
    );
    return _parseResponse(response.data);
  }

  Future<Map<String, dynamic>> submitMissedClockOut({
    required String sessionId,
    required String clockOutTime,
  }) async {
    final response = await _client.functions.invoke(
      'submit-missed-clockout',
      body: {
        'session_id': sessionId,
        'clock_out_time': clockOutTime,
      },
    );
    return _parseResponse(response.data);
  }

  Future<Map<String, dynamic>> notifyMealReady() async {
    final response = await _client.functions.invoke(
      'notify-meal-ready',
      body: {},
    );
    return _parseResponse(response.data);
  }

  Future<List<Map<String, dynamic>>> getTodaySessions(String employeeId) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final response = await _client
        .from('work_sessions')
        .select()
        .eq('employee_id', employeeId)
        .eq('session_date', dateStr)
        .neq('status', 'cancelled')
        .order('clock_in', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSessionsByDateRange({
    required String employeeId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _client
        .from('work_sessions')
        .select()
        .eq('employee_id', employeeId)
        .gte('session_date', startDate)
        .lte('session_date', endDate)
        .neq('status', 'cancelled')
        .order('clock_in', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getActiveSession(String employeeId) async {
    final response = await _client
        .from('work_sessions')
        .select()
        .eq('employee_id', employeeId)
        .eq('status', 'active')
        .isFilter('clock_out', null)
        .maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>?> getDailySummary({
    required String employeeId,
    required String date,
  }) async {
    final response = await _client
        .from('daily_summaries')
        .select()
        .eq('employee_id', employeeId)
        .eq('summary_date', date)
        .maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> getMonthDailySummaries(
    String employeeId,
    DateTime month,
  ) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    final startStr =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr =
        '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final response = await _client
        .from('daily_summaries')
        .select()
        .eq('employee_id', employeeId)
        .gte('summary_date', startStr)
        .lte('summary_date', endStr)
        .order('summary_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createManualSession({
    required String sessionDate,
    required String clockIn,
    required String clockOut,
  }) async {
    final response = await _client.functions.invoke(
      'manage-manual-session',
      body: {
        'action': 'create',
        'session_date': sessionDate,
        'clock_in': clockIn,
        'clock_out': clockOut,
      },
    );
    final data = _parseResponse(response.data);
    return Map<String, dynamic>.from(data['session'] as Map);
  }

  Future<Map<String, dynamic>> updateSession({
    required String sessionId,
    required String clockIn,
    required String clockOut,
  }) async {
    final response = await _client.functions.invoke(
      'manage-manual-session',
      body: {
        'action': 'update',
        'session_id': sessionId,
        'clock_in': clockIn,
        'clock_out': clockOut,
      },
    );
    final data = _parseResponse(response.data);
    return Map<String, dynamic>.from(data['session'] as Map);
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.functions.invoke(
      'manage-manual-session',
      body: {
        'action': 'delete',
        'session_id': sessionId,
      },
    );
  }

  Stream<List<Map<String, dynamic>>> subscribeToSessions(String employeeId) {
    return _client
        .from('work_sessions')
        .stream(primaryKey: ['id'])
        .eq('employee_id', employeeId);
  }
}
