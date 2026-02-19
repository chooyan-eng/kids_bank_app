import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import 'app_data_scope.dart';

/// D01: Neumorphic modal dialog for deposit / withdrawal operations.
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

  Widget _buildTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: NeumorphicButton(
            style: NeumorphicStyle(
              depth: _isDeposit ? -3 : 4,
              color: _isDeposit ? const Color(0xFFA5D6A7) : null,
              boxShape: NeumorphicBoxShape.roundRect(
                const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () => setState(() => _isDeposit = true),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_downward,
                  size: 16,
                  color: _isDeposit
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF8E8E8E),
                ),
                const SizedBox(width: 4),
                Text(
                  '入金',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isDeposit
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF8E8E8E),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: NeumorphicButton(
            style: NeumorphicStyle(
              depth: !_isDeposit ? -3 : 4,
              color: !_isDeposit ? const Color(0xFFFFCDD2) : null,
              boxShape: NeumorphicBoxShape.roundRect(
                const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () => setState(() => _isDeposit = false),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_upward,
                  size: 16,
                  color: !_isDeposit
                      ? const Color(0xFFB71C1C)
                      : const Color(0xFF8E8E8E),
                ),
                const SizedBox(width: 4),
                Text(
                  '出金',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: !_isDeposit
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFF8E8E8E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsetField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    TextInputType? keyboardType,
    bool autofocus = false,
    String? Function(String?)? validator,
  }) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: -3,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        autofocus: autofocus,
        validator: validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          labelText: label,
          labelStyle:
              const TextStyle(color: Color(0xFF8E8E8E), fontSize: 13),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: Color(0xFF3D3D3D)),
        ),
        style: const TextStyle(fontSize: 15, color: Color(0xFF3D3D3D)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日', 'ja');
    final baseColor = NeumorphicTheme.baseColor(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 10,
          color: baseColor,
          boxShape:
              NeumorphicBoxShape.roundRect(BorderRadius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  _isDeposit ? '入金' : '出金',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Type toggle (deposit / withdrawal)
                _buildTypeToggle(),
                const SizedBox(height: 16),

                // Amount field
                _buildInsetField(
                  controller: _amountController,
                  label: '金額（円）',
                  prefix: '¥',
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

                // Date picker row
                GestureDetector(
                  onTap: _selectDate,
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      depth: -3,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Color(0xFF8E8E8E),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            dateFormat.format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF3D3D3D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Memo field
                _buildInsetField(
                  controller: _memoController,
                  label: 'メモ（任意）',
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: NeumorphicButton(
                        style: NeumorphicStyle(
                          depth: 4,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Center(
                          child: Text(
                            'キャンセル',
                            style: TextStyle(color: Color(0xFF5D5D5D)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeumorphicButton(
                        style: NeumorphicStyle(
                          depth: 4,
                          color: const Color(0xFFFFB74D),
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: _isLoading ? null : _confirm,
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Color(0xFF7B4F00),
                                    ),
                                  ),
                                )
                              : const Text(
                                  '確定',
                                  style: TextStyle(
                                    color: Color(0xFF7B4F00),
                                    fontWeight: FontWeight.bold,
                                  ),
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
