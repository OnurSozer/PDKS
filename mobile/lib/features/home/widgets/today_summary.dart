import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';

class TodaySummary extends StatelessWidget {
  final Map<String, dynamic>? summary;

  const TodaySummary({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalMinutes = summary?['total_work_minutes'] as int? ?? 0;
    final regularMinutes = summary?['total_regular_minutes'] as int? ?? 0;
    final overtimeMinutes = summary?['total_overtime_minutes'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingSM,
      ),
      child: Row(
        children: [
          // Total hours card (purple gradient)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppConstants.primaryLight, AppConstants.primaryDark],
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.white.withValues(alpha: 0.8), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        l10n.totalHours,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppDateUtils.formatHoursMinutes(totalMinutes),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Regular + Overtime column
          Expanded(
            child: Column(
              children: [
                _MiniSummaryCard(
                  label: l10n.regularHours,
                  value: AppDateUtils.formatHoursMinutes(regularMinutes),
                  icon: Icons.work_outline,
                  color: AppConstants.clockInColor,
                ),
                const SizedBox(height: 8),
                _MiniSummaryCard(
                  label: l10n.overtimeHours,
                  value: AppDateUtils.formatHoursMinutes(overtimeMinutes),
                  icon: Icons.more_time,
                  color: AppConstants.overtimeColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSM),
        border: Border.all(color: AppConstants.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
