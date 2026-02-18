import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../leave/providers/leave_provider.dart';
import '../providers/session_history_provider.dart';
import '../widgets/month_pill_bar.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/calendar_legend.dart';
import '../widgets/day_bottom_sheet.dart';

class SessionHistoryScreen extends ConsumerStatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  ConsumerState<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends ConsumerState<SessionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionHistoryProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with year pill
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.calendar,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  // Year pill — bordered, right-aligned
                  GestureDetector(
                    onTap: () => _showYearPicker(state.selectedYear),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppConstants.borderColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.selectedYear}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18, color: AppConstants.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Month pill bar
            MonthPillBar(
              selectedYear: state.selectedYear,
              selectedMonth: state.selectedMonth,
              onMonthChanged: (month) {
                ref.read(sessionHistoryProvider.notifier).loadMonthStatuses(
                  state.selectedYear,
                  month,
                );
              },
              onYearChanged: (year) {
                ref.read(sessionHistoryProvider.notifier).loadMonthStatuses(
                  year,
                  state.selectedMonth,
                );
              },
            ),
            const SizedBox(height: 20),

            // Calendar grid
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CalendarGrid(
                      year: state.selectedYear,
                      month: state.selectedMonth,
                      selectedDate: state.selectedDate,
                      dayStatuses: state.monthDayStatuses,
                      onDayTap: (date) {
                        ref.read(sessionHistoryProvider.notifier).loadSessionsForDate(date);
                        _showDayBottomSheet(date);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Legend
                    const CalendarLegend(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Year Picker ----

  void _showYearPicker(int currentYear) {
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - 4 + i); // 4 years back + current

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            ...years.map((year) {
              final isSelected = year == currentYear;
              final isFuture = year > now.year;
              return ListTile(
                onTap: isFuture ? null : () {
                  Navigator.of(ctx).pop();
                  ref.read(sessionHistoryProvider.notifier).loadMonthStatuses(
                    year,
                    ref.read(sessionHistoryProvider).selectedMonth,
                  );
                },
                title: Text(
                  '$year',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isFuture
                        ? AppConstants.textMuted
                        : isSelected
                            ? AppConstants.primaryColor
                            : AppConstants.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppConstants.primaryColor, size: 20)
                    : null,
              );
            }),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  // ---- Day Bottom Sheet ----

  void _showDayBottomSheet(DateTime date) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final state = ref.watch(sessionHistoryProvider);
          final isLeaveDay = state.dailySummary?['status'] == 'leave';
          final dateStr = AppDateUtils.formatDate(date);
          return DayBottomSheet(
            date: date,
            dailySummary: state.dailySummary,
            sessions: state.sessions,
            leaveTypeName: state.leaveTypeByDate[dateStr],
            onAddSession: () {
              Navigator.of(ctx).pop();
              _showManualSessionDialog(date);
            },
            onMarkLeaveDay: () {
              Navigator.of(ctx).pop();
              _showLeaveTypeSelection(date);
            },
            onCancelLeave: isLeaveDay
                ? () {
                    Navigator.of(ctx).pop();
                    _confirmCancelLeave(date);
                  }
                : null,
            onEditSession: (session) {
              Navigator.of(ctx).pop();
              _showEditSessionDialog(session, date);
            },
            onDeleteSession: (session) {
              Navigator.of(ctx).pop();
              _confirmDeleteSession(session, date);
            },
          );
        },
      ),
    );
  }

  // ---- Cancel Leave ----

  void _confirmCancelLeave(DateTime date) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.cancelLeave,
          style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.cancelLeaveConfirm,
          style: const TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _doCancelLeave(date);
            },
            child: Text(l10n.confirm, style: const TextStyle(color: AppConstants.errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _doCancelLeave(DateTime date) async {
    final l10n = AppLocalizations.of(context);
    final dateStr = AppDateUtils.formatDate(date);

    try {
      // Find the active leave record that covers this date
      final userId = ref.read(authProvider).profile?.id;
      if (userId == null) return;

      final result = await SupabaseService.client
          .from('leave_records')
          .select('id')
          .eq('employee_id', userId)
          .eq('status', 'active')
          .lte('start_date', dateStr)
          .gte('end_date', dateStr)
          .limit(1)
          .maybeSingle();

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error)),
          );
        }
        return;
      }

      final leaveRecordId = result['id'] as String;
      final success = await ref.read(leaveProvider.notifier).cancelLeave(leaveRecordId);

      if (mounted && success) {
        // Refresh calendar data
        final notifier = ref.read(sessionHistoryProvider.notifier);
        notifier.loadSessionsForDate(date);
        notifier.loadMonthStatuses(
          ref.read(sessionHistoryProvider).selectedYear,
          ref.read(sessionHistoryProvider).selectedMonth,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.success),
            backgroundColor: AppConstants.onTimeColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  // ---- Manual Session Dialog ----

  void _showManualSessionDialog(DateTime date) {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 30);
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
    String selectedType = 'normal';

    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) {
          return AlertDialog(
            backgroundColor: AppConstants.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              l10n.manualSessionTitle,
              style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppConstants.primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        AppDateUtils.formatDisplayDate(date),
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Start time picker
                _buildTimePickerRow(
                  context: builderContext,
                  icon: Icons.login,
                  iconColor: AppConstants.clockInColor,
                  label: l10n.entryTime,
                  time: startTime,
                  onPicked: (picked) => setState(() => startTime = picked),
                ),
                const SizedBox(height: 12),

                // End time picker
                _buildTimePickerRow(
                  context: builderContext,
                  icon: Icons.logout,
                  iconColor: AppConstants.clockOutColor,
                  label: l10n.exitTime,
                  time: endTime,
                  onPicked: (picked) => setState(() => endTime = picked),
                ),
                const SizedBox(height: 12),

                // Session type dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.cardLightColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppConstants.borderColor, width: 0.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType,
                      dropdownColor: AppConstants.cardColor,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppConstants.textSecondary),
                      style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14),
                      items: [
                        DropdownMenuItem(
                          value: 'normal',
                          child: Text(l10n.normalShift),
                        ),
                        DropdownMenuItem(
                          value: 'boss_call',
                          child: Text(l10n.calledByBoss),
                        ),
                        DropdownMenuItem(
                          value: 'overtime',
                          child: Text(l10n.overtimeSession),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel, style: const TextStyle(color: AppConstants.textSecondary)),
              ),
              TextButton(
                onPressed: () => _submitManualSession(
                  dialogContext,
                  date,
                  startTime,
                  endTime,
                ),
                child: Text(
                  l10n.create,
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSessionDialog(Map<String, dynamic> session, DateTime date) {
    final clockIn = DateTime.parse(session['clock_in'] as String);
    final clockOutRaw = session['clock_out'] as String?;
    final clockOut = clockOutRaw != null ? DateTime.parse(clockOutRaw) : null;

    TimeOfDay startTime = TimeOfDay(hour: clockIn.hour, minute: clockIn.minute);
    TimeOfDay endTime = clockOut != null
        ? TimeOfDay(hour: clockOut.hour, minute: clockOut.minute)
        : const TimeOfDay(hour: 18, minute: 0);

    final l10n = AppLocalizations.of(context);
    final sessionId = session['id'] as String;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) {
          return AlertDialog(
            backgroundColor: AppConstants.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              l10n.editSession,
              style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppConstants.primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        AppDateUtils.formatDisplayDate(date),
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildTimePickerRow(
                  context: builderContext,
                  icon: Icons.login,
                  iconColor: AppConstants.clockInColor,
                  label: l10n.entryTime,
                  time: startTime,
                  onPicked: (picked) => setState(() => startTime = picked),
                ),
                const SizedBox(height: 12),
                _buildTimePickerRow(
                  context: builderContext,
                  icon: Icons.logout,
                  iconColor: AppConstants.clockOutColor,
                  label: l10n.exitTime,
                  time: endTime,
                  onPicked: (picked) => setState(() => endTime = picked),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel, style: const TextStyle(color: AppConstants.textSecondary)),
              ),
              TextButton(
                onPressed: () => _submitEditSession(
                  dialogContext,
                  sessionId,
                  date,
                  startTime,
                  endTime,
                ),
                child: Text(
                  l10n.save,
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitEditSession(
    BuildContext dialogContext,
    String sessionId,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    final l10n = AppLocalizations.of(context);

    Navigator.of(dialogContext).pop();

    _showLoadingDialog(l10n.save);

    try {
      await ref.read(sessionHistoryProvider.notifier).editSession(
        sessionId: sessionId,
        date: date,
        startHour: startTime.hour,
        startMinute: startTime.minute,
        endHour: endTime.hour,
        endMinute: endTime.minute,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSuccessDialog(l10n.success, l10n.sessionEdited);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        final errorMsg = e.toString().contains('exit_before_entry')
            ? l10n.exitBeforeEntry
            : e.toString().replaceAll('Exception: ', '');
        _showErrorDialog(l10n.error, errorMsg);
      }
    }
  }

  Widget _buildTimePickerRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required TimeOfDay time,
    required void Function(TimeOfDay) onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.cardLightColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppConstants.borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(
              '$label:',
              style: const TextStyle(color: AppConstants.textSecondary, fontSize: 14),
            ),
            const Spacer(),
            Text(
              time.format(context),
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitManualSession(
    BuildContext dialogContext,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    final l10n = AppLocalizations.of(context);

    Navigator.of(dialogContext).pop(); // Close the dialog

    // Show loading
    _showLoadingDialog(l10n.creatingSession);

    try {
      await ref.read(sessionHistoryProvider.notifier).createManualSession(
        date: date,
        startHour: startTime.hour,
        startMinute: startTime.minute,
        endHour: endTime.hour,
        endMinute: endTime.minute,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        _showSuccessDialog(l10n.success, l10n.sessionCreated);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        final errorMsg = e.toString().contains('exit_before_entry')
            ? l10n.exitBeforeEntry
            : e.toString().replaceAll('Exception: ', '');
        _showErrorDialog(l10n.error, errorMsg);
      }
    }
  }

  // ---- Leave Type Selection ----

  void _showLeaveTypeSelection(DateTime date) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.selectLeaveType,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Normal Leave
            _LeaveTypeOption(
              icon: Icons.beach_access,
              iconColor: AppConstants.mealReadyColor,
              title: l10n.normalLeave,
              subtitle: l10n.normalLeaveSubtitle,
              onTap: () {
                Navigator.of(ctx).pop();
                _showLeaveConfirmation(date, isSickLeave: false);
              },
            ),
            const SizedBox(height: 16),

            // Sick Leave
            _LeaveTypeOption(
              icon: Icons.local_hospital,
              iconColor: AppConstants.clockInColor,
              title: l10n.sickLeave,
              subtitle: l10n.sickLeaveSubtitle,
              onTap: () {
                Navigator.of(ctx).pop();
                _showLeaveConfirmation(date, isSickLeave: true);
              },
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  // ---- Leave Confirmation ----

  void _showLeaveConfirmation(DateTime date, {required bool isSickLeave}) {
    final l10n = AppLocalizations.of(context);
    final leaveTypeName = isSickLeave ? l10n.sickLeave : l10n.normalLeave;
    final iconColor = isSickLeave ? AppConstants.clockInColor : AppConstants.mealReadyColor;
    final icon = isSickLeave ? Icons.local_hospital : Icons.beach_access;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                leaveTypeName,
                style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppDateUtils.formatDisplayDate(date),
              style: const TextStyle(color: AppConstants.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.fullDay,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSickLeave ? l10n.noDeductionInfo : l10n.deductionInfo,
                          style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: AppConstants.textSecondary)),
          ),
          TextButton(
            onPressed: () => _processLeaveDay(dialogContext, date, isSickLeave: isSickLeave),
            child: Text(
              l10n.markButton,
              style: TextStyle(color: iconColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processLeaveDay(
    BuildContext dialogContext,
    DateTime date, {
    required bool isSickLeave,
  }) async {
    final l10n = AppLocalizations.of(context);

    Navigator.of(dialogContext).pop(); // Close confirmation dialog

    // Find matching leave type from leave provider
    final leaveState = ref.read(leaveProvider);
    final leaveTypes = leaveState.leaveTypes;

    // Try to find a matching leave type
    String? leaveTypeId;
    for (final lt in leaveTypes) {
      final name = (lt['name'] as String? ?? '').toLowerCase();
      if (isSickLeave && (name.contains('hastalık') || name.contains('sick'))) {
        leaveTypeId = lt['id'] as String;
        break;
      }
      if (!isSickLeave && (name.contains('yıllık') || name.contains('normal') || name.contains('annual'))) {
        leaveTypeId = lt['id'] as String;
        break;
      }
    }

    // If no match found, use the first available type
    if (leaveTypeId == null && leaveTypes.isNotEmpty) {
      leaveTypeId = leaveTypes.first['id'] as String;
    }

    if (leaveTypeId == null) {
      _showErrorDialog(l10n.error, l10n.noLeaveTypes);
      return;
    }

    _showLoadingDialog(l10n.savingLeave);

    try {
      final dateStr = AppDateUtils.formatDate(date);
      await ref.read(leaveProvider.notifier).recordLeave(
        leaveTypeId: leaveTypeId,
        startDate: dateStr,
        endDate: dateStr,
        reason: isSickLeave ? 'Hastalık İzni' : null,
      );

      // Refresh calendar data
      final histState = ref.read(sessionHistoryProvider);
      await ref.read(sessionHistoryProvider.notifier).loadSessionsForDate(date);
      await ref.read(sessionHistoryProvider.notifier).loadMonthStatuses(
        histState.selectedYear,
        histState.selectedMonth,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        _showSuccessDialog(l10n.success, l10n.leaveMarked);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        _showErrorDialog(l10n.error, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // ---- Delete Session ----

  void _confirmDeleteSession(Map<String, dynamic> session, DateTime date) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.deleteSession,
          style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.deleteSessionConfirm,
          style: const TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: AppConstants.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              _showLoadingDialog(l10n.deleting);

              try {
                final sessionId = session['id'] as String;
                await ref.read(sessionHistoryProvider.notifier).deleteSession(sessionId, date);

                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop(); // Close loading
                  _showSuccessDialog(l10n.success, l10n.sessionDeleted);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop(); // Close loading
                  _showErrorDialog(l10n.error, e.toString().replaceAll('Exception: ', ''));
                }
              }
            },
            child: Text(
              l10n.deleteSession,
              style: const TextStyle(color: AppConstants.errorColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Dialogs ----

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 20),
            Text(message, style: const TextStyle(color: AppConstants.textPrimary)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppConstants.clockInColor),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppConstants.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppLocalizations.of(context).ok,
              style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppConstants.errorColor),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppConstants.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppLocalizations.of(context).ok,
              style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveTypeOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LeaveTypeOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: iconColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor,
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
              Icon(Icons.chevron_right, color: iconColor.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
