import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/clock_button.dart';
import '../widgets/meal_ready_button.dart';

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
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(sessionProvider.notifier).loadTodayData(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Header height estimate (welcome row + padding)
              const headerHeight = 80.0;
              final centerAreaHeight = constraints.maxHeight - headerHeight;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      // Welcome header — stays at top
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.welcomeBack.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.primaryColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authState.profile?.firstName ?? '',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                authState.profile != null && authState.profile!.firstName.isNotEmpty
                                    ? authState.profile!.firstName[0].toUpperCase()
                                    : '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Centered content area
                      Container(
                        constraints: BoxConstraints(minHeight: centerAreaHeight),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Clock display — time and AM/PM on same row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  DateFormat('hh:mm').format(now),
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w800,
                                    color: AppConstants.textPrimary,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('a', Localizations.localeOf(context).languageCode).format(now),
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w800,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d', Localizations.localeOf(context).languageCode).format(now),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppConstants.textSecondary,
                              ),
                            ),

                            // Status badge
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: sessionState.isClockedIn
                                    ? AppConstants.clockInColor.withValues(alpha: 0.1)
                                    : AppConstants.textMuted.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sessionState.isClockedIn
                                          ? AppConstants.clockInColor
                                          : AppConstants.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getStatusText(sessionState, l10n),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: sessionState.isClockedIn
                                          ? AppConstants.clockInColor
                                          : AppConstants.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Clock button
                            const SizedBox(height: 36),
                            ClockButton(
                              isClockedIn: sessionState.isClockedIn,
                              isLoading: sessionState.isLoading,
                              onPressed: () => _handleClockAction(sessionState, l10n),
                            ),
                            const SizedBox(height: 28),

                            // Meal Ready button (Chef only)
                            if (isChef)
                              MealReadyButton(
                                isLoading: sessionState.isLoading,
                                onPressed: () => _handleMealReady(l10n),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
          SnackBar(
            content: Text(l10n.clockOutSuccess),
            backgroundColor: AppConstants.clockOutColor,
          ),
        );
      }
    } else {
      success = await ref.read(sessionProvider.notifier).clockIn();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clockInSuccess),
            backgroundColor: AppConstants.clockInColor,
          ),
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
