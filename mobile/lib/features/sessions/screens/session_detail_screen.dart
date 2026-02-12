import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';

class SessionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clockIn = DateTime.parse(session['clock_in'] as String);
    final clockOutStr = session['clock_out'] as String?;
    final clockOut = clockOutStr != null ? DateTime.parse(clockOutStr) : null;
    final status = session['status'] as String;
    final totalMinutes = session['total_minutes'] as int?;
    final regularMinutes = session['regular_minutes'] as int?;
    final overtimeMinutes = session['overtime_minutes'] as int?;
    final overtimeMultiplier = session['overtime_multiplier'];
    final notes = session['notes'] as String?;
    final sessionDate = session['session_date'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionDetail),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        children: [
          _DetailCard(
            children: [
              _DetailRow(label: l10n.date, value: sessionDate),
              _DetailRow(
                label: l10n.clockInTime,
                value: AppDateUtils.formatDisplayDateTime(clockIn),
              ),
              _DetailRow(
                label: l10n.clockOutTime,
                value: clockOut != null
                    ? AppDateUtils.formatDisplayDateTime(clockOut)
                    : '-',
              ),
              _DetailRow(label: l10n.status, value: _getStatusLabel(status, l10n)),
            ],
          ),
          if (totalMinutes != null)
            _DetailCard(
              children: [
                _DetailRow(
                  label: l10n.duration,
                  value: AppDateUtils.formatDuration(totalMinutes),
                ),
                if (regularMinutes != null)
                  _DetailRow(
                    label: l10n.regularHours,
                    value: AppDateUtils.formatDuration(regularMinutes),
                  ),
                if (overtimeMinutes != null && overtimeMinutes > 0) ...[
                  _DetailRow(
                    label: l10n.overtimeHours,
                    value: AppDateUtils.formatDuration(overtimeMinutes),
                  ),
                  if (overtimeMultiplier != null)
                    _DetailRow(
                      label: 'Multiplier',
                      value: '${overtimeMultiplier}x',
                    ),
                ],
              ],
            ),
          if (notes != null && notes.isNotEmpty)
            _DetailCard(
              children: [
                _DetailRow(label: 'Notes', value: notes),
              ],
            ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    return switch (status) {
      'active' => l10n.active,
      'completed' => l10n.completed,
      'edited' => l10n.edited,
      'cancelled' => l10n.cancelled,
      _ => status,
    };
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMD),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Column(children: children),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
