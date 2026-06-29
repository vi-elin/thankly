import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Widget that checks for app updates and maintenance mode on app start
class AppVersionChecker extends StatefulWidget {
  final Widget child;

  const AppVersionChecker({
    super.key,
    required this.child,
  });

  @override
  State<AppVersionChecker> createState() => _AppVersionCheckerState();
}

class _AppVersionCheckerState extends State<AppVersionChecker> {
  final _firebaseService = FirebaseService();
  bool _isChecking = true;
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      await _firebaseService.fetchRemoteConfig();
    } catch (e) {
      debugPrint('❌ Failed to load config: $e');
      if (mounted) setState(() => _isChecking = false);
      return;
    }

    if (!mounted) return;

    final maintenance = _firebaseService.isMaintenanceMode();
    final forceUpdate = _firebaseService.isForceUpdateRequired();
    final updateAvailable = _firebaseService.isUpdateAvailable(_currentVersion!);

    debugPrint('--- REMOTE CONFIG DIAGNOSTICS ---');
    debugPrint('Current App Version: $_currentVersion');
    debugPrint('maintenance_mode: $maintenance');
    debugPrint('force_update_required: $forceUpdate');
    debugPrint('minimum_app_version: ${_firebaseService.remoteConfig.getString('minimum_app_version')}');
    debugPrint('latest_app_version: ${_firebaseService.getLatestAppVersion()}');
    debugPrint('---------------------------------');

    if (maintenance) {
      _showMaintenanceDialog();
      return;
    }

    // force_update_required: true in Firebase → always show force update dialog
    if (forceUpdate) {
      _showForceUpdateDialog();
      return;
    }

    if (updateAvailable) {
      _showOptionalUpdateDialog();
    }

    setState(() => _isChecking = false);
  }

  void _showMaintenanceDialog() {
    final languageCode = context.locale.languageCode;
    final message = _firebaseService.getMaintenanceMessage(languageCode);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('maintenance_title'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              // Close the app
              Navigator.of(context).pop();
            },
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showForceUpdateDialog() {
    final languageCode = context.locale.languageCode;
    final message = _firebaseService.getUpdateMessage(languageCode);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('update_required'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: _openAppStore,
            child: Text('update_now'.tr()),
          ),
        ],
      ),
    );
  }

  void _showOptionalUpdateDialog() {
    final languageCode = context.locale.languageCode;
    final message = _firebaseService.getUpdateMessage(languageCode);
    final latestVersion = _firebaseService.getLatestAppVersion();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('update_available'.tr()),
        content: Text(
            '$message\n\n${'current_version'.tr()}: $_currentVersion\n${'latest_version'.tr()}: $latestVersion'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('later'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openAppStore();
            },
            child: Text('update_now'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppStore() async {
    // TODO: Replace with your actual App Store and Play Store URLs
    final url = Theme.of(context).platform == TargetPlatform.iOS
        ? Uri.parse('https://apps.apple.com/app/your-app-id')
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=com.thankly.vielin');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}
