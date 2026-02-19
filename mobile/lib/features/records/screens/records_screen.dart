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
    final netMin = state.netMinutes;
    final isExtra = netMin >= 0;
    final diffLabel = isExtra ? l10n.extra : l10n.missing;
    // Extra: OT% formula (with multiplier)
    // Deficit: deficit days / constant * 100 (no multiplier)
    final displayPct = isExtra
        ? state.overtimePercentage
        : (state.expectedDailyMinutes > 0 && state.monthlyConstant > 0)
            ? (netMin.abs() / state.expectedDailyMinutes / state.monthlyConstant) * 100
            : 0.0;
    final deviationStr = '${isExtra ? '+' : '-'}${displayPct.toStringAsFixed(2)}%';

    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left card: Aylık Çalışma
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFF92400E)],
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.work_history_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20),
                    const SizedBox(width: 6),
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
          ),
        ),
        const SizedBox(width: 12),
        // Right card: Percentage (extra/missing)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isExtra
                    ? [const Color(0xFF10B981), const Color(0xFF065F46)]
                    : [const Color(0xFFF43F5E), const Color(0xFF9F1239)],
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: (isExtra ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isExtra ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      diffLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  deviationStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
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

  String _formatTimeFull(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '$hours ${l10n.hoursFull}';
    return '$hours ${l10n.hoursFull} $minutes ${l10n.minutesFull}';
  }

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
              title: l10n.workedDays,
              value: '${state.workDaysCount} ${l10n.daysFull}',
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.schedule_outlined,
              iconColor: const Color(0xFF6366F1),
              title: l10n.expectedHours,
              value: _formatTimeFull(state.totalExpectedMinutes),
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
              title: l10n.totalDuration,
              value: _formatTimeFull(state.totalWorkedMinutes),
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: netMin >= 0 ? Icons.trending_up : Icons.trending_down,
              iconColor: netColor,
              title: l10n.netHours,
              value: '$netSign${_formatTimeFull(netMin.abs())}',
              valueColor: netColor,
            )),
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: Daily Average | Deficit
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.speed_outlined,
              iconColor: AppConstants.overtimeColor,
              title: l10n.dailyAverage,
              value: _formatTimeFull(state.dailyAverageMinutes),
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.remove_circle_outline,
              iconColor: const Color(0xFFF43F5E),
              title: l10n.deficitHours,
              value: state.totalDeficitMinutes > 0
                  ? _formatTimeFull(state.totalDeficitMinutes)
                  : l10n.none,
            )),
          ],
        ),
        const SizedBox(height: 12),
        // Row 4: Annual Leave | Sick Leave
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.beach_access_outlined,
              iconColor: AppConstants.leaveColor,
              title: l10n.annualLeaveUsage,
              value: '${state.usedAnnualLeaveDays} ${l10n.daysFull}',
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.local_hospital_outlined,
              iconColor: AppConstants.sickLeaveColor,
              title: l10n.sickLeaveUsage,
              value: '${state.usedSickLeaveDays} ${l10n.daysFull}',
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
  final String title;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
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
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
