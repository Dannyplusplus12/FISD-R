import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

/// Hiển thị số lượng — tap vào để nhập trực tiếp thay vì spam nút +/-
class SoLuongEditor extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final double width;
  final double fontSize;

  const SoLuongEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
    this.width = 48,
    this.fontSize = 16,
  });

  @override
  State<SoLuongEditor> createState() => _SoLuongEditorState();
}

class _SoLuongEditorState extends State<SoLuongEditor> {
  bool _editing = false;
  TextEditingController? _ctrl;

  void _startEdit() {
    _ctrl = TextEditingController(text: '${widget.value}')
      ..selection =
          TextSelection(baseOffset: 0, extentOffset: '${widget.value}'.length);
    setState(() => _editing = true);
  }

  void _commit(String text) {
    final v =
        (int.tryParse(text) ?? widget.value).clamp(widget.min, widget.max);
    _ctrl?.dispose();
    _ctrl = null;
    setState(() => _editing = false);
    if (v != widget.value) widget.onChanged(v);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return SizedBox(
        width: widget.width + 12,
        height: 36,
        child: Center(
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: widget.fontSize),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onSubmitted: _commit,
            onTapOutside: (_) => _commit(_ctrl?.text ?? ''),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _startEdit,
      child: Container(
        width: widget.width,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text('${widget.value}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: widget.fontSize)),
        ),
      ),
    );
  }
}
