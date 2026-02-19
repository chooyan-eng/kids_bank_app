import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import '../widgets/app_data_scope.dart';
import '../widgets/avatar_widget.dart';

/// S03: Child add / edit screen.
/// Pass [child] to edit an existing child; omit it to create a new one.
class ChildEditScreen extends StatefulWidget {
  final Child? child;

  const ChildEditScreen({this.child, super.key});

  @override
  State<ChildEditScreen> createState() => _ChildEditScreenState();
}

class _ChildEditScreenState extends State<ChildEditScreen> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.child != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.child!.name;
      _rateController.text = widget.child!.interestRatePercent
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '.0');
    } else {
      _rateController.text = '0.0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final scope = AppDataScope.of(context);
    final name = _nameController.text.trim();
    final rate = double.parse(_rateController.text);

    if (_isEditing) {
      final updated = widget.child!.copyWith(
        name: name,
        interestRatePercent: rate,
      );
      await scope.updateChild(updated);
    } else {
      final now = DateTime.now();
      final newChild = Child(
        id: _uuid.v4(),
        name: name,
        interestRatePercent: rate,
        balance: 0.0,
        createdAt: now,
      );
      await scope.addChild(newChild);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Build a preview child so the avatar reflects the current name input.
    final previewName = _nameController.text.trim();
    final previewChild = widget.child?.copyWith(name: previewName) ??
        Child(
          id: '',
          name: previewName,
          interestRatePercent: 0,
          balance: 0,
          createdAt: DateTime.now(),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '子どもを編集' : '子どもを追加'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar preview — tapping is a no-op in Phase 1
              Center(
                child: Tooltip(
                  message: 'Phase 2 でアイコン設定が可能になります',
                  child: AvatarWidget(child: previewChild, radius: 48),
                ),
              ),
              const SizedBox(height: 32),

              // Name field
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '名前',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}), // refresh avatar preview
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '名前を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interest rate field
              TextFormField(
                controller: _rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '年利',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '利率を入力してください';
                  final n = double.tryParse(value);
                  if (n == null || n < 0) return '0 以上の数値を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save button
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? '保存' : '追加する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
