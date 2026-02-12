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

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingSM,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.todaySummary,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMD),
            Row(
              children: [
                _SummaryItem(
                  label: l10n.totalHours,
                  value: AppDateUtils.formatHoursMinutes(totalMinutes),
                  color: AppConstants.primaryColor,
                  icon: Icons.schedule,
                ),
                _SummaryItem(
                  label: l10n.regularHours,
                  value: AppDateUtils.formatHoursMinutes(regularMinutes),
                  color: AppConstants.clockInColor,
                  icon: Icons.work_outline,
                ),
                _SummaryItem(
                  label: l10n.overtimeHours,
                  value: AppDateUtils.formatHoursMinutes(overtimeMinutes),
                  color: AppConstants.overtimeColor,
                  icon: Icons.more_time,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
