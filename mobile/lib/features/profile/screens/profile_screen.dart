import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _firstNameController = TextEditingController(text: profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdated)),
      );
      setState(() => _isEditing = false);
    }
  }

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
                    return 'Passwords do not match';
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
              backgroundColor: AppConstants.errorColor,
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
    final l10n = AppLocalizations.of(context);
    final profile = authState.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppConstants.primaryColor,
              child: Text(
                profile != null
                    ? '${profile.firstName[0]}${profile.lastName[0]}'
                    : '',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              profile?.fullName ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              profile?.email ?? '',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLG),

          if (_isEditing)
            _buildEditForm(l10n, authState.isLoading)
          else
            _buildViewProfile(l10n, profile),

          const Divider(height: 32),

          // Actions
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l10n.mySchedule),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/schedule'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outlined),
            title: Text(l10n.changePassword),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              Localizations.localeOf(context).languageCode == 'tr'
                  ? l10n.turkish
                  : l10n.english,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _toggleLanguage,
          ),
          const Divider(height: 16),
          ListTile(
            leading: Icon(Icons.logout, color: AppConstants.errorColor),
            title: Text(
              l10n.logout,
              style: TextStyle(color: AppConstants.errorColor),
            ),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(AppLocalizations l10n, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(labelText: l10n.firstName),
            validator: (v) => Validators.required(v, l10n.firstName),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(labelText: l10n.lastName),
            validator: (v) => Validators.required(v, l10n.lastName),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: l10n.phone),
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
          ),
          const SizedBox(height: AppConstants.paddingMD),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewProfile(AppLocalizations l10n, UserProfile? profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Column(
          children: [
            _InfoRow(label: l10n.firstName, value: profile?.firstName ?? '-'),
            _InfoRow(label: l10n.lastName, value: profile?.lastName ?? '-'),
            _InfoRow(label: l10n.email, value: profile?.email ?? '-'),
            _InfoRow(label: l10n.phone, value: profile?.phone ?? '-'),
            _InfoRow(
              label: l10n.startDateLabel,
              value: profile?.startDate ?? '-',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: AppConstants.textSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
