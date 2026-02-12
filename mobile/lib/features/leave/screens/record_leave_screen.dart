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

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.leaveRecorded)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordLeave),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          children: [
            // Leave Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedLeaveTypeId,
              decoration: InputDecoration(
                labelText: l10n.leaveType,
                prefixIcon: const Icon(Icons.category_outlined),
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
            const SizedBox(height: AppConstants.paddingMD),

            // Start Date
            _DateField(
              label: l10n.startDate,
              date: _startDate,
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: AppConstants.paddingMD),

            // End Date
            _DateField(
              label: l10n.endDate,
              date: _endDate,
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: AppConstants.paddingMD),

            // Total days display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMD),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, color: AppConstants.leaveColor),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.totalDays}: $_totalDays',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.leaveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMD),

            // Reason
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.reasonOptional,
                prefixIcon: const Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
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
                  foregroundColor: Colors.black,
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
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
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.date_range_outlined),
        ),
        child: Text(
          AppDateUtils.formatDisplayDate(date),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
