import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../records/providers/records_provider.dart';
import '../../leave/providers/leave_provider.dart';
import '../../../router.dart';  // localeProvider + firstDayOfWeekProvider

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context);
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.changePassword),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.newPassword),
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.confirmPassword),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final success = await ref
                  .read(authProvider.notifier)
                  .changePassword(newPasswordController.text);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.passwordChanged)),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFirstDayOfWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(AppConstants.prefFirstDayOfWeek) ?? 1;
    final newValue = current == 1 ? 7 : 1; // Toggle between Monday(1) and Sunday(7)
    await prefs.setInt(AppConstants.prefFirstDayOfWeek, newValue);
    ref.read(firstDayOfWeekProvider.notifier).state = newValue;
  }

  Future<void> _toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLocale = prefs.getString(AppConstants.prefLocale) ?? 'tr';
    final newLocale = currentLocale == 'tr' ? 'en' : 'tr';
    await prefs.setString(AppConstants.prefLocale, newLocale);
    ref.read(localeProvider.notifier).state = Locale(newLocale);
  }

  void _confirmLogout() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.clockOutColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final recordsState = ref.watch(recordsProvider);
    final leaveState = ref.watch(leaveProvider);
    final l10n = AppLocalizations.of(context);
    final profile = authState.profile;

    // Calculate remaining leave (only deductible types, exclude sick leave)
    double remainingLeave = 0;
    for (final balance in leaveState.balances) {
      final leaveType = balance['leave_type'] as Map<String, dynamic>?;
      final isDeductible = leaveType?['is_deductible'] as bool? ?? true;
      if (!isDeductible) continue;
      final total = (balance['total_days'] as num?)?.toDouble() ?? 0;
      final used = (balance['used_days'] as num?)?.toDouble() ?? 0;
      remainingLeave += (total - used);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                l10n.profile,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Avatar with purple ring
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.15),
                      child: Text(
                        profile != null && profile.firstName.isNotEmpty && profile.lastName.isNotEmpty
                            ? '${profile.firstName[0]}${profile.lastName[0]}'
                            : '',
                        style: const TextStyle(
                          fontSize: 36,
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                profile?.fullName ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                profile?.email ?? '',
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            // Role badge
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  profile?.role ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stat cards row
            Row(
              children: [
                Expanded(
                  child: _ProfileStatCard(
                    icon: Icons.beach_access_outlined,
                    iconColor: AppConstants.leaveColor,
                    value: remainingLeave.toStringAsFixed(0),
                    unit: l10n.dayUnit,
                    label: l10n.remainingLeaveShort,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileStatCard(
                    icon: Icons.timer_outlined,
                    iconColor: AppConstants.clockInColor,
                    value: AppDateUtils.formatDurationLocalized(
                      recordsState.totalWorkedMinutes,
                      l10n.hoursAbbrev,
                      l10n.minutesAbbrev,
                    ),
                    unit: '',
                    label: l10n.thisMonth,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildViewProfile(l10n, profile),

            const SizedBox(height: 16),

            // Actions
            Container(
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: AppConstants.borderColor, width: 0.5),
              ),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.schedule_outlined,
                    label: l10n.mySchedule,
                    onTap: () => context.push('/profile/schedule'),
                  ),
                  Divider(height: 1, color: AppConstants.borderColor, indent: 56),
                  _ActionTile(
                    icon: Icons.beach_access_outlined,
                    label: l10n.myLeave,
                    onTap: () => context.push('/profile/leave'),
                  ),
                  Divider(height: 1, color: AppConstants.borderColor, indent: 56),
                  _ActionTile(
                    icon: Icons.shield_outlined,
                    label: l10n.changePassword,
                    onTap: _showChangePasswordDialog,
                  ),
                  Divider(height: 1, color: AppConstants.borderColor, indent: 56),
                  _ActionTile(
                    icon: Icons.language,
                    label: l10n.language,
                    subtitle: Localizations.localeOf(context).languageCode == 'tr'
                        ? l10n.turkish
                        : l10n.english,
                    onTap: _toggleLanguage,
                  ),
                  Divider(height: 1, color: AppConstants.borderColor, indent: 56),
                  _ActionTile(
                    icon: Icons.calendar_view_week,
                    label: l10n.firstDayOfWeek,
                    subtitle: ref.watch(firstDayOfWeekProvider) == 7
                        ? l10n.sundayOption
                        : l10n.mondayOption,
                    onTap: _toggleFirstDayOfWeek,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Logout
            Container(
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: AppConstants.borderColor, width: 0.5),
              ),
              child: _ActionTile(
                icon: Icons.logout,
                label: l10n.logout,
                iconColor: AppConstants.clockOutColor,
                textColor: AppConstants.clockOutColor,
                showChevron: false,
                onTap: _confirmLogout,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildViewProfile(AppLocalizations l10n, UserProfile? profile) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.mail_outline,
            label: l10n.email,
            value: profile?.email ?? '-',
          ),
          Divider(height: 1, color: AppConstants.borderColor, indent: 56),
          _InfoTile(
            icon: Icons.phone_outlined,
            label: l10n.phone,
            value: profile?.phone ?? '-',
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;

  const _ProfileStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppConstants.primaryColor),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor,
    this.textColor,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? AppConstants.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? AppConstants.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: AppConstants.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
