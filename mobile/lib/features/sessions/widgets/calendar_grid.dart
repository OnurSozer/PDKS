import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime? selectedDate;
  final Map<String, String> dayStatuses; // "yyyy-MM-dd" -> "full"|"overtime"|"missing"|"leave"
  final ValueChanged<DateTime> onDayTap;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    this.selectedDate,
    required this.dayStatuses,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dayNames = l10n.shortDayNames;
    final firstWeekday = AppDateUtils.firstWeekdayOfMonth(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();

    // Calculate total cells needed (padding + days)
    final leadingEmpty = firstWeekday - 1; // Monday=1 => 0 leading cells
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day name headers
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: dayNames.map((name) => Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          // Day grid
          ...List.generate(rows, (row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - leadingEmpty + 1;

                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return Expanded(child: AspectRatio(aspectRatio: 1, child: SizedBox()));
                  }

                  final date = DateTime(year, month, dayNum);
                  final dateStr = AppDateUtils.formatDate(date);
                  final status = dayStatuses[dateStr];
                  final isToday = AppDateUtils.isSameDay(date, now);
                  final isSelected = selectedDate != null &&
                      AppDateUtils.isSameDay(date, selectedDate!);
                  final isFuture = date.isAfter(now);
                  final isWeekend = col >= 5;

                  // Determine cell styling
                  Color bgColor = AppConstants.cardColor;
                  Color borderColor = AppConstants.borderColor;
                  double borderWidth = 0.5;

                  if (isToday) {
                    bgColor = AppConstants.primaryColor;
                    borderColor = AppConstants.primaryLight;
                    borderWidth = 2;
                  } else if (isSelected) {
                    bgColor = AppConstants.primaryColor.withValues(alpha: 0.15);
                    borderColor = AppConstants.primaryColor;
                    borderWidth = 1.5;
                  } else if (status != null) {
                    borderColor = _statusColor(status);
                    borderWidth = 2;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: GestureDetector(
                        onTap: isFuture ? null : () => onDayTap(date),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: borderColor,
                                width: borderWidth,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isToday || isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isFuture
                                        ? AppConstants.textMuted.withValues(alpha: 0.4)
                                        : isToday
                                            ? Colors.white
                                            : isSelected
                                                ? AppConstants.primaryColor
                                                : isWeekend
                                                    ? AppConstants.textSecondary
                                                    : AppConstants.textPrimary,
                                  ),
                                ),
                                if (status != null && !isToday) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _statusColor(status),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'full':
        return AppConstants.fullShiftColor;
      case 'overtime':
        return AppConstants.overtimeShiftColor;
      case 'missing':
        return AppConstants.missingShiftColor;
      case 'leave':
        return AppConstants.leaveColor;
      default:
        return AppConstants.textMuted;
    }
  }
}
