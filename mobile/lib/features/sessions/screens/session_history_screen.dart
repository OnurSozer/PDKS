import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';
import '../../home/widgets/session_card.dart';
import '../../home/widgets/today_summary.dart';
import '../providers/session_history_provider.dart';

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionHistoryProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionHistory),
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime.now().add(const Duration(days: 1)),
            focusedDay: state.focusedMonth,
            selectedDayPredicate: (day) =>
                AppDateUtils.isSameDay(day, state.selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              ref
                  .read(sessionHistoryProvider.notifier)
                  .loadSessionsForDate(selectedDay);
              ref
                  .read(sessionHistoryProvider.notifier)
                  .setFocusedMonth(focusedDay);
            },
            onPageChanged: (focusedDay) {
              ref
                  .read(sessionHistoryProvider.notifier)
                  .setFocusedMonth(focusedDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(color: AppConstants.textPrimary),
              weekendTextStyle: const TextStyle(color: AppConstants.textSecondary),
              outsideTextStyle: const TextStyle(color: AppConstants.textMuted),
              todayTextStyle: const TextStyle(color: AppConstants.textPrimary),
              selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              disabledTextStyle: const TextStyle(color: AppConstants.textMuted),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, color: AppConstants.primaryColor),
              rightChevronIcon: const Icon(Icons.chevron_right, color: AppConstants.primaryColor),
              formatButtonTextStyle: const TextStyle(color: AppConstants.primaryColor),
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: AppConstants.primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
              weekendStyle: TextStyle(color: AppConstants.textMuted, fontSize: 13),
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
          const Divider(height: 1),
          // Summary for selected date
          if (state.dailySummary != null)
            TodaySummary(summary: state.dailySummary),
          // Sessions list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_busy,
                              size: 48,
                              color: AppConstants.textMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noSessions,
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.sessions.length,
                        itemBuilder: (context, index) {
                          final session = state.sessions[index];
                          return InkWell(
                            onTap: () {
                              context.push(
                                '/sessions/${session['id']}',
                                extra: session,
                              );
                            },
                            child: SessionCard(session: session),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
