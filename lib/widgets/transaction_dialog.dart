import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import 'app_data_scope.dart';

/// D01: Modal dialog for deposit / withdrawal operations.
class TransactionDialog extends StatefulWidget {
  final Child child;
  final bool initialIsDeposit;

  const TransactionDialog({
    required this.child,
    required this.initialIsDeposit,
    super.key,
  });

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  static const _uuid = Uuid();

  late bool _isDeposit;
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  late DateTime _selectedDate;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isDeposit = widget.initialIsDeposit;
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final scope = AppDataScope.of(context);

    // Use the most up-to-date child data from scope.
    final current = scope.children.firstWhere(
      (c) => c.id == widget.child.id,
      orElse: () => widget.child,
    );
    final balanceAfter =
        _isDeposit ? current.balance + amount : current.balance - amount;

    final transaction = Transaction(
      id: _uuid.v4(),
      childId: current.id,
      type:
          _isDeposit ? TransactionType.deposit : TransactionType.withdrawal,
      amount: amount,
      balanceAfter: balanceAfter,
      memo: _memoController.text.trim(),
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    await scope.addTransaction(transaction);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日', 'ja');

    return AlertDialog(
      title: Text(_isDeposit ? '入金' : '出金'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('入金'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('出金'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_isDeposit},
                onSelectionChanged: (s) =>
                    setState(() => _isDeposit = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '金額（円）',
                  border: OutlineInputBorder(),
                  prefixText: '¥',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '金額を入力してください';
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) return '有効な金額を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('日付'),
                subtitle: Text(dateFormat.format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: 'メモ（任意）',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _confirm,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('確定'),
        ),
      ],
    );
  }
}
