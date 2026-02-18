import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../state/session/session_provider.dart';
import '../../state/user/user_provider.dart';
import '../../state/auth/auth_provider.dart';
import '../../core/models/models.dart';
import '../theme/app_theme.dart';
import '../shared/widgets/meal_notification_button.dart';
import '../shared/responsive_helper.dart';
import 'dart:async';
import 'dart:math' as math;

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    // Initialize immediately to avoid 00:00:00 flash
    final session = context.read<SessionProvider>().activeSession;
    if (session != null) {
      _elapsed = DateTime.now().difference(session.startTime);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final sessionProvider = context.read<SessionProvider>();
      final session = sessionProvider.activeSession;
      
      bool shouldUpdate = false;

      if (session != null) {
        _elapsed = DateTime.now().difference(session.startTime);
        shouldUpdate = true;
      } else {
        if (_elapsed != Duration.zero) {
          _elapsed = Duration.zero;
          shouldUpdate = true;
        }
        
        // Check for cooldown update
        if (sessionProvider.cooldownStartTime != null) {
          final now = DateTime.now();
          final secondsSinceEnd = now.difference(sessionProvider.cooldownStartTime!).inSeconds;
          // Allow update up to 61 seconds to ensure we clear the cooldown state visually
          if (secondsSinceEnd >= 0 && secondsSinceEnd <= 61) {
            shouldUpdate = true;
          }
        }
      }

      if (shouldUpdate) {
        setState(() {});
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }


  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final userProvider = context.watch<UserProvider>();
    final activeSession = sessionProvider.activeSession;
    final isWorking = activeSession != null;
    final isMobile = ResponsiveHelper.isMobile(context);

    // Calculate cooldown based on when user clicked çıkış, not session end time
    Duration? cooldownRemaining;
    if (!isWorking && sessionProvider.cooldownStartTime != null) {
      final now = DateTime.now();
      final cooldownStart = sessionProvider.cooldownStartTime!;
      final secondsSinceEnd = now.difference(cooldownStart).inSeconds;
      
      if (secondsSinceEnd >= 0 && secondsSinceEnd < 60) {
        cooldownRemaining = Duration(seconds: 60 - secondsSinceEnd);
      }
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
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.pagePadding(context)),
          child: Column(
            children: [
              // Top Section: Centered Timer & Actions
              Expanded(
                child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Hoş Geldin,",
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          userProvider.fullName,
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getFormattedDate(),
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.white54,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: isMobile ? 24 : 32),
                        
                        // Main Timer Card
                        _buildGlassCard(
                          isMobile: isMobile,
                          child: Column(
                            children: [
                              if(isWorking)
                              Text(
                                'MESAİ SÜRÜYOR',
                                style: GoogleFonts.outfit(
                                  fontSize: isMobile ? 12 : 14,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                              SizedBox(height: isMobile ? 16 : 24),
                              
                              // Timer Display
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 16 : 32, 
                                  vertical: isMobile ? 16 : 20
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Show timer only if working
                                    if (isWorking) ...[
                                      Text(
                                        "Çalışma Süresi",
                                        style: GoogleFonts.outfit(
                                          fontSize: isMobile ? 12 : 14,
                                          color: Colors.white70,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      SizedBox(height: isMobile ? 8 : 12),
                                      Text(
                                        _formatDuration(_elapsed),
                                        style: GoogleFonts.outfit(
                                          fontSize: isMobile ? 40 : 56,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ] else if (sessionProvider.todaySessions.isEmpty) ...[
                                        // Clean empty state
                                        SizedBox(height: isMobile ? 20 : 30),
                                    ],
                                    // Show checkmark icon when shift is completed
                                    if (!isWorking && sessionProvider.todaySessions.isNotEmpty) ...[
                                      Container(
                                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green.shade400,
                                              Colors.green.shade600,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(0.4),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.check_circle_outline,
                                          size: isMobile ? 48 : 64,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: isMobile ? 12 : 16),
                                      Text(
                                        "Mesai Tamamlandı",
                                        style: GoogleFonts.outfit(
                                          fontSize: isMobile ? 18 : 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Bugünkü çalışmanız başarıyla kaydedildi",
                                        style: GoogleFonts.outfit(
                                          fontSize: isMobile ? 12 : 13,
                                          color: Colors.white60,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: isMobile ? 24 : 32),
                              
                              // Action Button
                                // Main Action Button with Pulse if not working
                                AnimatedBuilder(
                                  animation: _pulseController, 
                                  builder: (context, child) {
                                    final scale = !isWorking && cooldownRemaining == null 
                                        ? 1.0 + (_pulseController.value * 0.03) 
                                        : 1.0;
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: GestureDetector(
                                    onLongPress: sessionProvider.isLoading
                                      ? null
                                      : () {
                                          if (isWorking) {
                                            _showCheckOutDialog(sessionProvider);
                                          } else {
                                            // Recalculate cooldown to avoid stale closure state
                                            Duration? currentCooldown;
                                            if (sessionProvider.cooldownStartTime != null) {
                                               final seconds = DateTime.now().difference(sessionProvider.cooldownStartTime!).inSeconds;
                                               if (seconds < 60) {
                                                 currentCooldown = Duration(seconds: 60 - seconds);
                                               }
                                            }
                                            
                                            if (currentCooldown != null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Lütfen bekleme süresinin dolmasını bekleyin.')),
                                              );
                                              return;
                                            }
                                            _showCheckInDialog(sessionProvider);
                                          }
                                        },
                                    onTap: sessionProvider.isLoading
                                        ? null
                                        : () async {
                                            if (isWorking) {
                                              // Quick Checkout (Default: Cap at 18:00)
                                              try {
                                                await sessionProvider.endSession(capAtWorkEnd: true);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Çıkış yapıldı. (18:00 sonrası ise mesai sayılmadı)')),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Hata: $e')),
                                                  );
                                                }
                                              }
                                            } else {
                                              // Quick Check-in
                                              // Recalculate cooldown to avoid stale closure state
                                              Duration? currentCooldown;
                                              if (sessionProvider.cooldownStartTime != null) {
                                                 final seconds = DateTime.now().difference(sessionProvider.cooldownStartTime!).inSeconds;
                                                 if (seconds < 60) {
                                                   currentCooldown = Duration(seconds: 60 - seconds);
                                                 }
                                              }

                                              if (currentCooldown != null) {
                                                _showCooldownDialog(currentCooldown);
                                                return;
                                              }
                                              try {
                                                await sessionProvider.startSession();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Giriş yapıldı.')),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Hata: $e')),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      height: isMobile ? 72 : 80, // Bigger button
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: isWorking 
                                            ? const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFEE5253)])
                                            : const LinearGradient(colors: [Color(0xFF00D2D3), Color(0xFF00B894)]),
                                        borderRadius: BorderRadius.circular(40), // More rounded
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isWorking 
                                                ? const Color(0xFFFF6B6B) 
                                                : const Color(0xFF00D2D3)).withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: sessionProvider.isLoading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    isWorking ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                                                    color: Colors.white,
                                                    size: isMobile ? 32 : 36, // Bigger icon
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Text(
                                                    isWorking 
                                                        ? 'ÇIKIŞ YAP' 
                                                        : 'GİRİŞ YAP',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: isMobile ? 22 : 26, // Bigger text
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              
                                const SizedBox(height: 12),
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.touch_app_outlined, color: Colors.white.withOpacity(0.8), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Detaylı işlem için basılı tutun',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                            ],
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),              
              // Bottom Section: Fixed Summary
              SizedBox(height: isMobile ? 16 : 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Bugünün Özeti",
                        style: GoogleFonts.outfit(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Toplam",
                          sessionProvider.dailySummary != null 
                              ? _formatDuration(sessionProvider.dailySummary!.totalWorkedHours)
                              : "00:00",
                          Icons.access_time_filled,
                          Colors.blueAccent,
                          isMobile,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: _buildStatCard(
                          "Fazla Mesai",
                          sessionProvider.dailySummary != null 
                              ? _formatDuration(sessionProvider.dailySummary!.overtimeHours)
                              : "00:00",
                          Icons.bolt,
                          Colors.orangeAccent,
                          isMobile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Margin from bottom nav bar
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required bool isMobile}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 16 : 20),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 10 : 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }






  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
      "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    final days = [
      "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"
    ];
    // Weekday is 1-7 (Mon-Sun)
    return "${now.day} ${months[now.month - 1]} ${now.year}, ${days[now.weekday - 1]}";
  }

  void _showCooldownDialog(Duration cooldownRemaining) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        int remainingSeconds = cooldownRemaining.inSeconds;
        Timer? countdownTimer;
        
        return StatefulBuilder(
          builder: (context, setState) {
            // Start countdown timer
            if (countdownTimer == null) {
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (remainingSeconds > 0) {
                  setState(() {
                    remainingSeconds--;
                  });
                } else {
                  timer.cancel();
                  Navigator.pop(dialogContext);
                }
              });
            }
            
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              title: Text('Bekleyiniz', style: GoogleFonts.outfit(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Lütfen Bekleyiniz',
                    style: GoogleFonts.outfit(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$remainingSeconds saniye',
                    style: GoogleFonts.outfit(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: AppTheme.primaryColor
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    countdownTimer?.cancel();
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Tamam', style: GoogleFonts.outfit(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCheckInDialog(SessionProvider sessionProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Giriş Yap', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login_rounded, color: AppTheme.primaryColor, size: 48),
            const SizedBox(height: 16),
            Text(
              'Mesaiye başlamak istiyor musunuz?',
              style: GoogleFonts.outfit(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Show time picker for custom time
              final customTime = await _pickCustomTime(isCheckIn: true);
              if (customTime != null) {
                sessionProvider.startSession(customStartTime: customTime);
              }
            },
            child: Text('Farklı Saat', style: GoogleFonts.outfit(color: Colors.orange)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () {
              Navigator.pop(ctx);
              sessionProvider.startSession();
            },
            child: Text('Şimdi Başla', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCheckOutDialog(SessionProvider sessionProvider) {
    bool stayedForOvertime = false;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Çıkış Yap', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Mesaiyi bitirmek istiyor musunuz?',
                style: GoogleFonts.outfit(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Overtime Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: stayedForOvertime ? Colors.orange : Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: stayedForOvertime ? Colors.orange : Colors.white54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ek mesaiye kaldım',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'İşaretlenmezse 18:00 sonrası sayılmaz',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: stayedForOvertime,
                      onChanged: (val) => setState(() => stayedForOvertime = val),
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal', style: GoogleFonts.outfit(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                // Show time picker for custom time
                final customTime = await _pickCustomTime(isCheckIn: false);
                if (customTime != null) {
                  sessionProvider.endSession(
                    customEndTime: customTime,
                    capAtWorkEnd: !stayedForOvertime,
                  );
                }
              },
              child: Text('Farklı Saat', style: GoogleFonts.outfit(color: Colors.orange)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(ctx);
                sessionProvider.endSession(capAtWorkEnd: !stayedForOvertime);
              },
              child: Text('Çıkış Yap', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickCustomTime({required bool isCheckIn}) async {
    final now = DateTime.now();
    
    // Show time picker
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: isCheckIn ? 'Giriş saatini seçin' : 'Çıkış saatini seçin',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.cardDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return null;

    // Create DateTime from picked time
    final pickedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validation: Cannot be in the future
    if (pickedDateTime.isAfter(now)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCheckIn ? 'Giriş saati gelecekte olamaz!' : 'Çıkış saati gelecekte olamaz!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    return pickedDateTime;
  }
}
