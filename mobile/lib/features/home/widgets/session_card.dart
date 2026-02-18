import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;

  const SessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clockIn = DateTime.parse(session['clock_in'] as String);
    final clockOutStr = session['clock_out'] as String?;
    final clockOut = clockOutStr != null ? DateTime.parse(clockOutStr) : null;
    final status = session['status'] as String;
    final totalMinutes = session['total_minutes'] as int?;
    final isActive = status == 'active';

    // Date badge text
    final dayLabel = AppDateUtils.isToday(clockIn)
        ? l10n.today
        : AppDateUtils.isYesterday(clockIn)
            ? l10n.yesterday
            : AppDateUtils.formatShortWeekday(clockIn);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                dayLabel.length > 3 ? dayLabel.substring(0, 3) : dayLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Time info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      AppDateUtils.formatTime(clockIn),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    if (clockOut != null) ...[
                      Text(
                        '  -  ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConstants.textMuted,
                        ),
                      ),
                      Text(
                        AppDateUtils.formatTime(clockOut),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Status + Duration column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: status, l10n: l10n),
              if (totalMinutes != null) ...[
                const SizedBox(height: 4),
                Text(
                  AppDateUtils.formatDuration(totalMinutes),
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.clockInColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;

  const _StatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      'active' => (l10n.active, AppConstants.clockInColor.withValues(alpha: 0.1), AppConstants.clockInColor),
      'completed' => ('ON TIME', AppConstants.clockInColor.withValues(alpha: 0.1), AppConstants.clockInColor),
      'edited' => (l10n.edited, AppConstants.overtimeColor.withValues(alpha: 0.1), AppConstants.overtimeColor),
      'cancelled' => (l10n.cancelled, AppConstants.errorColor.withValues(alpha: 0.1), AppConstants.errorColor),
      _ => (status, AppConstants.textMuted.withValues(alpha: 0.1), AppConstants.textMuted),
    };

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
}
