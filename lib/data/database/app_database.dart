import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../dao/gratitude_dao.dart';
import '../entities/gratitude_entity.dart';

part 'app_database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [GratitudeEntity])
abstract class AppDatabase extends FloorDatabase {
  GratitudeDao get gratitudeDao;
}
