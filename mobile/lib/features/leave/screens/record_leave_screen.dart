import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/date_utils.dart';
import '../providers/leave_provider.dart';

class RecordLeaveScreen extends ConsumerStatefulWidget {
  const RecordLeaveScreen({super.key});

  @override
  ConsumerState<RecordLeaveScreen> createState() => _RecordLeaveScreenState();
}

class _RecordLeaveScreenState extends ConsumerState<RecordLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedLeaveTypeId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(leaveProvider);
      if (state.leaveTypes.isEmpty && !state.isLoading) {
        ref.read(leaveProvider.notifier).loadAll();
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _totalDays => AppDateUtils.daysBetween(_startDate, _endDate);

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLeaveTypeId == null) return;

    final l10n = AppLocalizations.of(context);
    final success = await ref.read(leaveProvider.notifier).recordLeave(
          leaveTypeId: _selectedLeaveTypeId!,
          startDate: AppDateUtils.formatDate(_startDate),
          endDate: AppDateUtils.formatDate(_endDate),
          reason: _reasonController.text.trim().isNotEmpty
              ? _reasonController.text.trim()
              : null,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.leaveRecorded),
          backgroundColor: AppConstants.clockInColor,
        ),
      );
      context.pop();
    } else {
      final error = ref.read(leaveProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? l10n.error),
          backgroundColor: AppConstants.clockOutColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveProvider);
    final l10n = AppLocalizations.of(context);

    // Show loading if leave types haven't loaded yet
    if (state.isLoading && state.leaveTypes.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    // Show error if loading failed
    if (state.error != null && state.leaveTypes.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppConstants.clockOutColor),
                      const SizedBox(height: 16),
                      Text(state.error!, style: const TextStyle(color: AppConstants.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(leaveProvider.notifier).loadAll(),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show message if no leave types configured
    if (state.leaveTypes.isEmpty && !state.isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: AppConstants.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noLeaveTypes,
                        style: const TextStyle(color: AppConstants.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingMD),
                  children: [
                    // Leave Type Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: AppConstants.borderColor, width: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DropdownButtonFormField<String>(
                        value: _selectedLeaveTypeId,
                        dropdownColor: AppConstants.cardColor,
                        decoration: InputDecoration(
                          labelText: l10n.leaveType,
                          prefixIcon: const Icon(Icons.category_outlined, color: AppConstants.textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        items: state.leaveTypes
                            .map((type) => DropdownMenuItem<String>(
                                  value: type['id'] as String,
                                  child: Text(type['name'] as String),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedLeaveTypeId = value);
                        },
                        validator: (value) =>
                            value == null ? '${l10n.leaveType} is required' : null,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMD),

                    // Date pickers row
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: l10n.startDate,
                            date: _startDate,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: l10n.endDate,
                            date: _endDate,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMD),

                    // Total days display
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMD),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppConstants.leaveColor.withValues(alpha: 0.1),
                            AppConstants.leaveColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: AppConstants.leaveColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, color: AppConstants.leaveColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.totalDays}: $_totalDays',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.leaveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMD),

                    // Reason
                    Container(
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: AppConstants.borderColor, width: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.reasonOptional,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 48),
                            child: Icon(Icons.notes_outlined, color: AppConstants.textMuted),
                          ),
                          alignLabelWithHint: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLG),

                    // Submit button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSM),
                          ),
                          elevation: 0,
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.save,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
            onPressed: () => context.pop(),
          ),
          Text(
            l10n.recordLeave,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: AppConstants.borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 18, color: AppConstants.primaryColor),
                const SizedBox(width: 6),
                Text(
                  AppDateUtils.formatDisplayDate(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
