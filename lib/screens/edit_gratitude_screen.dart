import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/gratitude.dart';
import '../bloc/gratitude_bloc.dart';
import '../bloc/gratitude_event.dart';

const _editBg = Color(0xFFF2F2F4);
const _editPrimary = Color(0xFF2A2327);
const _editHeading = Color(0xFF4A4044);

class EditGratitudeScreen extends StatefulWidget {
  final Gratitude? gratitude;

  const EditGratitudeScreen({super.key, this.gratitude});

  @override
  State<EditGratitudeScreen> createState() => _EditGratitudeScreenState();
}

class _EditGratitudeScreenState extends State<EditGratitudeScreen> {
  late TextEditingController _controller;
  bool _isProcessingChange = false;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    final items = widget.gratitude?.items ?? [];
    final initialText = items.isEmpty ? '' : items.map((item) => '• $item').join('\n');
    _previousText = initialText;
    _controller = TextEditingController(text: initialText);
  }

  bool get _hasChanges {
    final currentItems = _getItems();
    final initialItems = widget.gratitude?.items ?? [];
    if (currentItems.length != initialItems.length) return true;
    for (int i = 0; i < currentItems.length; i++) {
      if (currentItems[i] != initialItems[i]) return true;
    }
    return false;
  }

  void _handleTextChanged(String text) {
    if (_isProcessingChange) return;
    _isProcessingChange = true;

    final cursorPosition = _controller.selection.baseOffset;
    String newText = text;
    int newCursorPosition = cursorPosition;

    if (_previousText.isEmpty && text.isNotEmpty && !text.startsWith('• ')) {
      newText = '• $text';
      newCursorPosition = cursorPosition + 2;
    } else if (text.length > _previousText.length && text.endsWith('\n')) {
      final lines = _previousText.split('\n');
      final currentLine = lines.last;
      if (currentLine.trim().length > 2) {
        if (!text.endsWith('• ')) {
          newText = '$text• ';
          newCursorPosition = cursorPosition + 2;
        }
      } else {
        newText = _previousText;
        newCursorPosition = cursorPosition - 1;
      }
    } else if (text.length < _previousText.length) {
      final deletedCount = _previousText.length - text.length;
      final oldCursorPosition = cursorPosition + deletedCount;
      if (oldCursorPosition <= _previousText.length) {
        final deletedText = _previousText.substring(cursorPosition, oldCursorPosition);
        if (deletedText == '•' && cursorPosition > 0 && _previousText[cursorPosition - 1] == '\n') {
          final beforeBullet = _previousText.substring(0, cursorPosition - 1);
          final afterBullet = _previousText.substring(oldCursorPosition + 1);
          newText = beforeBullet + afterBullet;
          newCursorPosition = beforeBullet.length;
        } else if (deletedText == ' ' && cursorPosition > 0 && _previousText[cursorPosition - 1] == '•') {
          newText = _previousText;
          newCursorPosition = cursorPosition;
        }
      }
    }

    _previousText = newText;

    if (newText != text || newCursorPosition != cursorPosition) {
      newCursorPosition = newCursorPosition.clamp(0, newText.length);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }

    _isProcessingChange = false;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _editBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBackButton(),
                  _buildSaveButton(),
                ],
              ),
            ),
            // Heading + text field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.gratitude == null
                          ? 'what_are_you_grateful_for'.tr()
                          : 'edit_your_gratitude'.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _editHeading,
                        letterSpacing: -0.42,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: _handleTextChanged,
                        style: const TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w500,
                          height: 1.7,
                          color: _editPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'gratitude_hint'.tr(),
                          hintStyle: const TextStyle(
                            color: Color(0xFFB09AA3),
                            fontSize: 18.5,
                            fontWeight: FontWeight.w500,
                            height: 1.7,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _handleBack,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.3, -1.0),
            end: Alignment(-0.3, 1.0),
            colors: [Color(0xB8FFFFFF), Color(0x75FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xD9FFFFFF)),
          boxShadow: const [
            BoxShadow(color: Color(0x14462D41), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.arrow_back, size: 22, color: Color(0xFF26211E)),
      ),
    );
  }

  Widget _buildSaveButton() {
    final active = _hasChanges;
    return GestureDetector(
      onTap: active ? _save : null,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE580A4), Color(0xFFD2698E)],
                )
              : null,
          color: active ? null : const Color(0xB3DCD8DD),
          border: Border.all(
            color: active ? const Color(0x66FFFFFF) : const Color(0x80FFFFFF),
          ),
          boxShadow: active
              ? [const BoxShadow(color: Color(0x56B2446A), blurRadius: 16, offset: Offset(0, 6))]
              : null,
        ),
        child: Icon(
          Icons.check,
          size: 22,
          color: active ? Colors.white : const Color(0xFFAAA1A6),
        ),
      ),
    );
  }

  List<String> _getItems() {
    return _controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          if (line.startsWith('• ')) return line.substring(2).trim();
          if (line.startsWith('•')) return line.substring(1).trim();
          if (line.startsWith('- ')) return line.substring(2).trim();
          if (line.startsWith('-')) return line.substring(1).trim();
          return line;
        })
        .where((line) => line.isNotEmpty)
        .toList();
  }

  void _handleBack() {
    if (_hasChanges && _controller.text.trim().isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFBE7F0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: Text('discard_changes_title'.tr(),
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: Color(0xFF211A1C))),
          content: Text('discard_changes_message'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF6C5B62), height: 1.45)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel_button'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFBF4A72))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('discard_button'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFBF4A72))),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _save() async {
    final items = _getItems();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_add_at_least_one_item'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final gratitude = Gratitude(
      id: widget.gratitude?.id,
      timestamp: widget.gratitude?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      items: items,
    );

    if (!mounted) return;
    final bloc = context.read<GratitudeBloc>();
    if (widget.gratitude == null) {
      bloc.add(AddGratitude(gratitude));
    } else {
      bloc.add(UpdateGratitude(gratitude));
    }
    if (mounted) Navigator.pop(context);
  }
}
