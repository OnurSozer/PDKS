import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../providers/leave_provider.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaveProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(leaveProvider.notifier).loadAll(),
          child: ListView(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  l10n.leave,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),

              // Leave Balances Section
              if (state.balances.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    l10n.leaveBalance,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ...state.balances.map((balance) => _BalanceCard(balance: balance)),
              ],

              // Leave Records Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  l10n.leaveHistory,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppConstants.paddingLG),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.records.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLG),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.beach_access, size: 48, color: AppConstants.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noLeaveRecords,
                          style: const TextStyle(color: AppConstants.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...state.records.map(
                  (record) => _LeaveRecordCard(
                    record: record,
                    onCancel: () => _confirmCancel(context, ref, record, l10n),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> record,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelLeave),
        content: Text(l10n.cancelLeaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(leaveProvider.notifier).cancelLeave(record['id'] as String);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.clockOutColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Map<String, dynamic> balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final leaveType = balance['leave_type'] as Map<String, dynamic>?;
    final typeName = leaveType?['name'] as String? ?? '-';
    final totalDays = (balance['total_days'] as num?)?.toDouble() ?? 0;
    final usedDays = (balance['used_days'] as num?)?.toDouble() ?? 0;
    final remaining = totalDays - usedDays;
    final progress = totalDays > 0 ? usedDays / totalDays : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppConstants.leaveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.beach_access, size: 18, color: AppConstants.leaveColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  typeName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Text(
                remaining.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.leaveColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppConstants.borderColor,
              color: AppConstants.leaveColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.usedDays}: ${usedDays.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
              ),
              Text(
                '${l10n.remainingDays}: ${remaining.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.leaveColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaveRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onCancel;

  const _LeaveRecordCard({required this.record, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final leaveType = record['leave_type'] as Map<String, dynamic>?;
    final typeName = leaveType?['name'] as String? ?? '-';
    final startDate = record['start_date'] as String;
    final endDate = record['end_date'] as String;
    final totalDays = (record['total_days'] as num?)?.toDouble() ?? 0;
    final reason = record['reason'] as String?;
    final status = record['status'] as String;
    final isActive = status == 'active';
    final isCancelled = status == 'cancelled';

    Color statusColor() {
      if (isActive) return AppConstants.clockInColor;
      if (isCancelled) return AppConstants.clockOutColor;
      return AppConstants.primaryColor;
    }

    String statusLabel() {
      if (isActive) return l10n.active;
      if (isCancelled) return l10n.cancelled;
      return status;
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                typeName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppConstants.textMuted),
              const SizedBox(width: 6),
              Text(
                '$startDate  —  $endDate',
                style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
              ),
              const Spacer(),
              Text(
                '${totalDays.toStringAsFixed(1)} ${l10n.totalDays.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: const TextStyle(fontSize: 13, color: AppConstants.textMuted),
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: AppConstants.clockOutColor),
                child: Text(l10n.cancelLeave),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
