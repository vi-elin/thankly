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
import '../widgets/custom_dialog.dart';
import '../widgets/app_toast.dart';

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
  static const int _pageSize = 30;

  StreamSubscription? _subscription;
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = getIt<NotificationService>().onGratitudeSaved.listen((_) {
      if (mounted) context.read<GratitudeBloc>().add(const LoadGratitudes());
    });
    _scrollController.addListener(_onScroll);
    FirebaseService().logScreenView(screenName: 'home_screen', screenClass: 'HomeScreen');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final state = context.read<GratitudeBloc>().state;
    if (state is GratitudeLoaded && _visibleCount < state.gratitudes.length) {
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, state.gratitudes.length);
      });
    }
  }

  // Groups the given (already newest-first) gratitude records by day, for
  // rendering only the currently paginated-in subset with day headers.
  Map<DateTime, List<Gratitude>> _groupByDate(List<Gratitude> gratitudes) {
    final Map<DateTime, List<Gratitude>> grouped = {};
    for (final gratitude in gratitudes) {
      grouped.putIfAbsent(gratitude.dateOnly, () => []).add(gratitude);
    }
    return grouped;
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
      // Home has no text input, so it never needs to resize for the
      // keyboard. Without this, the FAB (which is positioned relative to
      // the Scaffold's content bottom) visibly jumps down as the previous
      // screen's keyboard-closing animation transiently changes
      // MediaQuery.viewInsets.bottom while navigating back here.
      resizeToAvoidBottomInset: false,
      body: BlocBuilder<GratitudeBloc, GratitudeState>(
        builder: (context, state) {
          if (state is GratitudeLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE85A8C)));
          }

          if (state is GratitudeError) {
            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(isEmpty: true, groupedGratitudes: {}),
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
            final visibleCount = _visibleCount.clamp(0, state.gratitudes.length);
            final visibleGratitudes = state.gratitudes.take(visibleCount).toList();
            final visibleGrouped = _groupByDate(visibleGratitudes);
            final hasMore = visibleCount < state.gratitudes.length;
            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(isEmpty: isEmpty, groupedGratitudes: state.groupedGratitudes),
                  Expanded(
                    child: isEmpty ? _buildEmptyState() : _buildList(context, visibleGrouped, hasMore),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader({required bool isEmpty, required Map<DateTime, List<Gratitude>> groupedGratitudes}) {
    final daysCount = groupedGratitudes.length;
    final totalItems = groupedGratitudes.values.fold<int>(0, (sum, gratitudeList) {
      return sum + gratitudeList.fold<int>(0, (itemSum, g) => itemSum + g.items.length);
    });

    final daysLabel = daysCount == 1 ? 'Grateful Day' : 'Grateful Days';
    final gratitudeLabel = totalItems == 1 ? 'Gratitude' : 'Gratitudes';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$totalItems $gratitudeLabel',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: _homeSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$daysCount $daysLabel',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: _homeSecondary,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _buildSettingsButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () => _navigateToSettings(context),
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
        child: const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF6B6065)),
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

  Widget _buildList(BuildContext context, Map<DateTime, List<Gratitude>> groupedGratitudes, bool hasMore) {
    final sortedDates = groupedGratitudes.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      controller: _scrollController,
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
          for (final gratitude in groupedGratitudes[date]!)
            Dismissible(
              key: Key(gratitude.id.toString()),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _showDeleteConfirmation(context),
              onDismissed: (_) => _deleteGratitude(context, gratitude),
              background: Align(
                alignment: Alignment.centerRight,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 18, bottom: 13),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE04C5A),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  ),
                ),
              ),
              child: GratitudeCard(
                gratitude: gratitude,
                onTap: () => _navigateToEdit(context, gratitude),
              ),
            ),
        ],
        if (hasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE85A8C)),
              ),
            ),
          ),
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
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28, weight: 600),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'today'.tr().toUpperCase();
    }
    if (date == yesterday) {
      return 'yesterday'.tr().toUpperCase();
    }

    if (date.year == now.year) {
      return DateFormat('MMMM d').format(date).toUpperCase();
    }

    return DateFormat('MMMM d, y').format(date).toUpperCase();
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        title: 'delete_gratitude_title'.tr(),
        content: 'delete_gratitude_message'.tr(),
        actions: [
          CustomDialogAction(
            label: 'cancel_button'.tr(),
            onPressed: () => Navigator.pop(context, false),
            isPrimary: false,
          ),
          CustomDialogAction(
            label: 'delete_button'.tr(),
            onPressed: () => Navigator.pop(context, true),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _deleteGratitude(BuildContext context, Gratitude gratitude) {
    context.read<GratitudeBloc>().add(DeleteGratitude(gratitude.id!));
    AppToast.success(context, 'gratitude_deleted'.tr());
  }

  void _confirmAndDelete(BuildContext context, Gratitude gratitude) async {
    final bloc = context.read<GratitudeBloc>();
    final confirmed = await _showDeleteConfirmation(context);
    if (confirmed == true && mounted) {
      bloc.add(DeleteGratitude(gratitude.id!));
      AppToast.success(context, 'gratitude_deleted'.tr());
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
