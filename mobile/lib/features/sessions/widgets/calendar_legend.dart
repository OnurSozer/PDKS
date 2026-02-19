import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
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
            emoji: '\u{1F334}',
          ),
          _LegendItem(
            color: AppConstants.sickLeaveColor,
            label: l10n.sickLeave,
            emoji: '\u{1F3E5}',
          ),
          _LegendItem(
            color: AppConstants.holidayColor,
            label: l10n.holiday,
            emoji: '\u{1F389}',
          ),
        ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String? emoji;

  const _LegendItem({required this.color, required this.label, this.emoji});

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
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
        ],
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
