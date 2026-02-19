import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import 'icon_select_screen.dart' show IconSelectScreen, IconSelectResult;
import '../widgets/app_data_scope.dart';
import '../widgets/avatar_widget.dart';

const _kBase = Color(0xFFE8E0D5);
const _kTextDark = Color(0xFF4A3828);
const _kTextMid = Color(0xFF9E8A78);
const _kAccent = Color(0xFF8B7355);
const _kRed = Color(0xFFE07A5F);

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

  late final String _childId;

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
    final result = await Navigator.push<IconSelectResult>(
      context,
      MaterialPageRoute(
        builder: (_) => IconSelectScreen(childId: _childId),
      ),
    );
    if (result != null) {
      setState(() {
        _iconImagePath = result.path;
        _iconType = result.iconType;
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

  Future<void> _showDeleteDialog() async {
    final child = widget.child!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _kBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Neumorphic(
                style: NeumorphicStyle(
                  boxShape: NeumorphicBoxShape.circle(),
                  depth: 4,
                  color: _kRed.withValues(alpha: 0.15),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: _kRed,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '削除の確認',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '「${child.name}」のデータをすべて削除しますか？',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextMid, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: NeumorphicButton(
                      onPressed: () => Navigator.pop(ctx, false),
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
                      onPressed: () => Navigator.pop(ctx, true),
                      style: NeumorphicStyle(
                        depth: 4,
                        color: _kRed,
                        boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        '削除',
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
    );

    if (confirmed == true && mounted) {
      await AppDataScope.of(context).deleteChild(child.id);
      if (mounted) Navigator.of(context).pop('deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: _kBase,
      appBar: NeumorphicAppBar(
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
                      AvatarWidget(child: previewChild, radius: 52),
                      Neumorphic(
                        style: NeumorphicStyle(
                          depth: 4,
                          boxShape: NeumorphicBoxShape.circle(),
                          color: _kAccent,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Name field
              _NeumorphicFormField(
                controller: _nameController,
                labelText: '名前',
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '名前を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interest rate field
              _NeumorphicFormField(
                controller: _rateController,
                labelText: '年利',
                suffixText: '%',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) return '利率を入力してください';
                  final n = double.tryParse(value);
                  if (n == null || n < 0) return '0 以上の数値を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Save button
              NeumorphicButton(
                onPressed: _isSaving ? null : _save,
                style: NeumorphicStyle(
                  depth: 6,
                  color: _kAccent,
                  boxShape: NeumorphicBoxShape.roundRect(
                    BorderRadius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? '保存' : '追加する',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),

              // Delete button — editing only
              if (_isEditing) ...[
                const SizedBox(height: 48),
                NeumorphicButton(
                  onPressed: _showDeleteDialog,
                  style: NeumorphicStyle(
                    disableDepth: true,
                    boxShape: NeumorphicBoxShape.roundRect(
                      BorderRadius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: _kRed),
                      SizedBox(width: 6),
                      Text(
                        'このユーザーを削除',
                        style: TextStyle(
                          color: _kRed,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Neumorphic-styled form field: concave container + plain TextFormField.
class _NeumorphicFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _NeumorphicFormField({
    required this.controller,
    required this.labelText,
    this.suffixText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: -4,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            labelText: labelText,
            suffixText: suffixText,
            labelStyle: const TextStyle(color: _kTextMid),
          ),
          style: const TextStyle(color: _kTextDark, fontSize: 16),
          validator: validator,
        ),
      ),
    );
  }
}
