import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';

import '../bloc/gratitude_bloc.dart';
import '../bloc/gratitude_event.dart';
import '../bloc/gratitude_state.dart';
import '../widgets/gratitude_card.dart';
import './edit_gratitude_screen.dart';
import './settings_screen.dart';
import '../core/di/injection.dart';
import '../services/notification_service.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';

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
      if (mounted) {
        context.read<GratitudeBloc>().add(const LoadGratitudes());
      }
    });
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
      // Check if app was resumed by a notification
      final notificationService = getIt<NotificationService>();
      await notificationService.checkAndHandlePendingNotification();

      // Reload gratitudes when app comes back to foreground
      if (mounted) {
        context.read<GratitudeBloc>().add(const LoadGratitudes());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<GratitudeBloc, GratitudeState>(
        builder: (context, state) {
          if (state is GratitudeLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black87,
              ),
            );
          }

          if (state is GratitudeError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'error_title'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is GratitudeLoaded) {
            if (state.groupedGratitudes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'empty_state_title'.tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'empty_state_message'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Get sorted dates (most recent first)
            final sortedDates = state.groupedGratitudes.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.grey[50]?.withOpacity(0.8),
                  elevation: 0,
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: FlexibleSpaceBar(
                        titlePadding:
                            const EdgeInsets.only(left: 24, bottom: 16),
                        title: Text(
                          _getGratitudeCountText(state.gratitudes.length),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 28,
                          ),
                        ),
                        centerTitle: false,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.black87),
                      tooltip: 'settings_title'.tr(),
                      onPressed: () => _navigateToSettings(context),
                    ),
                  ],
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = sortedDates[index];
                      final gratitudes = state.groupedGratitudes[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                            child: Text(
                              _formatDate(date),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Gratitude cards for this date with swipe-to-delete
                          ...gratitudes.map((gratitude) => Dismissible(
                                key: Key(gratitude.id.toString()),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await _showDeleteConfirmation(context);
                                },
                                onDismissed: (direction) {
                                  context
                                      .read<GratitudeBloc>()
                                      .add(DeleteGratitude(gratitude.id!));

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('gratitude_deleted'.tr()),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[400],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                child: GratitudeCard(
                                  gratitude: gratitude,
                                  onTap: () =>
                                      _navigateToEdit(context, gratitude),
                                ),
                              )),
                        ],
                      );
                    },
                    childCount: sortedDates.length,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(context, null),
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'add_button'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _getGratitudeCountText(int count) {
    if (count == 0) {
      return 'gratitudes_count_zero'.tr();
    } else if (count == 1) {
      return 'gratitudes_count_one'.tr();
    } else {
      // For Ukrainian, handle special plural forms
      final locale = context.locale.languageCode;
      if (locale == 'uk' || locale == 'ru') {
        final lastDigit = count % 10;
        final lastTwoDigits = count % 100;

        if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
          return 'gratitudes_count_other'
              .tr()
              .replaceAll('{}', count.toString());
        } else if (lastDigit >= 2 && lastDigit <= 4) {
          return 'gratitudes_count_few'.tr().replaceAll('{}', count.toString());
        } else {
          return 'gratitudes_count_other'
              .tr()
              .replaceAll('{}', count.toString());
        }
      }
      // For English and other languages
      return 'gratitudes_count_other'.tr().replaceAll('{}', count.toString());
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'today'.tr();
    } else if (date == yesterday) {
      return 'yesterday'.tr();
    } else {
      return DateFormat('EEEE, MMMM d, y').format(date).toUpperCase();
    }
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('delete_button'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit(BuildContext context, gratitude) async {
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
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
