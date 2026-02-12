import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        title: Text(l10n.leave),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/leave/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.recordLeave),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(leaveProvider.notifier).loadAll(),
        child: ListView(
          children: [
            // Leave Balances Section
            if (state.balances.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingMD,
                  AppConstants.paddingMD,
                  AppConstants.paddingMD,
                  AppConstants.paddingSM,
                ),
                child: Text(
                  l10n.leaveBalance,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...state.balances.map((balance) => _BalanceCard(balance: balance)),
            ],
            // Leave Records Section
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingMD,
                AppConstants.paddingMD,
                AppConstants.paddingMD,
                AppConstants.paddingSM,
              ),
              child: Text(
                l10n.leaveHistory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                      Icon(Icons.beach_access, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noLeaveRecords,
                        style: TextStyle(color: AppConstants.textSecondary),
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
            const SizedBox(height: 80), // Space for FAB
          ],
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
              backgroundColor: AppConstants.errorColor,
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

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              typeName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: AppConstants.leaveColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.usedDays}: ${usedDays.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                ),
                Text(
                  '${l10n.remainingDays}: ${remaining.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.leaveColor,
                  ),
                ),
              ],
            ),
          ],
        ),
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

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isActive ? AppConstants.clockInColor : AppConstants.errorColor)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? l10n.active : l10n.cancelled,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppConstants.clockInColor
                          : AppConstants.errorColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppConstants.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '$startDate  -  $endDate',
                  style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${totalDays.toStringAsFixed(1)} ${l10n.totalDays.toLowerCase()}',
                  style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                ),
              ],
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                reason,
                style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(foregroundColor: AppConstants.errorColor),
                  child: Text(l10n.cancelLeave),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
