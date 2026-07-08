import 'package:flutter/material.dart';

enum AppToastType { success, error, info }

const _toastRadius = 14.0;
const _toastTitleColor = Color(0xFF2A2327);
const _toastShadow = Color(0x1F462D41);
const _toastSuccessTint = Color(0xFFFCEAF1);
const _toastSuccessIcon = Color(0xFFE85A8C);
const _toastErrorTint = Color(0x1AE04C5A);
const _toastErrorIcon = Color(0xFFE04C5A);
const _toastInfoTint = Color(0xFFFCEAF1);
const _toastInfoIcon = Color(0xFFE85A8C);

/// App-wide toast notifications matching the app's card/dialog visual language:
/// white rounded surface, soft plum-tinted shadow, tinted icon badge.
class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        // Match the content's own shape so the SnackBar's Material doesn't
        // fall back to its default (differently-rounded) corner shape.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_toastRadius),
        ),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        duration: duration ??
            (type == AppToastType.error
                ? const Duration(seconds: 3)
                : const Duration(seconds: 2)),
        dismissDirection: DismissDirection.down,
        content: _ToastContent(message: message, type: type),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: AppToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: AppToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: AppToastType.info);
}

class _ToastContent extends StatelessWidget {
  final String message;
  final AppToastType type;

  const _ToastContent({required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final IconData iconData;
    final Color tint;
    final Color iconColor;
    switch (type) {
      case AppToastType.success:
        iconData = Icons.check;
        tint = _toastSuccessTint;
        iconColor = _toastSuccessIcon;
        break;
      case AppToastType.error:
        iconData = Icons.close;
        tint = _toastErrorTint;
        iconColor = _toastErrorIcon;
        break;
      case AppToastType.info:
        iconData = Icons.info_outline;
        tint = _toastInfoTint;
        iconColor = _toastInfoIcon;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_toastRadius),
        boxShadow: const [
          BoxShadow(
            color: _toastShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(iconData, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: _toastTitleColor,
                height: 1.3,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
