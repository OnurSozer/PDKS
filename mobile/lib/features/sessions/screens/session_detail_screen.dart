import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    l10n.sessionDetail,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(status, l10n),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingMD),
                children: [
                  // Time card
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMD),
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(color: AppConstants.borderColor, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.date,
                          value: sessionDate,
                        ),
                        Divider(height: 20, color: AppConstants.borderColor),
                        _DetailRow(
                          icon: Icons.login,
                          iconColor: AppConstants.clockInColor,
                          label: l10n.clockInTime,
                          value: AppDateUtils.formatDisplayDateTime(clockIn),
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.logout,
                          iconColor: AppConstants.clockOutColor,
                          label: l10n.clockOutTime,
                          value: clockOut != null
                              ? AppDateUtils.formatDisplayDateTime(clockOut)
                              : '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMD),

                  // Duration card
                  if (totalMinutes != null)
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMD),
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: AppConstants.borderColor, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.timer_outlined,
                            label: l10n.duration,
                            value: AppDateUtils.formatDuration(totalMinutes),
                            valueStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                          if (regularMinutes != null) ...[
                            Divider(height: 20, color: AppConstants.borderColor),
                            _DetailRow(
                              icon: Icons.work_outline,
                              label: l10n.regularHours,
                              value: AppDateUtils.formatDuration(regularMinutes),
                            ),
                          ],
                          if (overtimeMinutes != null && overtimeMinutes > 0) ...[
                            const SizedBox(height: 8),
                            _DetailRow(
                              icon: Icons.more_time,
                              iconColor: AppConstants.overtimeColor,
                              label: l10n.overtimeHours,
                              value: AppDateUtils.formatDuration(overtimeMinutes),
                              valueStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.overtimeColor,
                              ),
                            ),
                            if (overtimeMultiplier != null) ...[
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.close,
                                label: l10n.multiplier,
                                value: '${overtimeMultiplier}x',
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                  // Notes card
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.paddingMD),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppConstants.paddingMD),
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: AppConstants.borderColor, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notes_outlined, size: 20, color: AppConstants.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                l10n.notes,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notes,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'active' => AppConstants.clockInColor,
      'completed' => AppConstants.clockInColor,
      'edited' => AppConstants.warningColor,
      'cancelled' => AppConstants.clockOutColor,
      _ => AppConstants.textSecondary,
    };
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppConstants.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: valueStyle ?? const TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
