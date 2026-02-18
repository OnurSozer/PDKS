import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/session/session_provider.dart';
import '../../state/day_override/day_override_provider.dart';
import '../../core/models/models.dart';
import '../../core/utils/time_calculator.dart';
import '../theme/app_theme.dart';
import '../shared/responsive_helper.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}


class _StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    context.watch<DayOverrideProvider>(); // Watch for override updates so stats recalculate
    final focusedDate = provider.focusedDate;
    final sessionsList = provider.getSessionsFromCache(focusedDate.year, focusedDate.month);
    final isMobile = ResponsiveHelper.isMobile(context);
    
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
                    "İstatistikler",
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  _buildDateSelectors(focusedDate, isMobile),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.pagePadding(context)),
                child: Column(
                  children: [
                    _buildPerformanceCard(sessionsMap, focusedDate, isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildDetailedStats(sessionsMap, isMobile),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectors(DateTime focusedDate, bool isMobile) {
    return Row(
      children: [
        _buildYearSelector(focusedDate, isMobile),
        const SizedBox(width: 8),
        _buildMonthSelector(focusedDate, isMobile),
      ],
    );
  }

  Widget _buildYearSelector(DateTime focusedDate, bool isMobile) {
    return GestureDetector(
      onTap: () => _showYearPicker(focusedDate),
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
    );
  }

  void _showYearPicker(DateTime focusedDate) {
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
                final isSelected = year == focusedDate.year;
                return ListTile(
                  title: Text(
                    "$year",
                    style: GoogleFonts.outfit(
                      color: isSelected ? AppTheme.primaryColor : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    if (year != focusedDate.year) {
                      final newDate = DateTime(year, 1);
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

  Widget _buildMonthSelector(DateTime focusedDate, bool isMobile) {
    final months = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
      "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: focusedDate.month,
          dropdownColor: AppTheme.cardDark,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
          style: GoogleFonts.outfit(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
          onChanged: (int? newValue) {
            if (newValue != null) {
              final newDate = DateTime(focusedDate.year, newValue);
              context.read<SessionProvider>().setFocusedDate(newDate);
            }
          },
          items: List.generate(12, (index) {
            return DropdownMenuItem<int>(
              value: index + 1,
              child: Text(months[index]),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(Map<int, List<Session>> sessionsMap, DateTime focusedDate, bool isMobile) {
    // Get user role from provider for role-specific calculations
    final userRole = context.read<SessionProvider>().userRole;
    final expectedDailyWork = TimeCalculator.getExpectedDailyWork(userRole);
    final standardDailyMinutes = expectedDailyWork.inMinutes.toDouble();
    final halfDayMinutes = standardDailyMinutes / 2;
    final daysInMonth = DateUtils.getDaysInMonth(focusedDate.year, focusedDate.month);
    
    // Check if role has overtime multiplier (engineer10hrs doesn't)
    final isEngineer10hrs = userRole == 'engineer10hrs';
    final overtimeMultiplier = isEngineer10hrs ? 1.0 : 1.5;
    
    // Get current date for "up to today" calculation
    final now = DateTime.now();
    
    // Get day override provider
    final dayOverrideProvider = context.read<DayOverrideProvider>();
    
    // === EXPECTED WORK ===
    // Count only workdays (Sun-Thu) UP TO TODAY, exclude weekends (Fri-Sat)
    // Future days are NOT included in expected
    double expectedMinutes = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedDate.year, focusedDate.month, day);
      
      // Skip future days - only count up to today
      final isFuture = date.year > now.year || 
                      (date.year == now.year && date.month > now.month) || 
                      (date.year == now.year && date.month == now.month && date.day > now.day);
      if (isFuture) continue;
      
      // Weekend: Friday(5) and Saturday(6)
      final isWeekend = date.weekday == 5 || date.weekday == 6;
      
      if (isWeekend) {
        // Weekend - no expected work
        continue;
      }
      
      // Check for day override
      final override = dayOverrideProvider.getOverrideForDay(date);
      
      if (override?.type == DayOverrideType.vacation) {
        // Official company vacation - no expected work
        continue;
      } else if (override?.type == DayOverrideType.halfDay) {
        // Half day
        expectedMinutes += halfDayMinutes;
      } else {
        // Normal workday
        expectedMinutes += standardDailyMinutes;
      }
    }
    
    // === WORKED MINUTES ===
    // Actual session minutes + Leave credits (on ANY day including weekends)
    double workedMinutes = 0;
    for (var daySessions in sessionsMap.values) {
      for (var s in daySessions) {
        if (s.type == SessionType.dayOff || s.type == SessionType.sickLeave) {
          // Leave: credit full daily expected work
          workedMinutes += standardDailyMinutes;
        } else {
          // Normal work: use actual duration
          workedMinutes += s.duration.inMinutes;
        }
      }
    }
    
    // === PERCENTAGE CALCULATION ===
    // difference = worked - expected
    final difference = workedMinutes - expectedMinutes;
    
    double extraPayPercentage;
    if (difference > 0) {
      // Extra: apply multiplier (1.5x or 1.0x), divide by daily, divide by 21.66
      final adjustedExtra = difference * overtimeMultiplier;
      final extraDays = adjustedExtra / standardDailyMinutes;
      extraPayPercentage = (extraDays / 21.66) * 100;
    } else {
      // Missing: negative percentage (difference is already negative)
      final missingDays = difference / standardDailyMinutes;
      extraPayPercentage = (missingDays / 21.66) * 100;
    }
    
    // Work completion percentage: worked / expected
    final workPercentage = expectedMinutes > 0 ? (workedMinutes / expectedMinutes) * 100 : 0.0;
    
    // For display, we use workedMinutes as totalRawMinutes
    final totalRawMinutes = workedMinutes;
    final monthWorkMinutes = expectedMinutes;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: workPercentage >= 100 
              ? [Colors.green.shade900.withOpacity(0.5), Colors.green.shade800.withOpacity(0.3)]
              : [Colors.orange.shade900.withOpacity(0.5), Colors.orange.shade800.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: workPercentage >= 100 ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (workPercentage >= 100 ? Colors.green : Colors.orange).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Aylık Çalışma",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (workPercentage >= 100)
                    Text(
                      "Eksik Yok",
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final missingMinutes = monthWorkMinutes - totalRawMinutes;
                        final hours = (missingMinutes / 60).floor();
                        final minutes = (missingMinutes % 60).toInt();
                        return Text(
                          hours > 0 ? "${hours}s ${minutes}dk" : "${minutes}dk",
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 32 : 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }
                    ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  workPercentage >= 100 ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: isMobile ? 24 : 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Durum:",
                      style: GoogleFonts.outfit(color: Colors.white70),
                    ),
                    Text(
                      workPercentage >= 100 
                          ? "Hedef Tamamlandı ✓"
                          : "${(100 - workPercentage).toStringAsFixed(1)}% Eksik",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: workPercentage >= 100 ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (extraPayPercentage > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Fazla Mesai Primi:",
                        style: GoogleFonts.outfit(color: Colors.white70),
                      ),
                      Text(
                        "+${extraPayPercentage.toStringAsFixed(2)}%",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(Map<int, List<Session>> sessionsMap, bool isMobile) {
    // Calculate stats
    double totalActualMinutes = 0;
    int totalWorkDays = 0;
    int totalDayOffs = 0;
    double maxDailyMinutes = 0;
    double minDailyMinutes = double.infinity;
    
    sessionsMap.forEach((day, sessions) {
      if (sessions.isNotEmpty) {
        // Check if day off or sick leave
        final isDayOff = sessions.any((s) => s.type == SessionType.dayOff);
        final isSickLeave = sessions.any((s) => s.type == SessionType.sickLeave);
        final isAnyLeave = isDayOff || isSickLeave;
        
        if (isAnyLeave) {
          totalDayOffs++;
        } else {
          totalWorkDays++;
          double dailyTotal = 0;
          for (var s in sessions) {
            dailyTotal += s.duration.inMinutes;
          }
          totalActualMinutes += dailyTotal;
          
          if (dailyTotal > maxDailyMinutes) maxDailyMinutes = dailyTotal;
          if (dailyTotal < minDailyMinutes) minDailyMinutes = dailyTotal;
        }
      }
    });

    if (minDailyMinutes == double.infinity) minDailyMinutes = 0;

    final totalHours = (totalActualMinutes / 60).floor();
    final totalMinutes = (totalActualMinutes % 60).toInt();
    
    final averageMinutes = totalWorkDays > 0 ? totalActualMinutes / totalWorkDays : 0;
    final avgHours = (averageMinutes / 60).floor();
    final avgMins = (averageMinutes % 60).toInt();

    final maxHours = (maxDailyMinutes / 60).floor();
    final maxMins = (maxDailyMinutes % 60).toInt();
    
    final minHours = (minDailyMinutes / 60).floor();
    final minMins = (minDailyMinutes % 60).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Detaylar",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                "Çalışılan Gün",
                "$totalWorkDays Gün",
                Icons.calendar_today,
                Colors.blue,
                isMobile
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailCard(
                "Toplam Süre",
                "${totalHours}s ${totalMinutes}dk",
                Icons.access_time,
                Colors.purple,
                isMobile
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                "Ortalama Günlük",
                "${avgHours}s ${avgMins}dk",
                Icons.timelapse,
                Colors.orange,
                isMobile
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailCard(
                "Kullanılan İzin",
                "$totalDayOffs Gün",
                Icons.beach_access,
                Colors.teal,
                isMobile
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                "En Uzun Gün",
                "${maxHours}s ${maxMins}dk",
                Icons.arrow_upward,
                Colors.pink,
                isMobile
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailCard(
                "En Kısa Mesai",
                "${minHours}s ${minMins}dk",
                Icons.arrow_downward,
                Colors.indigo,
                isMobile
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 16 : 20),
          ),
          SizedBox(height: isMobile ? 8 : 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 10 : 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
