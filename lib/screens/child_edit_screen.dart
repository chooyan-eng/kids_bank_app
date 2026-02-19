import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import 'icon_select_screen.dart' show IconSelectScreen, IconSelectResult;
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

  Widget _buildNeumorphicField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E8E8E),
          ),
        ),
        const SizedBox(height: 8),
        Neumorphic(
          style: NeumorphicStyle(
            depth: -4,
            boxShape:
                NeumorphicBoxShape.roundRect(BorderRadius.circular(14)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              suffixText: suffix,
              suffixStyle: const TextStyle(color: Color(0xFF8E8E8E)),
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF3D3D3D)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = NeumorphicTheme.baseColor(context);

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
      backgroundColor: baseColor,
      appBar: NeumorphicAppBar(
        title: Text(
          _isEditing ? '子どもを編集' : '子どもを追加',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF3D3D3D),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
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
                          color: const Color(0xFFFFB74D),
                          boxShape: NeumorphicBoxShape.circle(),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Color(0xFF7B4F00),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Name field
              _buildNeumorphicField(
                controller: _nameController,
                label: '名前',
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}), // refresh avatar preview
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '名前を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Interest rate field
              _buildNeumorphicField(
                controller: _rateController,
                label: '年利',
                suffix: '%',
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
                style: NeumorphicStyle(
                  depth: 5,
                  color: const Color(0xFFFFB74D),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                onPressed: _isSaving ? null : _save,
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF7B4F00),
                            ),
                          ),
                        )
                      : Text(
                          _isEditing ? '保存' : '追加する',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7B4F00),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
