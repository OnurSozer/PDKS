import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/clock_button.dart';
import '../widgets/meal_ready_button.dart';
import '../widgets/session_card.dart';
import '../widgets/today_summary.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMissedClockOut();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(sessionProvider.notifier).loadTodayData();
      _checkMissedClockOut();
    }
  }

  Future<void> _checkMissedClockOut() async {
    final missedSession =
        await ref.read(sessionProvider.notifier).checkMissedClockOut();
    if (missedSession != null && mounted) {
      _showMissedClockOutDialog(missedSession);
    }
  }

  void _showMissedClockOutDialog(Map<String, dynamic> session) {
    final l10n = AppLocalizations.of(context);
    final clockIn = DateTime.parse(session['clock_in'] as String);
    var selectedTime = TimeOfDay(hour: 18, minute: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.missedClockOutTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.missedClockOutMessage),
              const SizedBox(height: 16),
              Text(
                '${l10n.clockInTime}: ${AppDateUtils.formatDisplayDateTime(clockIn)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setDialogState(() => selectedTime = time);
                  }
                },
                icon: const Icon(Icons.access_time),
                label: Text(
                  '${l10n.selectDepartureTime}: ${selectedTime.format(ctx)}',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final clockOutTime = DateTime(
                  clockIn.year,
                  clockIn.month,
                  clockIn.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                Navigator.of(ctx).pop();
                ref.read(sessionProvider.notifier).submitMissedClockOut(
                      sessionId: session['id'] as String,
                      clockOutTime: clockOutTime,
                    );
              },
              child: Text(l10n.submitMissedClockOut),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final sessionState = ref.watch(sessionProvider);
    final l10n = AppLocalizations.of(context);
    final isChef = authState.profile?.isChef ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home),
        actions: [
          if (authState.profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  authState.profile!.fullName,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(sessionProvider.notifier).loadTodayData(),
        child: ListView(
          children: [
            const SizedBox(height: AppConstants.paddingLG),
            // Status text
            Center(
              child: Text(
                _getStatusText(sessionState, l10n),
                style: TextStyle(
                  fontSize: 16,
                  color: sessionState.isClockedIn
                      ? AppConstants.clockInColor
                      : AppConstants.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLG),
            // Clock button
            Center(
              child: ClockButton(
                isClockedIn: sessionState.isClockedIn,
                isLoading: sessionState.isLoading,
                onPressed: () => _handleClockAction(sessionState, l10n),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLG),
            // Meal Ready button (Chef only)
            if (isChef)
              MealReadyButton(
                isLoading: sessionState.isLoading,
                onPressed: () => _handleMealReady(l10n),
              ),
            // Today's summary
            TodaySummary(summary: sessionState.dailySummary),
            // Today's sessions
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
                vertical: AppConstants.paddingSM,
              ),
              child: Text(
                l10n.todaySessions,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (sessionState.todaySessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLG),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noSessionsToday,
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...sessionState.todaySessions.map(
                (session) => SessionCard(session: session),
              ),
            const SizedBox(height: AppConstants.paddingLG),
          ],
        ),
      ),
    );
  }

  String _getStatusText(SessionState sessionState, AppLocalizations l10n) {
    if (sessionState.isClockedIn) {
      final clockIn =
          DateTime.parse(sessionState.activeSession!['clock_in'] as String);
      return '${l10n.clockedInSince} ${AppDateUtils.formatTime(clockIn)}';
    }
    return l10n.notClockedIn;
  }

  Future<void> _handleClockAction(
      SessionState sessionState, AppLocalizations l10n) async {
    bool success;
    if (sessionState.isClockedIn) {
      success = await ref.read(sessionProvider.notifier).clockOut();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clockOutSuccess)),
        );
      }
    } else {
      success = await ref.read(sessionProvider.notifier).clockIn();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clockInSuccess)),
        );
      }
    }
    if (!success && mounted && sessionState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sessionState.error!),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _handleMealReady(AppLocalizations l10n) async {
    final success = await ref.read(sessionProvider.notifier).notifyMealReady();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mealReadySent),
          backgroundColor: AppConstants.mealReadyColor,
        ),
      );
    }
  }
}
