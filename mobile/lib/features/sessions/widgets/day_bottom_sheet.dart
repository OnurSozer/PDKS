import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';

class DayBottomSheet extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic>? dailySummary;
  final List<Map<String, dynamic>> sessions;
  final VoidCallback? onAddSession;
  final VoidCallback? onMarkLeaveDay;
  final void Function(Map<String, dynamic>)? onSessionTap;
  final void Function(Map<String, dynamic>)? onDeleteSession;

  const DayBottomSheet({
    super.key,
    required this.date,
    this.dailySummary,
    this.sessions = const [],
    this.onAddSession,
    this.onMarkLeaveDay,
    this.onSessionTap,
    this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalMinutes = dailySummary?['total_work_minutes'] as int? ?? 0;
    final expectedMinutes = dailySummary?['expected_work_minutes'] as int? ?? 0;
    final overtimeMinutes = dailySummary?['total_overtime_minutes'] as int? ?? 0;
    final isLate = dailySummary?['is_late'] == true;
    final status = dailySummary?['status'] as String? ?? '';

    // First clock in / last clock out
    String clockInStr = '--:--';
    String clockOutStr = '--:--';
    if (sessions.isNotEmpty) {
      final firstSession = sessions.last;
      final lastSession = sessions.first;
      final clockIn = DateTime.parse(firstSession['clock_in'] as String);
      clockInStr = AppDateUtils.formatTime(clockIn);
      final clockOutRaw = lastSession['clock_out'] as String?;
      if (clockOutRaw != null) {
        clockOutStr = AppDateUtils.formatTime(DateTime.parse(clockOutRaw));
      }
    }

    final hasSessions = sessions.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Date header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatDisplayDate(date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    if (hasSessions) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${sessions.length} ${l10n.sessions.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (status.isNotEmpty) _buildStatusBadge(status, isLate, l10n),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary info (only if sessions exist)
          if (hasSessions || dailySummary != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.cardLightColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.login,
                            iconColor: AppConstants.clockInColor,
                            label: l10n.clockInTime,
                            value: clockInStr,
                          ),
                        ),
                        Container(width: 1, height: 40, color: AppConstants.borderColor),
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.logout,
                            iconColor: AppConstants.clockOutColor,
                            label: l10n.clockOutTime,
                            value: clockOutStr,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: AppConstants.borderColor),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: l10n.totalHours,
                          value: AppDateUtils.formatHoursMinutes(totalMinutes),
                          color: AppConstants.primaryColor,
                        ),
                        if (overtimeMinutes > 0)
                          _StatItem(
                            label: l10n.overtimeHours,
                            value: '+${AppDateUtils.formatDuration(overtimeMinutes)}',
                            color: AppConstants.overtimeColor,
                          ),
                        if (expectedMinutes > 0 && totalMinutes < expectedMinutes)
                          _StatItem(
                            label: l10n.missing,
                            value: AppDateUtils.formatDuration(expectedMinutes - totalMinutes),
                            color: AppConstants.warningColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Session list
            if (sessions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${sessions.length} ${l10n.sessions.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ...sessions.map((session) {
                final clockIn = DateTime.parse(session['clock_in'] as String);
                final clockOutRaw = session['clock_out'] as String?;
                final minutes = session['total_minutes'] as int?;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.cardLightColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AppConstants.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        AppDateUtils.formatTime(clockIn),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
                      ),
                      Text(' — ', style: TextStyle(color: AppConstants.textMuted)),
                      Text(
                        clockOutRaw != null
                            ? AppDateUtils.formatTime(DateTime.parse(clockOutRaw))
                            : '--:--',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
                      ),
                      const Spacer(),
                      if (minutes != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppDateUtils.formatDuration(minutes),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      if (onDeleteSession != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => onDeleteSession!(session),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppConstants.errorColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline, size: 16, color: AppConstants.errorColor),
                          ),
                        ),
                      ],
                      if (onSessionTap != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => onSessionTap!(session),
                          child: const Icon(Icons.chevron_right, size: 18, color: AppConstants.textMuted),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
          ] else ...[
            // Empty day — show icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, color: AppConstants.primaryColor, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      AppDateUtils.formatDisplayDate(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Action cards — large card-style like reference
          if (onAddSession != null || onMarkLeaveDay != null) ...[
            if (onAddSession != null)
              _ActionCard(
                icon: Icons.add_circle_outline,
                iconBgColor: AppConstants.primaryColor,
                title: l10n.addSession,
                subtitle: l10n.addSessionSubtitle,
                borderColor: AppConstants.primaryColor,
                onTap: onAddSession!,
              ),
            if (onAddSession != null && onMarkLeaveDay != null)
              const SizedBox(height: 12),
            if (onMarkLeaveDay != null)
              _ActionCard(
                icon: Icons.beach_access,
                iconBgColor: AppConstants.leaveColor,
                title: l10n.markLeaveDay,
                subtitle: l10n.markLeaveDaySubtitle,
                borderColor: AppConstants.leaveColor,
                onTap: onMarkLeaveDay!,
              ),
          ],

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isLate, AppLocalizations l10n) {
    final (label, bgColor, textColor) = _getStatusInfo(status, isLate, l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  (String, Color, Color) _getStatusInfo(String status, bool isLate, AppLocalizations l10n) {
    if (status == 'leave') {
      return (l10n.leave, AppConstants.leaveColor.withValues(alpha: 0.15), AppConstants.leaveColor);
    }
    if (status == 'holiday') {
      return (l10n.holiday, AppConstants.mealReadyColor.withValues(alpha: 0.15), AppConstants.mealReadyColor);
    }
    if (status == 'absent') {
      return (l10n.absent, AppConstants.errorColor.withValues(alpha: 0.15), AppConstants.errorColor);
    }
    if (isLate) {
      return (l10n.lateLabel, AppConstants.lateColor.withValues(alpha: 0.15), AppConstants.lateColor);
    }
    if (status == 'complete') {
      return (l10n.onTime, AppConstants.onTimeColor.withValues(alpha: 0.15), AppConstants.onTimeColor);
    }
    return (l10n.active, AppConstants.primaryColor.withValues(alpha: 0.15), AppConstants.primaryColor);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: borderColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: borderColor.withValues(alpha: 0.5), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
      ],
    );
  }
}
