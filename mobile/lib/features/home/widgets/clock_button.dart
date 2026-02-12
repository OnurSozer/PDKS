import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';

class ClockButton extends StatelessWidget {
  final bool isClockedIn;
  final bool isLoading;
  final VoidCallback onPressed;

  const ClockButton({
    super.key,
    required this.isClockedIn,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = isClockedIn ? AppConstants.clockOutColor : AppConstants.clockInColor;
    final label = isClockedIn ? l10n.clockOut : l10n.clockIn;
    final icon = isClockedIn ? Icons.logout : Icons.login;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: AppConstants.clockButtonSize,
        height: AppConstants.clockButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
