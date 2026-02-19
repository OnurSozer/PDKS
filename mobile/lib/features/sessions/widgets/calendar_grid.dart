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
  final int firstDayOfWeek; // 1 = Monday, 7 = Sunday

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    this.selectedDate,
    required this.dayStatuses,
    required this.onDayTap,
    this.firstDayOfWeek = 1,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allDayNames = l10n.shortDayNames; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]

    // Reorder day names based on first day of week
    final dayNames = _reorderDayNames(allDayNames);

    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon, 7=Sun
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();

    // Calculate leading empty cells based on first day of week
    final leadingEmpty = _leadingEmptyCells(firstWeekday);
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
                      fontSize: 12,
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
                  final isWeekend = _isWeekendColumn(col);

                  // Determine cell styling
                  Color bgColor = AppConstants.cardColor;
                  Color borderColor = AppConstants.borderColor;
                  double borderWidth = 0.5;

                  if (isToday) {
                    bgColor = AppConstants.primaryColor;
                    borderColor = AppConstants.primaryLight;
                    borderWidth = 2;
                  } else if (status != null) {
                    borderColor = _statusColor(status);
                    borderWidth = 2;
                  }

                  final emoji = _statusEmoji(status);

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
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Number — always centered
                                Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isToday
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isFuture
                                        ? AppConstants.textMuted.withValues(alpha: 0.4)
                                        : isToday
                                            ? Colors.white
                                            : isWeekend
                                                ? AppConstants.textSecondary
                                                : AppConstants.textPrimary,
                                  ),
                                ),
                                // Dot + emoji offset below the centered number
                                if (status != null && !isToday)
                                  Transform.translate(
                                    offset: const Offset(0, 18),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _statusColor(status),
                                          ),
                                        ),
                                        if (emoji != null) ...[
                                          const SizedBox(height: 5),
                                          Text(
                                            emoji,
                                            style: const TextStyle(fontSize: 8, height: 1),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
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

  /// Reorder day names based on first day of week
  List<String> _reorderDayNames(List<String> names) {
    // names is [Mon, Tue, Wed, Thu, Fri, Sat, Sun] (indices 0-6)
    if (firstDayOfWeek == 7) {
      // Sunday first: [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
      return [names[6], ...names.sublist(0, 6)];
    }
    return names; // Monday first (default)
  }

  /// Calculate leading empty cells for the first row
  int _leadingEmptyCells(int firstWeekday) {
    // firstWeekday: 1=Mon, 7=Sun
    if (firstDayOfWeek == 7) {
      // Sunday-first: Sun=0 leading, Mon=1, ..., Sat=6
      return firstWeekday % 7;
    }
    // Monday-first: Mon=0 leading, Tue=1, ..., Sun=6
    return firstWeekday - 1;
  }

  /// Check if column index represents a weekend
  bool _isWeekendColumn(int col) {
    if (firstDayOfWeek == 7) {
      // Sunday-first: col 0 = Sun (weekend), col 6 = Sat (weekend)
      return col == 0 || col == 6;
    }
    // Monday-first: col 5 = Sat, col 6 = Sun
    return col >= 5;
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
      case 'sick_leave':
        return AppConstants.sickLeaveColor;
      case 'holiday':
        return AppConstants.holidayColor;
      case 'half_holiday':
        return AppConstants.holidayColor;
      default:
        return AppConstants.textMuted;
    }
  }

  String? _statusEmoji(String? status) {
    switch (status) {
      case 'leave':
        return '\u{1F334}'; // 🌴
      case 'sick_leave':
        return '\u{1F3E5}'; // 🏥
      case 'holiday':
      case 'half_holiday':
        return '\u{1F389}'; // 🎉
      default:
        return null;
    }
  }
}
