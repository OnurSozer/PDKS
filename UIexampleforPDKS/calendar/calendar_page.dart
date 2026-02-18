
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../state/session/session_provider.dart';
import '../../state/auth/auth_provider.dart';
import '../../state/day_override/day_override_provider.dart';
import '../../state/user_management/user_management_provider.dart';
import '../../core/models/models.dart';
import '../../core/utils/time_calculator.dart';
import '../../core/services/export_service.dart';
import '../theme/app_theme.dart';
import '../shared/responsive_helper.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Fetch current month's sessions on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SessionProvider>();
      provider.fetchSessionsForMonth(
        provider.focusedDate.year,
        provider.focusedDate.month,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Consume data from provider
    final provider = context.watch<SessionProvider>();
    final dayOverrideProvider = context.watch<DayOverrideProvider>(); // Listen for override updates
    final focusedDate = provider.focusedDate;
    final sessionsList = provider.getSessionsFromCache(focusedDate.year, focusedDate.month);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    // Convert List<Session> to Map<int, List<Session>> for the calendar
    final Map<int, List<Session>> sessionsMap = {};
    for (var session in sessionsList) {
      final day = session.startTime.day;
      if (!sessionsMap.containsKey(day)) {
        sessionsMap[day] = [];
      }
      sessionsMap[day]!.add(session);
    }
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(ResponsiveHelper.pagePadding(context)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Takvim",
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      // Export button
                      GestureDetector(
                        onTap: () => _showExportOptions(focusedDate),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.5)),
                          ),
                          child: Icon(
                            Icons.file_download_outlined,
                            color: Colors.green,
                            size: isMobile ? 20 : 24,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showYearPicker(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "${focusedDate.year}",
                                style: GoogleFonts.outfit(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildMonthSelector(focusedDate, isMobile),
            SizedBox(height: isMobile ? 10 : 20),
            _buildDaysOfWeek(isMobile),
            Expanded(
              child: _buildCalendarGrid(sessionsMap, focusedDate, isMobile),
            ),
            _buildLegend(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(DateTime focusedDate, bool isMobile) {
    final months = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
      "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    
    return SizedBox(
      height: isMobile ? 50 : 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
        itemBuilder: (context, index) {
          final isSelected = index + 1 == focusedDate.month;
          return GestureDetector(
            onTap: () {
              if (index + 1 != focusedDate.month) {
                final newDate = DateTime(focusedDate.year, index + 1);
                context.read<SessionProvider>().setFocusedDate(newDate);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4), // Reduced margin
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20, 
                vertical: isMobile ? 8 : 10
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: isSelected ? null : Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Text(
                  months[index],
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showYearPicker() {
    final currentFocusedDate = context.read<SessionProvider>().focusedDate;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: Text("Yıl Seçin", style: GoogleFonts.outfit(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: 10, // Show last 5 years + next 4 years
              itemBuilder: (context, index) {
                final year = DateTime.now().year - 5 + index;
                final isSelected = year == currentFocusedDate.year;
                return ListTile(
                  title: Text(
                    "$year",
                    style: GoogleFonts.outfit(
                      color: isSelected ? AppTheme.primaryColor : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    if (year != currentFocusedDate.year) {
                      final newDate = DateTime(year, currentFocusedDate.month);
                      context.read<SessionProvider>().setFocusedDate(newDate);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal", style: GoogleFonts.outfit(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDaysOfWeek(bool isMobile) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((d) => Text(
          d, 
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 12 : 14,
          )
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(Map<int, List<Session>> sessionsMap, DateTime focusedDate, bool isMobile) {
    final daysInMonth = DateUtils.getDaysInMonth(focusedDate.year, focusedDate.month);
    final firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    final paddingDays = firstWeekday - 1;
    
    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: isMobile ? 8 : 12,
        crossAxisSpacing: isMobile ? 8 : 12,
      ),
      itemCount: daysInMonth + paddingDays,
      itemBuilder: (context, index) {
        if (index < paddingDays) {
          return const SizedBox();
        }
        final day = index - paddingDays + 1;
        final date = DateTime(focusedDate.year, focusedDate.month, day);
        return _buildDayCell(date, sessionsMap[day] ?? [], isMobile);
      },
    );
  }

  Widget _buildDayCell(DateTime date, List<Session> sessions, bool isMobile) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isWeekend = date.weekday == 5 || date.weekday == 6; // Friday/Saturday weekend
    
    final hasWorked = sessions.isNotEmpty;
    
    // Check for day override (vacation/half-day) from provider
    final dayOverrideProvider = context.read<DayOverrideProvider>();
    final dayOverride = dayOverrideProvider.getOverrideForDay(date);
    final isOfficialVacation = dayOverride?.type == DayOverrideType.vacation;
    final isHalfDay = dayOverride?.type == DayOverrideType.halfDay;
    
    // Check if this is a personal day off or sick leave
    final isDayOff = sessions.any((s) => s.type == SessionType.dayOff);
    final isSickLeave = sessions.any((s) => s.type == SessionType.sickLeave);
    final isAnyLeave = isDayOff || isSickLeave;  // Treat both as leave for calculations
    final isCalledByBoss = sessions.any((s) => s.type == SessionType.calledByBoss);
    
    Duration totalDuration = Duration.zero;
    for (var s in sessions) {
      totalDuration += s.duration;
    }
    
    final totalHours = totalDuration.inMinutes / 60;
    // Get role-specific expected hours
    final userRole = context.read<SessionProvider>().userRole;
    final expectedDailyWork = TimeCalculator.getExpectedDailyWork(userRole);
    final standardHours = isHalfDay ? expectedDailyWork.inMinutes / 60 / 2 : expectedDailyWork.inMinutes / 60;
    final hasOvertime = !isAnyLeave && !isOfficialVacation && totalHours > standardHours;
    final isMissing = !isAnyLeave && !isOfficialVacation && !isWeekend && hasWorked && totalHours < standardHours;
    
    Color? bgColor;
    Color? borderColor;
    double borderWidth = 0;
    if (isToday) {
      bgColor = AppTheme.primaryColor;
      borderColor = Colors.white;
      borderWidth = 2;
    } else if (isOfficialVacation) {
      // Official vacation/holiday - red styling
      bgColor = Colors.red.withOpacity(0.2);
      borderColor = Colors.red;
      borderWidth = 2;
    } else if (isHalfDay && !hasWorked) {
      // Half-day - orange styling (only if no work yet)
      bgColor = Colors.orange.withOpacity(0.15);
      borderColor = Colors.orange;
      borderWidth = 2;
    } else if (isSickLeave) {
      // Sick leave - green/health styling
      bgColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green;
      borderWidth = 2;
    } else if (isDayOff) {
      // Personal day off - orange/vacation styling
      bgColor = Colors.orange.withOpacity(0.2);
      borderColor = Colors.orange;
      borderWidth = 2;
    } else if (isCalledByBoss) {
      // Called by boss - purple styling
      bgColor = Colors.purple.withOpacity(0.2);
      borderColor = Colors.purple;
      borderWidth = 2;
    } else if (hasWorked) {
      if (hasOvertime) {
        // Overtime - purple border with dark bg
        bgColor = AppTheme.cardDark;
        borderColor = Colors.purple.withOpacity(0.8);
        borderWidth = 2;
      } else if (isMissing) {
        // Missing hours - orange border
        bgColor = AppTheme.cardDark;
        borderColor = AppTheme.accentColor;
        borderWidth = 2;
      } else {
        // Normal work day - green border
        bgColor = AppTheme.cardDark;
        borderColor = AppTheme.secondaryColor;
        borderWidth = 2;
      }
    } else if (isWeekend) {
      bgColor = Colors.white.withOpacity(0.02);
    }
    
    return GestureDetector(
      onTap: () {
        if (hasWorked) {
          _showDayDetails(date, sessions);
        } else {
          // Show bottom sheet for empty days
          _showEmptyDayOptions(date);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          border: borderWidth > 0 
              ? Border.all(color: borderColor!, width: borderWidth)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${date.day}",
                style: GoogleFonts.outfit(
                  color: isToday 
                      ? Colors.white 
                      : (isDayOff 
                          ? Colors.orange 
                          : (hasWorked ? Colors.white : Colors.white54)),
                  fontWeight: isToday || hasWorked ? FontWeight.bold : FontWeight.normal,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              if (isOfficialVacation)
                Icon(
                  Icons.beach_access,
                  color: Colors.redAccent,
                  size: isMobile ? 10 : 14,
                ),
              if (isHalfDay)
                Icon(
                  Icons.hourglass_bottom,
                  color: Colors.orange,
                  size: isMobile ? 10 : 14,
                ),
              if (isDayOff && !isOfficialVacation && !isHalfDay)
                 Icon(
                  Icons.weekend,
                  color: Colors.yellowAccent,
                  size: isMobile ? 10 : 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 20, 
        horizontal: isMobile ? 12 : 16
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(AppTheme.secondaryColor, "Tam Mesai", isMobile),
                _legendItem(Colors.purple.shade400, "Fazla Mesai", isMobile),
                _legendItem(AppTheme.accentColor, "Eksik", isMobile),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper for legend items
  Widget _legendItem(Color color, String label, bool isMobile) {
    return Row(
      children: [
        Container(
          width: isMobile ? 8 : 12,
          height: isMobile ? 8 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70, 
            fontSize: isMobile ? 10 : 12
          ),
        ),
      ],
    );
  }

  void _showDayDetails(DateTime date, List<Session> sessions) {
    final isMobile = ResponsiveHelper.isMobile(context);
    // Capture the SessionProvider from CalendarPage's context BEFORE the bottom sheet
    // This ensures we use the scoped provider (for admin viewing other users)
    final sessionProvider = context.read<SessionProvider>();
    
    // Check if this is a day off or sick leave
    final isDayOff = sessions.any((s) => s.type == SessionType.dayOff);
    final isSickLeave = sessions.any((s) => s.type == SessionType.sickLeave);
    final isCalledByBoss = sessions.any((s) => s.type == SessionType.calledByBoss);

    // Handle sick leave display
    if (isSickLeave) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_hospital, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                "Hastalık İzni",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Bu gün hastalık iznindesiniz.\n(Bakiyeden düşülmez)",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                   try {
                     final sickLeaveSession = sessions.firstWhere((s) => s.type == SessionType.sickLeave);
                     // Use captured sessionProvider from CalendarPage's context
                     await sessionProvider.deleteSession(sickLeaveSession.startTime);
                     
                     // Force refresh from server
                     await sessionProvider.fetchSessionsForMonth(date.year, date.month);
                     
                     if (bottomSheetContext.mounted) {
                       // If admin is viewing another user, refresh that user's data
                       final userMgmt = context.read<UserManagementProvider>();
                       if (userMgmt.selectedUser != null) {
                         userMgmt.refreshSelectedUser();
                       } else {
                         userMgmt.refreshCurrentUser();
                       }
                       Navigator.pop(bottomSheetContext);
                     }
                   } catch (e) {
                     debugPrint("Error removing sick leave: $e");
                     if (bottomSheetContext.mounted) {
                       ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                         SnackBar(content: Text('İzin kaldırılamadı: $e'), backgroundColor: Colors.red),
                       );
                       Navigator.pop(bottomSheetContext);
                     }
                   }
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text("İzni Kaldır", style: GoogleFonts.outfit(color: Colors.red)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
      return;
    }

    if (isDayOff) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.yellowAccent.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.weekend, size: 48, color: Colors.yellowAccent),
              const SizedBox(height: 16),
              Text(
                "İzinli Gün",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Bu gün izinlisiniz.",
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                   try {
                     final dayOffSession = sessions.firstWhere((s) => s.type == SessionType.dayOff);
                     // Use captured sessionProvider from CalendarPage's context
                     await sessionProvider.deleteSession(dayOffSession.startTime);
                     
                     // Force refresh from server
                     await sessionProvider.fetchSessionsForMonth(date.year, date.month);
                     
                     if (bottomSheetContext.mounted) {
                       // If admin is viewing another user, refresh that user's data
                       final userMgmt = context.read<UserManagementProvider>();
                       if (userMgmt.selectedUser != null) {
                         userMgmt.refreshSelectedUser();
                       } else {
                         userMgmt.refreshCurrentUser();
                       }
                       Navigator.pop(bottomSheetContext);
                     }
                   } catch (e) {
                     debugPrint("Error removing day off: $e");
                     if (bottomSheetContext.mounted) {
                       ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                         SnackBar(content: Text('İzin kaldırılamadı: $e'), backgroundColor: Colors.red),
                       );
                       Navigator.pop(bottomSheetContext);
                     }
                   }
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text("İzni Kaldır", style: GoogleFonts.outfit(color: Colors.red)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
      return;
    }
    
    // Get role-specific expected minutes (try SessionProvider first, then AuthProvider)
    String? userRole = context.read<SessionProvider>().userRole;
    if (userRole == null || userRole.isEmpty) {
      // Fallback: get from AuthProvider
      userRole = context.read<AuthProvider>().role;
    }
    debugPrint('Calendar popup - userRole: $userRole');
    
    final roleExpectedWork = TimeCalculator.getExpectedDailyWork(userRole);
    debugPrint('Calendar popup - expected work: ${roleExpectedWork.inMinutes} minutes');
    
    final dayOverrideProvider = context.read<DayOverrideProvider>();
    final override = dayOverrideProvider.getOverrideForDay(date);
    
    // Determine expected minutes based on day override and role
    int standardMinutes;
    if (override?.type == DayOverrideType.vacation) {
      standardMinutes = 0;
    } else if (override?.type == DayOverrideType.halfDay) {
      standardMinutes = (roleExpectedWork.inMinutes / 2).round();
    } else {
      standardMinutes = roleExpectedWork.inMinutes;
    }
    
    // Calculate statistics
    Duration totalDuration = Duration.zero;
    for (var s in sessions) {
      totalDuration += s.duration;
    }
    
    final totalHours = totalDuration.inHours;
    final totalMinutes = totalDuration.inMinutes.remainder(60);
    final totalWorkedMinutes = totalDuration.inMinutes;
    final extraMinutes = totalWorkedMinutes - standardMinutes;
    
    final extraHoursPart = (extraMinutes.abs() / 60).floor();
    final extraMinutesPart = extraMinutes.abs() % 60;
    final extraTimeFormatted = "${extraHoursPart.toString().padLeft(2, '0')}:${extraMinutesPart.toString().padLeft(2, '0')}";
    
    final months = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
      "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(
            color: isDayOff 
                ? Colors.orange.withOpacity(0.5) 
                : (isCalledByBoss 
                    ? Colors.purple.withOpacity(0.5) 
                    : AppTheme.primaryColor.withOpacity(0.3)),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${date.day} ${months[date.month - 1]} ${date.year}",
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${sessions.length} Seans",
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDayOff 
                              ? [Colors.orange.shade600, Colors.orange.shade700]
                              : (isCalledByBoss
                                  ? [Colors.purple.shade600, Colors.purple.shade700]
                                  : (extraMinutes >= 0 
                                      ? [Colors.green.shade600, Colors.green.shade700]
                                      : [Colors.orange.shade600, Colors.orange.shade700])),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isDayOff 
                            ? "İzinli" 
                            : (isCalledByBoss 
                                ? "Patron Çağırdı"
                                : (extraMinutes >= 0 ? "Tam Mesai" : "Eksik")),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.access_time,
                        label: "Toplam Süre",
                        value: "$totalHours:${totalMinutes.toString().padLeft(2, '0')}",
                        color: AppTheme.primaryColor,
                        isMobile: isMobile,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: extraMinutes >= 0 ? Icons.trending_up : Icons.trending_down,
                        label: extraMinutes >= 0 ? "Fazla Mesai" : "Eksik Süre",
                        value: extraTimeFormatted,
                        color: extraMinutes >= 0 ? Colors.green : Colors.orange,
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Session List
                Text(
                  "Giriş/Çıkış Detayları",
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ...sessions.map((session) => _buildSessionItem(session, isMobile)).toList(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 10 : 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(Session session, bool isMobile) {
    final startTime = "${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}";
    final endTime = session.endTime != null 
        ? "${session.endTime!.hour.toString().padLeft(2, '0')}:${session.endTime!.minute.toString().padLeft(2, '0')}"
        : "Devam ediyor";

    final duration = session.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Entry/Exit times
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.login, color: Colors.green.shade400, size: isMobile ? 14 : 16),
                    const SizedBox(width: 8),
                    Text(
                      startTime,
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: session.endTime != null ? Colors.red.shade400 : Colors.grey,
                      size: isMobile ? 14 : 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      endTime,
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: session.endTime != null ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Duration & Edit & Delete
        Row(
          children: [
            // Edit button
            InkWell(
              onTap: () async {
                await _showEditSessionDialog(context, session);
                // Refresh data after edit
                if (mounted) {
                  Navigator.pop(context); // Close details sheet
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white70, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            // Delete button
            InkWell(
              onTap: () async {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardDark,
                    title: Text('Seansı Sil', style: GoogleFonts.outfit(color: Colors.white)),
                    content: Text(
                      'Bu seansı silmek istediğinizden emin misiniz?',
                      style: GoogleFonts.outfit(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('İptal', style: GoogleFonts.outfit(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Sil', style: GoogleFonts.outfit(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true && mounted) {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.cardDark,
                      content: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 20),
                          Text('Siliniyor...', style: GoogleFonts.outfit(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                  
                  try {
                    await context.read<SessionProvider>().sessionService.deleteSession(
                      context.read<SessionProvider>().userId,
                      session.startTime,
                    );
                    // Refresh data
                    await context.read<SessionProvider>().loadDailyData();
                    final provider = context.read<SessionProvider>();
                    await provider.fetchSessionsForMonth(
                      provider.focusedDate.year,
                      provider.focusedDate.month,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      Navigator.pop(context); // Close details sheet
                      
                      // Show success dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          title: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Text('Başarılı', style: GoogleFonts.outfit(color: Colors.white)),
                            ],
                          ),
                          content: Text('Seans silindi', style: GoogleFonts.outfit(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Tamam', style: GoogleFonts.outfit(color: AppTheme.primaryColor)),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      
                      // Show error dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          title: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Hata', style: GoogleFonts.outfit(color: Colors.white)),
                            ],
                          ),
                          content: Text('Seans silinemedi: $e', style: GoogleFonts.outfit(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Tamam', style: GoogleFonts.outfit(color: AppTheme.primaryColor)),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Colors.red, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$hours:${minutes.toString().padLeft(2, '0')}",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }



  Future<void> _showEditSessionDialog(BuildContext context, Session session) async {
    TimeOfDay startTime = TimeOfDay.fromDateTime(session.startTime);
    TimeOfDay? endTime = session.endTime != null ? TimeOfDay.fromDateTime(session.endTime!) : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: Text('Saati Düzenle', style: GoogleFonts.outfit(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Giriş Saati', style: GoogleFonts.outfit(color: Colors.white70)),
                  trailing: Text(startTime.format(context), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: startTime);
                    if (picked != null) setState(() => startTime = picked);
                  },
                ),
                ListTile(
                  title: Text('Çıkış Saati', style: GoogleFonts.outfit(color: Colors.white70)),
                  trailing: Text(endTime?.format(context) ?? '--:--', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: endTime ?? TimeOfDay.now());
                    if (picked != null) setState(() => endTime = picked);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('İptal', style: GoogleFonts.outfit(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () async {
                  // Use session date for the new times, not DateTime.now()
                  final sessionDate = session.startTime;
                  final newStart = DateTime(sessionDate.year, sessionDate.month, sessionDate.day, startTime.hour, startTime.minute);
                  DateTime? newEnd;
                  if (endTime != null) {
                    newEnd = DateTime(sessionDate.year, sessionDate.month, sessionDate.day, endTime!.hour, endTime!.minute);
                  }

                  if (newEnd != null && newEnd.isBefore(newStart)) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.cardDark,
                        title: Text('Hata', style: GoogleFonts.outfit(color: Colors.white)),
                        content: Text('Çıkış saati giriş saatinden önce olamaz!', style: GoogleFonts.outfit(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Tamam', style: GoogleFonts.outfit(color: AppTheme.primaryColor)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  final updatedSession = session.copyWith(
                    startTime: newStart,
                    endTime: newEnd,
                    isManualEntry: true,
                  );

                  try {
                    await context.read<SessionProvider>().updateSession(
                      updatedSession, 
                      oldStartTime: session.startTime,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          title: Text('Hata', style: GoogleFonts.outfit(color: Colors.white)),
                          content: Text(e.toString().replaceAll("Exception: ", ""), style: GoogleFonts.outfit(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Tamam', style: GoogleFonts.outfit(color: AppTheme.primaryColor)),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: Text('Kaydet', style: GoogleFonts.outfit(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show options for empty days
  void _showEmptyDayOptions(DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Date header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Add Session button
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _showManualSessionDialog(date);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seans Ekle',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Giriş ve çıkış saati belirle',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Mark as Day Off button
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _markAsDayOff(date);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.beach_access, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İzin Günü İşaretle',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bu günü izinli olarak kaydet',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Mark a day as day off - first show leave type selection
  void _markAsDayOff(DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'İzin Türü Seçin',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Normal Leave Option
            _buildLeaveTypeOption(
              icon: Icons.beach_access,
              iconColor: Colors.orange,
              title: 'Normal İzin',
              subtitle: 'İzin bakiyesinden düşülür',
              onTap: () {
                Navigator.pop(ctx);
                _showLeaveConfirmation(date, isSickLeave: false);
              },
            ),
            const SizedBox(height: 16),
            // Sick Leave Option
            _buildLeaveTypeOption(
              icon: Icons.local_hospital,
              iconColor: Colors.green,
              title: 'Hastalık İzni',
              subtitle: 'İzin bakiyesinden düşülmez',
              onTap: () {
                Navigator.pop(ctx);
                _showLeaveConfirmation(date, isSickLeave: true);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: iconColor.withOpacity(0.1),
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
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  // Show leave confirmation dialog with half/full day info
  void _showLeaveConfirmation(DateTime date, {required bool isSickLeave}) {
    final dayOverrideProvider = context.read<DayOverrideProvider>();
    final isHalfDayTag = dayOverrideProvider.isHalfDay(date);
    final deductionAmount = isHalfDayTag ? 0.5 : 1.0;
    
    final leaveTypeName = isSickLeave ? 'Hastalık İzni' : 'Normal İzin';
    final iconColor = isSickLeave ? Colors.green : Colors.orange;
    final icon = isSickLeave ? Icons.local_hospital : Icons.beach_access;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(leaveTypeName, style: GoogleFonts.outfit(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day}/${date.month}/${date.year} tarihini ${leaveTypeName.toLowerCase()} olarak işaretlemek istediğinizden emin misiniz?',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: iconColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                   Icon(isHalfDayTag ? Icons.hourglass_bottom : Icons.calendar_today, 
                        color: iconColor, size: 20),
                   const SizedBox(width: 12),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         isHalfDayTag ? "Yarım Gün" : "Tam Gün",
                         style: GoogleFonts.outfit(
                           color: iconColor,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       Text(
                         isSickLeave 
                           ? "İzin bakiyesinden düşülmeyecek."
                           : "İzin bakiyesinden $deductionAmount gün düşülecek.",
                         style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                       ),
                     ],
                   )
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('İptal', style: GoogleFonts.outfit(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => _processDayOff(date, isHalfDay: isHalfDayTag, isSickLeave: isSickLeave, dialogContext: dialogContext),
            child: Text('İşaretle', style: GoogleFonts.outfit(color: iconColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Helper method to process the day off creation
  Future<void> _processDayOff(DateTime date, {required bool isHalfDay, required bool isSickLeave, required BuildContext dialogContext}) async {
    final sessionProvider = context.read<SessionProvider>();
    Navigator.of(dialogContext).pop(); // Close confirmation dialog

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('Kaydediliyor...', style: GoogleFonts.outfit(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      // Tam Gün: 09:00 - 18:00 (9 hours) -> 1.0 deduction
      // Yarım Gün: 09:00 - 13:00 (4 hours) -> 0.5 deduction
      final startHour = 9;
      final endHour = isHalfDay ? 13 : 18;
      
      // Sick leave: no deduction from balance, use sickLeave type
      // Normal leave: deduct from balance, use dayOff type
      final sessionType = isSickLeave ? SessionType.sickLeave : SessionType.dayOff;

      await sessionProvider.createManualSession(
        date: date,
        startTime: TimeOfDay(hour: startHour, minute: 0),
        endTime: TimeOfDay(hour: endHour, minute: 0),
        sessionType: sessionType,
        leaveDeduction: isSickLeave ? 0.0 : (isHalfDay ? 0.5 : 1.0),
      );

      if (mounted) {
        await context.read<UserManagementProvider>().refreshCurrentUser();
        Navigator.of(context).pop(); // Close loading

        final leaveTypeName = isSickLeave ? 'Hastalık izni' : 'İzin günü';
        final deductionMessage = isSickLeave 
          ? '(Bakiyeden düşülmedi)' 
          : '(Düşülen: ${isHalfDay ? "0.5" : "1.0"} gün)';

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('Başarılı', style: GoogleFonts.outfit(color: Colors.white)),
              ],
            ),
            content: Text(
              '$leaveTypeName kaydedildi. $deductionMessage',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tamam', style: GoogleFonts.outfit(color: AppTheme.primaryColor)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: const Text('Hata', style: TextStyle(color: Colors.white)),
            content: Text('$e', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Manual session creation dialog
  Future<void> _showManualSessionDialog(DateTime date) async {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 30);
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 00);
    SessionType selectedType = SessionType.work;
    
    // Capture the page context before entering the dialog
    final pageContext = context;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: Text('Manuel Seans Ekle', style: GoogleFonts.outfit(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Start time
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: builderContext,
                      initialTime: startTime,
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.primaryColor,
                              surface: AppTheme.cardDark,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => startTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.login, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text('Giriş:', style: GoogleFonts.outfit(color: Colors.white70)),
                        const Spacer(),
                        Text(
                          startTime.format(context),
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // End time
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.primaryColor,
                              surface: AppTheme.cardDark,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => endTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text('Çıkış:', style: GoogleFonts.outfit(color: Colors.white70)),
                        const Spacer(),
                        Text(
                          endTime.format(context),
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Session Type Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SessionType>(
                      value: selectedType,
                      dropdownColor: AppTheme.cardDark,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      style: GoogleFonts.outfit(color: Colors.white),
                      items: [
                        const DropdownMenuItem(
                          value: SessionType.work,
                          child: Text("Normal Mesai"),
                        ),
                         const DropdownMenuItem(
                          value: SessionType.calledByBoss,
                          child: Text("Patron Çağırdı"),
                        ),
                         const DropdownMenuItem(
                          value: SessionType.overtime,
                          child: Text("Ek Mesai Yapma İzni"),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                  ),
                ),
                if (selectedType == SessionType.work)
                   Padding(
                     padding: const EdgeInsets.only(top: 8),
                     child: Text(
                       "Not: Normal mesai 18:00'de biter.",
                       style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                     ),
                   ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('İptal', style: GoogleFonts.outfit(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () async {
                  // Capture provider before closing dialog
                  final sessionProvider = pageContext.read<SessionProvider>();
                  
                  Navigator.of(dialogContext).pop(); // Close main dialog
                  
                  // Show loading - use page context
                  showDialog(
                    context: pageContext,
                    barrierDismissible: false,
                    builder: (loadingContext) => AlertDialog(
                      backgroundColor: AppTheme.cardDark,
                      content: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 20),
                          Text('Oluşturuluyor...', style: GoogleFonts.outfit(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                  
                  try {
                    // Logic for saving:
                    // 1. Determine SessionType and Final End Time
                    TimeOfDay finalEndTime = endTime;
                    SessionType finalSessionType = SessionType.work;

                    if (selectedType == SessionType.work) {
                       // Cap at 18:00
                       if (endTime.hour > 18 || (endTime.hour == 18 && endTime.minute > 0)) {
                         finalEndTime = const TimeOfDay(hour: 18, minute: 0);
                       }
                       finalSessionType = SessionType.work;
                    } else if (selectedType == SessionType.calledByBoss) {
                       finalSessionType = SessionType.calledByBoss;
                    } else if (selectedType == SessionType.overtime) {
                       // Map explicit overtime permission to Work type, but without capping
                       finalSessionType = SessionType.work;
                       // No cap needed
                    }

                    await sessionProvider.createManualSession(
                      date: date,
                      startTime: startTime,
                      endTime: finalEndTime,
                      sessionType: finalSessionType,
                    );
                    
                    if (mounted) {
                      Navigator.of(pageContext).pop(); // Close loading
                      
                      // Show success
                      showDialog(
                        context: pageContext,
                        builder: (successContext) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          title: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Text('Başarılı', style: GoogleFonts.outfit(color: Colors.white)),
                            ],
                          ),
                          content: Text('Seans oluşturuldu', style: GoogleFonts.outfit(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(successContext).pop(),
                              child: Text('Tamam', style: GoogleFonts.outfit(color: AppTheme.primaryColor)),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(pageContext).pop(); // Close loading
                      
                      // Show error
                      showDialog(
                        context: pageContext,
                        builder: (errorContext) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          title: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Hata', style: GoogleFonts.outfit(color: Colors.white)),
                            ],
                          ),
                          content: Text('$e', style: GoogleFonts.outfit(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(errorContext).pop(),
                              child: Text('Tamam', style: GoogleFonts.outfit(color: AppTheme.primaryColor)),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: Text('Oluştur', style: GoogleFonts.outfit(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show export options for individual report
  void _showExportOptions(DateTime focusedDate) {
    final sessionProvider = context.read<SessionProvider>();
    final userProvider = context.read<UserManagementProvider>();
    
    // Get user info
    final userName = userProvider.currentUserHelper?.name ?? 
                     context.read<AuthProvider>().userId ?? '';
    final userSurname = userProvider.currentUserHelper?.surname ?? '';
    
    final months = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
      "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Rapor Dışa Aktar',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${months[focusedDate.month - 1]} ${focusedDate.year}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            
            // PDF Export
            _buildExportOption(
              icon: Icons.picture_as_pdf,
              iconColor: Colors.red,
              title: 'PDF olarak indir',
              subtitle: 'Yazdırılabilir rapor',
              onTap: () {
                Navigator.pop(ctx);
                _exportIndividualPdf(focusedDate, userName, userSurname);
              },
            ),
            const SizedBox(height: 12),
            
            // Excel Export
            _buildExportOption(
              icon: Icons.table_chart,
              iconColor: Colors.green,
              title: 'Excel olarak indir',
              subtitle: 'Detaylı tablo formatı',
              onTap: () {
                Navigator.pop(ctx);
                _exportIndividualExcel(focusedDate, userName, userSurname);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: iconColor.withOpacity(0.1),
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
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportIndividualPdf(DateTime focusedDate, String userName, String userSurname) async {
    final sessionProvider = context.read<SessionProvider>();
    final exportService = ExportService();
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('PDF oluşturuluyor...', style: GoogleFonts.outfit(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      // Get sessions for the month
      final sessions = sessionProvider.getSessionsFromCache(focusedDate.year, focusedDate.month);
      
      // Generate PDF
      final pdfBytes = await exportService.generateIndividualReportPdf(
        sessions: sessions,
        userName: userName,
        userSurname: userSurname,
        year: focusedDate.year,
        month: focusedDate.month,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        
        final months = [
          "Ocak", "Subat", "Mart", "Nisan", "Mayis", "Haziran",
          "Temmuz", "Agustos", "Eylul", "Ekim", "Kasim", "Aralik"
        ];
        final fileName = 'Mesai_Raporu_${months[focusedDate.month - 1]}_${focusedDate.year}.pdf';
        
        await exportService.sharePdf(pdfBytes, fileName);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportIndividualExcel(DateTime focusedDate, String userName, String userSurname) async {
    final sessionProvider = context.read<SessionProvider>();
    final exportService = ExportService();
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('Excel oluşturuluyor...', style: GoogleFonts.outfit(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      // Get sessions for the month
      final sessions = sessionProvider.getSessionsFromCache(focusedDate.year, focusedDate.month);
      
      // Generate Excel
      final excelBytes = await exportService.generateIndividualReportExcel(
        sessions: sessions,
        userName: userName,
        userSurname: userSurname,
        year: focusedDate.year,
        month: focusedDate.month,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        
        final months = [
          "Ocak", "Subat", "Mart", "Nisan", "Mayis", "Haziran",
          "Temmuz", "Agustos", "Eylul", "Ekim", "Kasim", "Aralik"
        ];
        final fileName = 'Mesai_Raporu_${months[focusedDate.month - 1]}_${focusedDate.year}.xlsx';
        
        await exportService.shareExcel(excelBytes, fileName);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel oluşturulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
