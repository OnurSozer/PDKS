
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../shared/responsive_helper.dart';
import '../../state/user/user_provider.dart';
import '../../state/session/session_provider.dart';
import '../../state/user_management/user_management_provider.dart';
import '../../state/auth/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    // Refresh user data upon entering profile page to ensure leave balance is up-to-date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.userId != null) {
        context.read<UserManagementProvider>().refreshCurrentUser(userId: auth.userId);
      }
    });
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
    setState(() {
      _notificationsEnabled = value;
    });
    
    /*if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Bildirimler açıldı' : 'Bildirimler kapatıldı'),
          backgroundColor: value ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }*/
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 12),
            Text('Yardım & Destek', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sorularınız veya sorunlarınız için bizimle iletişime geçebilirsiniz.',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'onur@solar.com.tr',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tamam', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 28),
            const SizedBox(width: 12),
            Text('Çıkış Yap', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: Text('Çıkış Yap', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final userManagement = context.watch<UserManagementProvider>();
    final sessionProvider = context.watch<SessionProvider>();
    final isMobile = ResponsiveHelper.isMobile(context);
    
    // Get leave balance from UserManagementProvider
    final leaveBalance = userManagement.currentUserHelper?.leaveBalance ?? 0.0;
    final leaveBalanceText = "${leaveBalance.toStringAsFixed(2)} Gün";
    
    // Calculate this month's worked hours from sessions
    final now = DateTime.now();
    final monthSessions = sessionProvider.getSessionsFromCache(now.year, now.month);
    int totalMinutes = 0;
    for (final session in monthSessions) {
      if (session.endTime != null) {
        totalMinutes += session.endTime!.difference(session.startTime).inMinutes;
      }
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final monthHoursText = "${hours}s ${minutes}dk";
    
    // Get user initials for avatar
    final initials = userProvider.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: isMobile ? 10 : 20),
              // Profile Header with Initials Avatar
              Container(
                width: isMobile ? 100 : 120,
                height: isMobile ? 100 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 32 : 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userProvider.fullName,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Kıdemli Mühendis',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 12 : 14,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1,
                ),
              ),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              // Stats Grid
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: Row(
                  children: [
                    Expanded(child: _buildStatBox("Kalan İzin", leaveBalanceText, Icons.beach_access, isMobile: isMobile, isNegative: leaveBalance < 0)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatBox("Bu Ay", monthHoursText, Icons.timer, isMobile: isMobile)),
                  ],
                ),
              ),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              // Menu Items
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ayarlar",
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Bildirimler with Toggle
                    _buildMenuItemWithToggle(
                      "Bildirimler",
                      Icons.notifications_outlined,
                      isMobile,
                      _notificationsEnabled,
                      _toggleNotifications,
                    ),
                    
                    // Yardım & Destek
                    InkWell(
                      onTap: _showContactDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMenuItem("Yardım & Destek", Icons.help_outline, isMobile),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Çıkış Yap
                    InkWell(
                      onTap: _showLogoutConfirmation,
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMenuItem("Çıkış Yap", Icons.logout, isMobile, isDestructive: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, {bool isNegative = false, required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isNegative ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: isNegative ? Colors.red : Colors.white70, size: isMobile ? 24 : 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 10 : 12,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, bool isMobile, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: isDestructive 
                  ? AppTheme.accentColor.withOpacity(0.1) 
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon, 
              color: isDestructive ? AppTheme.accentColor : Colors.white70,
              size: isMobile ? 18 : 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: isDestructive ? AppTheme.accentColor : Colors.white,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            color: Colors.white24,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemWithToggle(
    String title,
    IconData icon,
    bool isMobile,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon, 
              color: value ? AppTheme.primaryColor : Colors.white54,
              size: isMobile ? 18 : 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
