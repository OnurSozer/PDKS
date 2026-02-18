import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';

class MonthPillBar extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const MonthPillBar({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  State<MonthPillBar> createState() => _MonthPillBarState();
}

class _MonthPillBarState extends State<MonthPillBar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(MonthPillBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    final index = widget.selectedMonth - 1;
    final offset = (index * 72.0) - 100;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthNames = l10n.shortMonthNames;
    final now = DateTime.now();

    return SizedBox(
      height: 38,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final isSelected = month == widget.selectedMonth;
          final isFuture = widget.selectedYear == now.year && month > now.month;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: isFuture ? null : () => widget.onMonthChanged(month),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: AppConstants.borderColor, width: 1),
                ),
                child: Text(
                  monthNames[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isFuture
                        ? AppConstants.textMuted
                        : isSelected
                            ? Colors.white
                            : AppConstants.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
