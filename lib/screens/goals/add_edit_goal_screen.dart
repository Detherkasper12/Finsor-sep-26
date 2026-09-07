import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import '../../models/goal.dart';
import '../../providers/goals_provider.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final Goal? goal;
  const AddEditGoalScreen({super.key, this.goal});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _debtorController;
  late GoalType _type;
  DateTime? _dueDate;
  String _color = '#4CAF50';

  bool get isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetController = TextEditingController(
      text: widget.goal != null ? widget.goal!.targetAmount.toStringAsFixed(2) : '',
    );
    _debtorController = TextEditingController(text: widget.goal?.debtorName ?? '');
    _type = widget.goal?.type ?? GoalType.savings;
    _dueDate = widget.goal?.dueDate;
    _color = widget.goal?.color ?? '#4CAF50';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _debtorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Goal' : 'New Goal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              Text('Type', style: Theme.of(context).textTheme.titleSmall),
              const Gap(8),
              SegmentedButton<GoalType>(
                segments: const [
                  ButtonSegment(value: GoalType.savings, label: Text('Savings'), icon: Icon(Icons.savings)),
                  ButtonSegment(value: GoalType.debt, label: Text('Debt'), icon: Icon(Icons.account_balance)),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const Gap(24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _type == GoalType.savings ? 'Goal Name' : 'Debt Name',
                  hintText: _type == GoalType.savings ? 'e.g. Emergency Fund' : 'e.g. Student Loan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
              ),
              if (_type == GoalType.debt) ...[
                const Gap(16),
                TextFormField(
                  controller: _debtorController,
                  decoration: InputDecoration(
                    labelText: 'Creditor / Debtor',
                    hintText: 'e.g. Bank of America',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const Gap(16),
              TextFormField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount required';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const Gap(16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(_dueDate == null
                    ? 'Set due date (optional)'
                    : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                trailing: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _dueDate = null),
                      )
                    : null,
                onTap: _pickDueDate,
              ),
              const Gap(24),
              // Color picker
              Text('Color', style: Theme.of(context).textTheme.titleSmall),
              const Gap(8),
              Wrap(
                spacing: 8,
                children: ['#4CAF50', '#2196F3', '#FF9800', '#E91E63', '#9C27B0', '#00BCD4', '#FF5722', '#607D8B']
                    .map((c) => GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(int.parse(c.replaceAll('#', '0xFF'))),
                            child: _color == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        ))
                    .toList(),
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final target = double.parse(_targetController.text);
    final notifier = ref.read(goalNotifierProvider.notifier);

    if (isEditing) {
      final updated = widget.goal!.copyWith(
        name: _nameController.text.trim(),
        type: _type,
        targetAmount: target,
        debtorName: _debtorController.text.trim().isNotEmpty ? _debtorController.text.trim() : null,
        dueDate: _dueDate,
        color: _color,
        updatedAt: DateTime.now(),
      );
      await notifier.updateGoal(updated);
    } else {
      final goal = Goal(
        id: 'goal_${const Uuid().v4()}',
        name: _nameController.text.trim(),
        type: _type,
        targetAmount: target,
        debtorName: _debtorController.text.trim().isNotEmpty ? _debtorController.text.trim() : null,
        dueDate: _dueDate,
        color: _color,
        iconName: _type == GoalType.savings ? 'savings' : 'account_balance',
        createdAt: DateTime.now(),
      );
      await notifier.addGoal(goal);
    }

    if (mounted) Navigator.pop(context);
  }
}
