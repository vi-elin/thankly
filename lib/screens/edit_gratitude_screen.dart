import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/gratitude.dart';
import '../bloc/gratitude_bloc.dart';
import '../bloc/gratitude_event.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/app_toast.dart';

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

    if (text.length > _previousText.length && text.endsWith('\n')) {
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
    } else if (text.length > _previousText.length) {
      final insertedLength = text.length - _previousText.length;
      final oldCursorPosition = cursorPosition - insertedLength;
      if (oldCursorPosition >= 0 && oldCursorPosition <= _previousText.length) {
        int lineStart = 0;
        if (oldCursorPosition > 0) {
          final idx = _previousText.lastIndexOf('\n', oldCursorPosition - 1);
          lineStart = idx == -1 ? 0 : idx + 1;
        }
        final lineEndIndex = _previousText.indexOf('\n', oldCursorPosition);
        final lineEnd = lineEndIndex == -1 ? _previousText.length : lineEndIndex;
        final currentLineOld = _previousText.substring(lineStart, lineEnd);
        if (currentLineOld.isEmpty) {
          newText = '${text.substring(0, lineStart)}• ${text.substring(lineStart)}';
          newCursorPosition = cursorPosition + 2;
        }
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

  bool get _isEditingDisabled {
    if (widget.gratitude == null) return false;
    final today = DateTime.now();
    final createdDate = DateTime.fromMillisecondsSinceEpoch(widget.gratitude!.timestamp);
    return today.year != createdDate.year ||
           today.month != createdDate.month ||
           today.day != createdDate.day;
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();

    return Scaffold(
      backgroundColor: _editBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(items),
            // Heading
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Text(
                'what_are_you_grateful_for'.tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _editHeading,
                  letterSpacing: -0.33,
                  height: 1.12,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 16),
            // Text field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 40),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  enabled: !_isEditingDisabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(List<String> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBackButton(),
          Row(
            children: [
              _buildActionButtons(items),
              const SizedBox(width: 12),
              if (_hasChanges) _buildSaveButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(List<String> items) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.3, -1.0),
          end: Alignment(-0.3, 1.0),
          colors: [Color(0xB8FFFFFF), Color(0x75FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xD9FFFFFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x14462D41), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _handleDuplicate(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.content_copy, color: _editPrimary, size: 18),
            ),
          ),
          GestureDetector(
            onTap: () => _handleClear(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.delete_outline, color: _editPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _handleBack,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.chevron_left, color: _editPrimary, size: 22),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _save,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE580A4), Color(0xFFD2698E)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x56B2446A), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 20),
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
    if (!_isEditingDisabled && _hasChanges && _controller.text.trim().isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => CustomDialog(
          title: 'discard_changes_title'.tr(),
          content: 'discard_changes_message'.tr(),
          actions: [
            CustomDialogAction(
              label: 'cancel_button'.tr(),
              onPressed: () => Navigator.pop(context),
              isPrimary: false,
            ),
            CustomDialogAction(
              label: 'discard_button'.tr(),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              isAccentSecondary: true,
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
      AppToast.error(context, 'please_add_at_least_one_item'.tr());
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

  void _handleDuplicate() {
    final items = _getItems();
    if (items.isEmpty) return;

    final text = items.join('\n');
    Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      AppToast.success(context, 'copied_to_clipboard'.tr());
    }
  }

  void _handleClear() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'delete_gratitude_title'.tr(),
        content: 'delete_gratitude_message'.tr(),
        actions: [
          CustomDialogAction(
            label: 'cancel_button'.tr(),
            onPressed: () => Navigator.pop(context),
            isPrimary: false,
          ),
          CustomDialogAction(
            label: 'delete_button'.tr(),
            onPressed: () {
              Navigator.pop(context);
              if (widget.gratitude?.id != null) {
                context.read<GratitudeBloc>().add(DeleteGratitude(widget.gratitude!.id!));
              }
              Navigator.pop(context);
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}
