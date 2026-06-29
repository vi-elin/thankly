import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';

import '../bloc/gratitude_bloc.dart';
import '../bloc/gratitude_event.dart';
import '../bloc/gratitude_state.dart';
import '../widgets/gratitude_card.dart';
import './edit_gratitude_screen.dart';
import './settings_screen.dart';
import '../core/di/injection.dart';
import '../services/notification_service.dart';
import '../services/firebase_service.dart';
import '../models/gratitude.dart';

const _homePrimary = Color(0xFF211A1C);
const _homeSecondary = Color(0xFF8A8086);
const _homeSectionLabel = Color(0xFF7A7177);
const _homeBg = Color(0xFFF2F2F4);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = getIt<NotificationService>().onGratitudeSaved.listen((_) {
      if (mounted) context.read<GratitudeBloc>().add(const LoadGratitudes());
    });
    FirebaseService().logScreenView(screenName: 'home_screen', screenClass: 'HomeScreen');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final notificationService = getIt<NotificationService>();
      await notificationService.checkAndHandlePendingNotification();
      if (mounted) context.read<GratitudeBloc>().add(const LoadGratitudes());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _homeBg,
      body: BlocBuilder<GratitudeBloc, GratitudeState>(
        builder: (context, state) {
          if (state is GratitudeLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE85A8C)));
          }

          if (state is GratitudeError) {
            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(isEmpty: true),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(state.message,
                            style: const TextStyle(fontSize: 14, color: _homeSecondary), textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is GratitudeLoaded) {
            final isEmpty = state.groupedGratitudes.isEmpty;
            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(isEmpty: isEmpty),
                  Expanded(
                    child: isEmpty ? _buildEmptyState() : _buildList(context, state),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader({required bool isEmpty}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gratitude',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: _homePrimary,
                      letterSpacing: -0.54,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: _homeSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            const Spacer(),
          _buildSettingsButton(),
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () => _navigateToSettings(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.3, -1.0),
            end: Alignment(-0.3, 1.0),
            colors: [Color(0xB8FFFFFF), Color(0x75FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: const Color(0xD9FFFFFF)),
          boxShadow: const [
            BoxShadow(color: Color(0x14462D41), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.settings_outlined, size: 21, color: Color(0xFF6B6065)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 180),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              children: [
                Positioned(
                  left: 18,
                  top: 18,
                  child: const Icon(Icons.auto_awesome, size: 60, color: Color(0x52DB6A92)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'empty_state_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A4044),
              letterSpacing: -0.24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'empty_state_message'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9A9096),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, GratitudeLoaded state) {
    final sortedDates = state.groupedGratitudes.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      children: [
        for (final date in sortedDates) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
            child: Text(
              _formatDate(date).toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.68,
                color: _homeSectionLabel,
              ),
            ),
          ),
          for (final gratitude in state.groupedGratitudes[date]!)
            Dismissible(
              key: Key(gratitude.id.toString()),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _showDeleteConfirmation(context),
              onDismissed: (_) => _deleteGratitude(context, gratitude),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                margin: const EdgeInsets.only(bottom: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE580A4), Color(0xFFD2698E)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
              ),
              child: GratitudeCard(
                gratitude: gratitude,
                onTap: () => _navigateToEdit(context, gratitude),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => _navigateToEdit(context, null),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE580A4), Color(0xFFD2698E)],
          ),
          border: Border.all(color: const Color(0x66FFFFFF)),
          boxShadow: const [
            BoxShadow(color: Color(0x66B2446A), blurRadius: 26, offset: Offset(0, 10)),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28, weight: 600),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'today'.tr();
    if (date == yesterday) return 'yesterday'.tr();
    return DateFormat('EEEE, MMMM d, y').format(date);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
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
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBF4A72)),
            child: Text('delete_button'.tr()),
          ),
        ],
      ),
    );
  }

  void _deleteGratitude(BuildContext context, Gratitude gratitude) {
    context.read<GratitudeBloc>().add(DeleteGratitude(gratitude.id!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('gratitude_deleted'.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmAndDelete(BuildContext context, Gratitude gratitude) async {
    final bloc = context.read<GratitudeBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _showDeleteConfirmation(context);
    if (confirmed == true && mounted) {
      bloc.add(DeleteGratitude(gratitude.id!));
      messenger.showSnackBar(
        SnackBar(
          content: Text('gratitude_deleted'.tr()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToEdit(BuildContext context, Gratitude? gratitude) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGratitudeScreen(gratitude: gratitude),
      ),
    );
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}
