import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    l10n.mySchedule,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.schedule == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: AppConstants.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noScheduleAssigned,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildScheduleView(context, state, l10n),
            ),
          ],
        ),
      ),
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
        // Shift info card
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: AppConstants.borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScheduleRow(
                icon: Icons.badge_outlined,
                label: l10n.shiftName,
                value: shiftName,
              ),
              Divider(height: 24, color: AppConstants.borderColor),
              _ScheduleRow(
                icon: Icons.login,
                iconColor: AppConstants.clockInColor,
                label: l10n.shiftStart,
                value: _formatTime(startTime),
              ),
              const SizedBox(height: 8),
              _ScheduleRow(
                icon: Icons.logout,
                iconColor: AppConstants.clockOutColor,
                label: l10n.shiftEnd,
                value: _formatTime(endTime),
              ),
              const SizedBox(height: 8),
              _ScheduleRow(
                icon: Icons.coffee_outlined,
                label: l10n.breakDuration,
                value: '${breakMinutes}m',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.paddingMD),

        // Work days card
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: AppConstants.borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.workDays,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final dayNumber = index + 1;
                  final isWorkDay = workDays.contains(dayNumber);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isWorkDay
                          ? AppConstants.primaryColor.withValues(alpha: 0.1)
                          : AppConstants.inputColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isWorkDay
                            ? AppConstants.primaryColor.withValues(alpha: 0.3)
                            : AppConstants.borderColor,
                      ),
                    ),
                    child: Text(
                      dayNames[index],
                      style: TextStyle(
                        fontSize: 13,
                        color: isWorkDay
                            ? AppConstants.primaryColor
                            : AppConstants.textMuted,
                        fontWeight:
                            isWorkDay ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(String time) {
    if (time.contains(':') && time.length > 5) {
      return time.substring(0, 5);
    }
    return time;
  }
}

class _ScheduleRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _ScheduleRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? AppConstants.primaryColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
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
            color: AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }
}
