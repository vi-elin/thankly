import 'package:flutter/material.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.3, -1.0),
            end: Alignment(-0.3, 1.0),
            colors: [
              const Color(0xB8FFFFFF),
              const Color(0x75FFFFFF),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xD9FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14462D41),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF211A1C),
                  letterSpacing: -0.24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C5B62),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    _buildActionButton(actions[i]),
                    if (i < actions.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(CustomDialogAction action) {
    return Flexible(
      child: GestureDetector(
        onTap: action.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            gradient: action.isPrimary
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE580A4), Color(0xFFD2698E)],
                  )
                : null,
            color: action.isPrimary ? null : const Color(0x00000000),
            borderRadius: BorderRadius.circular(12),
            border: action.isPrimary ? Border.all(color: const Color(0x66FFFFFF)) : null,
          ),
          child: Text(
            action.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: action.isPrimary ? Colors.white : const Color(0xFFBF4A72),
              letterSpacing: -0.24,
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

  CustomDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}
