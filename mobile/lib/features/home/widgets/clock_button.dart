import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';

class ClockButton extends StatelessWidget {
  final bool isClockedIn;
  final bool isLoading;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  const ClockButton({
    super.key,
    required this.isClockedIn,
    required this.isLoading,
    required this.onPressed,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = isClockedIn ? l10n.clockOutButtonTitle : l10n.clockInButtonTitle;
    final subtitle = isClockedIn ? l10n.clockOutButtonSubtitle : l10n.clockInButtonSubtitle;

    // Purple gradient for clock-in, red gradient for clock-out
    final colors = isClockedIn
        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
        : [AppConstants.primaryLight, AppConstants.primaryDark];

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      onLongPress: isLoading ? null : onLongPress,
      child: Container(
        width: AppConstants.clockButtonSize,
        height: AppConstants.clockButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
