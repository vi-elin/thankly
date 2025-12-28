import 'package:floor/floor.dart';
import '../entities/gratitude_entity.dart';

@dao
abstract class GratitudeDao {
  @Query('SELECT * FROM GratitudeEntity ORDER BY timestamp DESC')
  Future<List<GratitudeEntity>> findAllGratitudes();

  @Query('SELECT * FROM GratitudeEntity WHERE id = :id')
  Future<GratitudeEntity?> findGratitudeById(int id);

  @Query('SELECT * FROM GratitudeEntity ORDER BY RANDOM() LIMIT 1')
  Future<GratitudeEntity?> findRandomGratitude();

  @insert
  Future<int> insertGratitude(GratitudeEntity gratitude);

  @update
  Future<int> updateGratitude(GratitudeEntity gratitude);

  @delete
  Future<int> deleteGratitude(GratitudeEntity gratitude);

  @Query('DELETE FROM GratitudeEntity WHERE id = :id')
  Future<void> deleteGratitudeById(int id);
}
