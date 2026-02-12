import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../providers/profile_provider.dart';

class ScheduleViewScreen extends ConsumerWidget {
  const ScheduleViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySchedule),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.schedule == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_busy, size: 64, color: AppConstants.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noScheduleAssigned,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildScheduleView(context, state, l10n),
    );
  }

  Widget _buildScheduleView(
    BuildContext context,
    ScheduleState state,
    AppLocalizations l10n,
  ) {
    final schedule = state.schedule!;
    final template = state.shiftTemplate;

    final shiftName = template?['name'] as String? ?? '-';
    final startTime = template?['start_time'] as String? ??
        schedule['custom_start_time'] as String? ??
        '-';
    final endTime = template?['end_time'] as String? ??
        schedule['custom_end_time'] as String? ??
        '-';
    final breakMinutes = template?['break_duration_minutes'] as int? ??
        schedule['custom_break_duration_minutes'] as int? ??
        0;
    final workDays = (template?['work_days'] as List<dynamic>?) ??
        (schedule['custom_work_days'] as List<dynamic>?) ??
        [];

    final dayNames = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScheduleRow(
                  icon: Icons.badge_outlined,
                  label: l10n.shiftName,
                  value: shiftName,
                ),
                const Divider(),
                _ScheduleRow(
                  icon: Icons.login,
                  label: l10n.shiftStart,
                  value: _formatTime(startTime),
                ),
                _ScheduleRow(
                  icon: Icons.logout,
                  label: l10n.shiftEnd,
                  value: _formatTime(endTime),
                ),
                _ScheduleRow(
                  icon: Icons.coffee_outlined,
                  label: l10n.breakDuration,
                  value: '${breakMinutes}m',
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.workDays,
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final dayNumber = index + 1;
                    final isWorkDay = workDays.contains(dayNumber);
                    return Chip(
                      label: Text(dayNames[index]),
                      backgroundColor: isWorkDay
                          ? AppConstants.primaryColor.withValues(alpha: 0.15)
                          : AppConstants.inputColor,
                      labelStyle: TextStyle(
                        color: isWorkDay
                            ? AppConstants.primaryColor
                            : AppConstants.textMuted,
                        fontWeight:
                            isWorkDay ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isWorkDay
                            ? AppConstants.primaryColor.withValues(alpha: 0.3)
                            : AppConstants.borderColor,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(String time) {
    // Handle "HH:MM:SS" format from DB
    if (time.contains(':') && time.length > 5) {
      return time.substring(0, 5);
    }
    return time;
  }
}

class _ScheduleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ScheduleRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
