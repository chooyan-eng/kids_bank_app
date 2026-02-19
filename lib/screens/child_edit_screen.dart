import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import 'icon_select_screen.dart';
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

  // Generated once in initState so new children can also get an icon path.
  late final String _childId;

  // Icon state updated after returning from IconSelectScreen.
  String? _iconImagePath;
  IconType? _iconType;

  bool get _isEditing => widget.child != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final child = widget.child!;
      _childId = child.id;
      _nameController.text = child.name;
      _rateController.text = child.interestRatePercent
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '.0');
      _iconImagePath = child.iconImagePath;
      _iconType = child.iconType;
    } else {
      _childId = _uuid.v4();
      _rateController.text = '0.0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _openIconSelect() async {
    final savedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => IconSelectScreen(childId: _childId),
      ),
    );
    if (savedPath != null) {
      setState(() {
        _iconImagePath = savedPath;
        _iconType = IconType.gallery;
      });
    }
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
        iconType: _iconType,
        iconImagePath: _iconImagePath,
      );
      await scope.updateChild(updated);
    } else {
      final now = DateTime.now();
      final newChild = Child(
        id: _childId,
        name: name,
        iconType: _iconType,
        iconImagePath: _iconImagePath,
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
    // Build a preview child reflecting the current name and icon selections.
    final previewName = _nameController.text.trim();
    final previewChild = Child(
      id: _childId,
      name: previewName,
      iconType: _iconType,
      iconImagePath: _iconImagePath,
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
              // Avatar preview — tap to open icon selection
              Center(
                child: GestureDetector(
                  onTap: _openIconSelect,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AvatarWidget(child: previewChild, radius: 48),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
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
