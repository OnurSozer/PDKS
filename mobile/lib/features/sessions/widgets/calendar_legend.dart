import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          _LegendItem(
            color: AppConstants.fullShiftColor,
            label: l10n.fullShift,
          ),
          _LegendItem(
            color: AppConstants.overtimeShiftColor,
            label: l10n.overtimeShift,
          ),
          _LegendItem(
            color: AppConstants.missingShiftColor,
            label: l10n.missing,
          ),
          _LegendItem(
            color: AppConstants.leaveColor,
            label: l10n.leave,
          ),
          _LegendItem(
            color: AppConstants.sickLeaveColor,
            label: l10n.sickLeave,
          ),
          _LegendItem(
            color: AppConstants.holidayColor,
            label: l10n.holiday,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }
}
