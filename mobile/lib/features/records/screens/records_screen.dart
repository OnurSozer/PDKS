import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';
import '../providers/records_provider.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(recordsProvider.notifier).loadRecords(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                child: Text(
                  l10n.statistics,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),

              // Year/Month selectors
              const SizedBox(height: 12),
              _MonthYearSelector(
                year: state.selectedYear,
                month: state.selectedMonth,
                l10n: l10n,
                onChanged: (year, month) {
                  ref.read(recordsProvider.notifier).loadRecordsForMonth(year, month);
                },
              ),
              const SizedBox(height: 16),

              // Gradient summary card
              _GradientSummaryCard(state: state, l10n: l10n),
              const SizedBox(height: 20),

              // Details header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  l10n.details,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),

              // 2x3 stat grid
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _StatsGrid(state: state, l10n: l10n),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthYearSelector extends StatelessWidget {
  final int year;
  final int month;
  final AppLocalizations l10n;
  final void Function(int year, int month) onChanged;

  const _MonthYearSelector({
    required this.year,
    required this.month,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final monthNames = l10n.shortMonthNames;
    final now = DateTime.now();

    return Row(
      children: [
        // Month dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.borderColor, width: 0.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: month,
                isDense: true,
                isExpanded: true,
                dropdownColor: AppConstants.cardColor,
                style: const TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                items: List.generate(12, (i) {
                  final m = i + 1;
                  final isFuture = year == now.year && m > now.month;
                  return DropdownMenuItem(
                    value: m,
                    enabled: !isFuture,
                    child: Text(
                      monthNames[i],
                      style: TextStyle(
                        color: isFuture ? AppConstants.textMuted : AppConstants.textPrimary,
                      ),
                    ),
                  );
                }),
                onChanged: (val) {
                  if (val != null) onChanged(year, val);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Year dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderColor, width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: year,
              isDense: true,
              dropdownColor: AppConstants.cardColor,
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              items: List.generate(5, (i) {
                final y = now.year - 2 + i;
                return DropdownMenuItem(value: y, child: Text('$y'));
              }),
              onChanged: (val) {
                if (val != null) onChanged(val, month);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientSummaryCard extends StatelessWidget {
  final RecordsState state;
  final AppLocalizations l10n;

  const _GradientSummaryCard({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final worked = state.totalWorkedMinutes;
    final hours = worked ~/ 60;
    final minutes = worked % 60;
    final pct = state.completionPercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF59E0B),
            Color(0xFF92400E),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_history_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.monthlyWork,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$hours',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: l10n.hoursAbbrev,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: '$minutes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: l10n.minutesAbbrev,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Completion badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pct.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final RecordsState state;
  final AppLocalizations l10n;

  const _StatsGrid({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final netMin = state.netMinutes;
    final netColor = netMin >= 0
        ? const Color(0xFF10B981) // emerald
        : const Color(0xFFF43F5E); // rose
    final netSign = netMin >= 0 ? '+' : '';

    return Column(
      children: [
        // Row 1: Worked Days | Expected Hours
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.calendar_today,
              iconColor: AppConstants.primaryColor,
              value: '${state.workDaysCount}',
              label: l10n.workedDays,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.schedule_outlined,
              iconColor: const Color(0xFF6366F1),
              value: AppDateUtils.formatDurationLocalized(
                state.totalExpectedMinutes,
                l10n.hoursAbbrev,
                l10n.minutesAbbrev,
              ),
              label: l10n.expectedHours,
            )),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Total Duration | Net Hours
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.timer_outlined,
              iconColor: AppConstants.clockInColor,
              value: AppDateUtils.formatDurationLocalized(
                state.totalWorkedMinutes,
                l10n.hoursAbbrev,
                l10n.minutesAbbrev,
              ),
              label: l10n.totalDuration,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: netMin >= 0 ? Icons.trending_up : Icons.trending_down,
              iconColor: netColor,
              value: '$netSign${AppDateUtils.formatDurationLocalized(
                netMin.abs(),
                l10n.hoursAbbrev,
                l10n.minutesAbbrev,
              )}',
              label: l10n.netHours,
              valueColor: netColor,
            )),
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: Overtime Hours | OT %
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.more_time_outlined,
              iconColor: AppConstants.overtimeColor,
              value: AppDateUtils.formatDurationLocalized(
                state.overtimeValue.round(),
                l10n.hoursAbbrev,
                l10n.minutesAbbrev,
              ),
              label: l10n.overtimeHoursTotal,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.percent_outlined,
              iconColor: const Color(0xFFF59E0B),
              value: '${state.overtimePercentage.toStringAsFixed(1)}%',
              label: l10n.otPercent,
            )),
          ],
        ),
        const SizedBox(height: 12),
        // Row 4: Deficit | OT Days
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.remove_circle_outline,
              iconColor: const Color(0xFFF43F5E),
              value: AppDateUtils.formatDurationLocalized(
                state.totalDeficitMinutes,
                l10n.hoursAbbrev,
                l10n.minutesAbbrev,
              ),
              label: l10n.deficitHours,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.event_available_outlined,
              iconColor: const Color(0xFFF59E0B),
              value: state.overtimeDays.toStringAsFixed(2),
              label: l10n.otDays,
            )),
          ],
        ),
        const SizedBox(height: 12),
        // Row 5: Late Days | Absent Days
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.watch_later_outlined,
              iconColor: const Color(0xFFF97316),
              value: '${state.lateDaysCount}',
              label: l10n.lateDays,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.person_off_outlined,
              iconColor: const Color(0xFFF43F5E),
              value: '${state.absentDaysCount}',
              label: l10n.absentDays,
            )),
          ],
        ),
        const SizedBox(height: 12),
        // Row 6: Daily Average | Used Leave
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.speed_outlined,
              iconColor: AppConstants.overtimeColor,
              value: AppDateUtils.formatDurationLocalized(
                state.dailyAverageMinutes,
                l10n.hoursAbbrev,
                l10n.minutesAbbrev,
              ),
              label: l10n.dailyAverage,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.beach_access_outlined,
              iconColor: AppConstants.leaveColor,
              value: '${state.usedLeaveDays}',
              label: l10n.usedLeave,
            )),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
