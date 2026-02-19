import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import 'app_data_scope.dart';

const _kBase = Color(0xFFE8E0D5);
const _kTextDark = Color(0xFF4A3828);
const _kTextMid = Color(0xFF9E8A78);
const _kGreen = Color(0xFF6AAF8B);
const _kRed = Color(0xFFE07A5F);
const _kAccent = Color(0xFF8B7355);

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

    return Dialog(
      backgroundColor: _kBase,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '入出金',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Type toggle
                Row(
                  children: [
                    Expanded(
                      child: NeumorphicButton(
                        onPressed: () =>
                            setState(() => _isDeposit = true),
                        style: NeumorphicStyle(
                          depth: _isDeposit ? -3 : 3,
                          color: _isDeposit ? _kGreen : null,
                          boxShape: NeumorphicBoxShape.roundRect(
                            const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: _isDeposit ? Colors.white : _kTextMid,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '入金',
                              style: TextStyle(
                                color:
                                    _isDeposit ? Colors.white : _kTextMid,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: NeumorphicButton(
                        onPressed: () =>
                            setState(() => _isDeposit = false),
                        style: NeumorphicStyle(
                          depth: !_isDeposit ? -3 : 3,
                          color: !_isDeposit ? _kRed : null,
                          boxShape: NeumorphicBoxShape.roundRect(
                            const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              size: 16,
                              color:
                                  !_isDeposit ? Colors.white : _kTextMid,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '出金',
                              style: TextStyle(
                                color:
                                    !_isDeposit ? Colors.white : _kTextMid,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Amount field
                _NeumorphicField(
                  controller: _amountController,
                  labelText: '金額（円）',
                  prefixText: '¥',
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '金額を入力してください';
                    final n = double.tryParse(value);
                    if (n == null || n <= 0) return '有効な金額を入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Date row
                GestureDetector(
                  onTap: _selectDate,
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      depth: -3,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: _kTextMid,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '日付',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _kTextMid,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(_selectedDate),
                                  style: const TextStyle(
                                    color: _kTextDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: _kTextMid,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Memo field
                _NeumorphicField(
                  controller: _memoController,
                  labelText: 'メモ（任意）',
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: NeumorphicButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: NeumorphicStyle(
                          depth: 4,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text(
                          'キャンセル',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _kTextMid),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeumorphicButton(
                        onPressed: _isLoading ? null : _confirm,
                        style: NeumorphicStyle(
                          depth: 4,
                          color: _kAccent,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '確定',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neumorphic-styled text input: concave container + plain TextField.
class _NeumorphicField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? prefixText;
  final TextInputType? keyboardType;
  final bool autofocus;
  final String? Function(String?)? validator;

  const _NeumorphicField({
    required this.controller,
    required this.labelText,
    this.prefixText,
    this.keyboardType,
    this.autofocus = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: -3,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            labelText: labelText,
            prefixText: prefixText,
            labelStyle: const TextStyle(color: _kTextMid),
          ),
          style: const TextStyle(color: _kTextDark),
          validator: validator,
        ),
      ),
    );
  }
}
