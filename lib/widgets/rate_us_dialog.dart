import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/di/injection.dart';
import '../services/settings_service.dart';
import '../services/firebase_service.dart';
import 'app_toast.dart';

const _titleColor = Color(0xFF2A2327);
const _bodyColor = Color(0xFF7A7177);
const _starInactive = Color(0xFFE4DEE1);
const _starActive = Color(0xFFF0B429);
const _secondaryBg = Color(0xFFF3F1F2);
const _secondaryText = Color(0xFF4A4044);

// Support inbox that receives low-rating feedback under the hood.
const _supportEmail = 'vielindevelopment@gmail.com';

// Set once the app has an App Store Connect record (numeric id from its
// App Store Connect URL, e.g. "6443888723"). Play Store uses the package
// name directly, so it needs no placeholder.
const _appStoreId = 'REPLACE_WITH_APP_STORE_ID';
const _androidPackageName = 'com.mobileapp.thanklio';

/// One-time "rate us" prompt: 5-star picker that branches based on rating.
/// 1-3 stars asks for a reason and emails it to support; 4-5 stars asks the
/// user to leave a review and opens the store listing.
class RateUsDialog extends StatefulWidget {
  const RateUsDialog({super.key});

  /// Shows the dialog at most once ever, only once [totalSavedCount] has
  /// reached the 7-gratitude threshold.
  static Future<void> maybeShow(
    BuildContext context, {
    required int totalSavedCount,
  }) async {
    final settingsService = getIt<SettingsService>();
    if (settingsService.hasShownRateUsPrompt) return;
    if (totalSavedCount < 7) return;

    // Mark as shown immediately so a rebuild before the dialog is dismissed
    // can't trigger it again.
    await settingsService.setHasShownRateUsPrompt(true);

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => const RateUsDialog(),
    );
  }

  @override
  State<RateUsDialog> createState() => _RateUsDialogState();
}

class _RateUsDialogState extends State<RateUsDialog> {
  int _rating = 0;
  final _reasonController = TextEditingController();

  // Set by any explicit action (send feedback, open store, or a dismiss
  // button) so the PopScope below only logs a "barrier" dismissal — tapping
  // outside the dialog or the Android back button — when nothing else
  // already tracked how the dialog was closed.
  bool _actionLogged = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop || _actionLogged) return;
        _actionLogged = true;
        FirebaseService().logEvent(
          name: 'rate_us_dismissed',
          parameters: {'stars': _rating, 'action': 'barrier'},
        );
      },
      child: Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: screenWidth * 0.85,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
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
                      'rate_us_title'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'rate_us_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: _bodyColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStars(),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: _rating == 0
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: _rating <= 3
                                  ? _buildLowRatingContent()
                                  : _buildHighRatingContent(),
                            ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: _buildSkipButton(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: () => _handleDismiss('skip'),
      child: Semantics(
        label: 'onboarding_skip'.tr(),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _secondaryBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 16, color: _bodyColor),
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isActive = starValue <= _rating;
        return GestureDetector(
          onTap: () => setState(() => _rating = starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isActive ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 38,
              color: isActive ? _starActive : _starInactive,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLowRatingContent() {
    return Column(
      children: [
        TextField(
          controller: _reasonController,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'rate_us_reason_hint'.tr(),
            hintStyle: const TextStyle(color: _bodyColor, fontSize: 14),
            filled: true,
            fillColor: _secondaryBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 16),
        _buildButton(
          label: 'rate_us_send_feedback'.tr(),
          isPrimary: true,
          onTap: _sendFeedback,
        ),
        const SizedBox(height: 10),
        _buildButton(
          label: 'rate_us_not_now'.tr(),
          isPrimary: false,
          onTap: () => _handleDismiss('not_now'),
        ),
      ],
    );
  }

  Widget _buildHighRatingContent() {
    return Column(
      children: [
        Text(
          'rate_us_store_prompt'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            color: _bodyColor,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        _buildButton(
          label: 'rate_us_rate_on_store'.tr(),
          isPrimary: true,
          onTap: _openStoreListing,
        ),
        const SizedBox(height: 10),
        _buildButton(
          label: 'rate_us_maybe_later'.tr(),
          isPrimary: false,
          onTap: () => _handleDismiss('maybe_later'),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE580A4), Color(0xFFD2698E)],
                )
              : null,
          color: isPrimary ? null : _secondaryBg,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? Border.all(color: const Color(0x66FFFFFF)) : null,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : _secondaryText,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  /// Logs the star rating (0 if none picked yet) alongside which dismiss
  /// action was taken, so Firebase shows what rating a user had in mind
  /// even when they backed out without submitting or opening the store.
  Future<void> _handleDismiss(String action) async {
    _actionLogged = true;
    await FirebaseService().logEvent(
      name: 'rate_us_dismissed',
      parameters: {'stars': _rating, 'action': action},
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _sendFeedback() async {
    final reason = _reasonController.text.trim();

    _actionLogged = true;
    await FirebaseService().logEvent(
      name: 'rate_us_feedback_submitted',
      parameters: {'stars': _rating},
    );

    final body = 'Rating: $_rating/5\n\n${reason.isEmpty ? '(no reason provided)' : reason}';
    final emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('Thanklio Feedback ($_rating★)')}'
          '&body=${Uri.encodeComponent(body)}',
    );

    final navigator = Navigator.of(context);
    final launched = await launchUrl(emailUri);
    if (!context.mounted) return;
    navigator.pop();
    if (!launched) {
      AppToast.error(context, 'could_not_open_link'.tr());
    }
  }

  Future<void> _openStoreListing() async {
    _actionLogged = true;
    await FirebaseService().logEvent(
      name: 'rate_us_store_opened',
      parameters: {'stars': _rating},
    );

    final url = Platform.isIOS
        ? 'https://apps.apple.com/app/id$_appStoreId?action=write-review'
        : 'https://play.google.com/store/apps/details?id=$_androidPackageName';

    final navigator = Navigator.of(context);
    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    navigator.pop();
    if (!launched) {
      AppToast.error(context, 'could_not_open_link'.tr());
    }
  }
}
