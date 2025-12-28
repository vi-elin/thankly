import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/gratitude.dart';
import '../bloc/gratitude_bloc.dart';
import '../bloc/gratitude_event.dart';

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
    // Initialize with existing gratitude items or empty
    final items = widget.gratitude?.items ?? [];
    String initialText;

    if (items.isEmpty) {
      // Start with empty text to show placeholder
      initialText = '';
    } else {
      // Add bullet points to existing items
      initialText = items.map((item) => '• $item').join('\n');
    }

    _previousText = initialText;
    _controller = TextEditingController(text: initialText);
  }

  bool get _hasChanges {
    // Compare cleaned items, not raw text with bullets
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

    // If user starts typing from empty, add bullet
    if (_previousText.isEmpty && text.isNotEmpty && !text.startsWith('• ')) {
      newText = '• ' + text;
      newCursorPosition = cursorPosition + 2;
    }
    // Handle Enter key - add bullet to new line
    else if (text.length > _previousText.length && text.endsWith('\n')) {
      // User pressed Enter
      // Check if the current line has any text (not just bullet)
      final lines = _previousText.split('\n');
      final currentLine = lines.last;

      // Only allow new line if current line has text after the bullet
      if (currentLine.trim().length > 2) {
        // More than just "• "
        if (!text.endsWith('• ')) {
          newText = text + '• ';
          newCursorPosition = cursorPosition + 2;
        }
      } else {
        // Don't allow new line, remove the newline character
        newText = _previousText;
        newCursorPosition = cursorPosition - 1;
      }
    }
    // Handle Backspace on bullet point
    else if (text.length < _previousText.length) {
      // User deleted something
      final deletedCount = _previousText.length - text.length;

      // The cursor position we have is AFTER deletion in the new text
      // We need to find where it was in the old text BEFORE deletion
      final oldCursorPosition = cursorPosition + deletedCount;

      if (oldCursorPosition <= _previousText.length) {
        // Check what was deleted
        final deletedText =
            _previousText.substring(cursorPosition, oldCursorPosition);

        // If user deleted a bullet character at the start of a line
        if (deletedText == '•' &&
            cursorPosition > 0 &&
            _previousText[cursorPosition - 1] == '\n') {
          // User is deleting the bullet at the start of a line (not the first line)
          // Merge this line with the previous line
          final beforeBullet = _previousText.substring(
              0, cursorPosition - 1); // Everything before the \n
          final afterBullet = _previousText
              .substring(oldCursorPosition + 1); // Skip the space after bullet

          newText = beforeBullet + afterBullet;
          newCursorPosition = beforeBullet.length;
        }
        // If user deleted the space after the bullet, restore it
        else if (deletedText == ' ' &&
            cursorPosition > 0 &&
            _previousText[cursorPosition - 1] == '•') {
          newText = _previousText; // Restore the text
          newCursorPosition = cursorPosition; // Keep cursor where it was
        }
      }
    }

    _previousText = newText;

    if (newText != text || newCursorPosition != cursorPosition) {
      // Ensure cursor position is within bounds
      newCursorPosition = newCursorPosition.clamp(0, newText.length);

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }

    _isProcessingChange = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _handleBack,
        ),
        actions: [
          // Delete button (only for existing gratitudes)
          if (widget.gratitude != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _handleDelete,
            ),
          IconButton(
            onPressed: _hasChanges ? _save : null,
            icon: Icon(
              Icons.check,
              color: _hasChanges ? Colors.white : Colors.grey[400],
            ),
            style: IconButton.styleFrom(
              backgroundColor: _hasChanges ? Colors.green : Colors.grey[200],
              shape: const CircleBorder(),
              disabledBackgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.gratitude == null
                    ? 'what_are_you_grateful_for'.tr()
                    : 'edit_your_gratitude'.tr(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey[800],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: _handleTextChanged,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'gratitude_hint'.tr(),
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      height: 1.8,
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
    );
  }

  List<String> _getItems() {
    return _controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          // Remove bullet points (• or -) from the beginning
          if (line.startsWith('• ')) {
            return line.substring(2).trim();
          } else if (line.startsWith('•')) {
            return line.substring(1).trim();
          } else if (line.startsWith('- ')) {
            return line.substring(2).trim();
          } else if (line.startsWith('-')) {
            return line.substring(1).trim();
          }
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
          title: Text('discard_changes_title'.tr()),
          content: Text('discard_changes_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel_button'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close screen
              },
              child: Text('discard_button'.tr()),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _handleDelete() async {
    if (widget.gratitude?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_gratitude_title'.tr()),
        content: Text('delete_gratitude_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel_button'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('delete_button'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<GratitudeBloc>().add(DeleteGratitude(widget.gratitude!.id!));
      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gratitude_deleted'.tr()),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
      timestamp:
          widget.gratitude?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      items: items,
    );

    // Save using BLoC
    if (!mounted) return;

    final bloc = context.read<GratitudeBloc>();
    if (widget.gratitude == null) {
      bloc.add(AddGratitude(gratitude));
    } else {
      bloc.add(UpdateGratitude(gratitude));
    }

    // Return to previous screen
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
