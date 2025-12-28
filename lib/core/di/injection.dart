import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/app_database.dart';
import '../../data/dao/gratitude_dao.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import '../../bloc/gratitude_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // SharedPreferences - singleton
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Settings Service - singleton
  getIt.registerSingleton<SettingsService>(SettingsService(prefs));

  // Database - singleton
  final database =
      await $FloorAppDatabase.databaseBuilder('gratitude_database.db').build();
  getIt.registerSingleton<AppDatabase>(database);

  // DAO - singleton
  getIt.registerSingleton<GratitudeDao>(database.gratitudeDao);

  // Notification Service - singleton
  getIt.registerSingleton<NotificationService>(NotificationService.instance);

  // BLoC - factory (new instance each time)
  getIt.registerFactory<GratitudeBloc>(
    () => GratitudeBloc(gratitudeDao: getIt<GratitudeDao>()),
  );
}
