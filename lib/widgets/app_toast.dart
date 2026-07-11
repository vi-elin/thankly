import 'dart:async';
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
/// Shown as a top-anchored overlay (swipe up to dismiss).
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration? duration,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        type: type,
        duration: duration ??
            (type == AppToastType.error
                ? const Duration(seconds: 3)
                : const Duration(seconds: 2)),
        onRemove: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
          entry.remove();
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: AppToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: AppToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: AppToastType.info);
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onRemove;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onRemove,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _offset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onRemove();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: SlideTransition(
            position: _offset,
            child: FadeTransition(
              opacity: _opacity,
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) < -200) {
                      _dismiss();
                    }
                  },
                  child: _ToastContent(message: widget.message, type: widget.type),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
