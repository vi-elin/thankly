import 'package:flutter/material.dart';

const _dialogTitleColor = Color(0xFF2A2327);
const _dialogBodyColor = Color(0xFF7A7177);
const _dialogSecondaryBg = Color(0xFFF3F1F2);
const _dialogSecondaryText = Color(0xFF4A4044);
const _dialogDestructiveAccent = Color(0xFFE04C5A);

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<CustomDialogAction> actions;
  final bool isDangerous;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: screenWidth * 0.8,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F462D41),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _dialogTitleColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: _dialogBodyColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _buildActionButton(actions[i]),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(CustomDialogAction action) {
    return GestureDetector(
      onTap: action.onPressed,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: action.isPrimary
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE580A4), Color(0xFFD2698E)],
                )
              : null,
          color: action.isDestructive
              ? const Color(0xFFE04C5A)
              : action.isPrimary
                  ? null
                  : action.isAccentSecondary
                      ? Colors.white
                      : _dialogSecondaryBg,
          borderRadius: BorderRadius.circular(16),
          border: action.isAccentSecondary && !action.isPrimary && !action.isDestructive
              ? Border.all(color: _dialogDestructiveAccent, width: 1.5)
              : null,
          boxShadow: action.isPrimary || action.isDestructive
              ? [
                  BoxShadow(
                    color: action.isDestructive
                        ? const Color(0x40E04C5A)
                        : const Color(0x40B2446A),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            action.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: action.isPrimary || action.isDestructive
                  ? Colors.white
                  : action.isAccentSecondary
                      ? _dialogDestructiveAccent
                      : _dialogSecondaryText,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isAccentSecondary;

  CustomDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isAccentSecondary = false,
  });
}
