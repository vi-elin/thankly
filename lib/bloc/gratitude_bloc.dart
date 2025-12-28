import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/dao/gratitude_dao.dart';
import '../models/gratitude.dart';
import 'gratitude_event.dart';
import 'gratitude_state.dart';

class GratitudeBloc extends Bloc<GratitudeEvent, GratitudeState> {
  final GratitudeDao gratitudeDao;

  GratitudeBloc({required this.gratitudeDao})
      : super(const GratitudeInitial()) {
    on<LoadGratitudes>(_onLoadGratitudes);
    on<AddGratitude>(_onAddGratitude);
    on<UpdateGratitude>(_onUpdateGratitude);
    on<DeleteGratitude>(_onDeleteGratitude);
  }

  Future<void> _onLoadGratitudes(
    LoadGratitudes event,
    Emitter<GratitudeState> emit,
  ) async {
    try {
      emit(const GratitudeLoading());

      final entities = await gratitudeDao.findAllGratitudes();
      final gratitudes = entities.map((e) => Gratitude.fromEntity(e)).toList();
      final grouped = _groupByDate(gratitudes);

      emit(GratitudeLoaded(
        gratitudes: gratitudes,
        groupedGratitudes: grouped,
      ));
    } catch (e) {
      emit(GratitudeError('Failed to load gratitudes: $e'));
    }
  }

  Future<void> _onAddGratitude(
    AddGratitude event,
    Emitter<GratitudeState> emit,
  ) async {
    try {
      final entity = event.gratitude.toEntity();
      await gratitudeDao.insertGratitude(entity);

      // Reload gratitudes
      add(const LoadGratitudes());
    } catch (e) {
      emit(GratitudeError('Failed to add gratitude: $e'));
    }
  }

  Future<void> _onUpdateGratitude(
    UpdateGratitude event,
    Emitter<GratitudeState> emit,
  ) async {
    try {
      final entity = event.gratitude.toEntity();
      await gratitudeDao.updateGratitude(entity);

      // Reload gratitudes
      add(const LoadGratitudes());
    } catch (e) {
      emit(GratitudeError('Failed to update gratitude: $e'));
    }
  }

  Future<void> _onDeleteGratitude(
    DeleteGratitude event,
    Emitter<GratitudeState> emit,
  ) async {
    try {
      await gratitudeDao.deleteGratitudeById(event.id);

      // Reload gratitudes
      add(const LoadGratitudes());
    } catch (e) {
      emit(GratitudeError('Failed to delete gratitude: $e'));
    }
  }

  Map<DateTime, List<Gratitude>> _groupByDate(List<Gratitude> gratitudes) {
    final Map<DateTime, List<Gratitude>> grouped = {};

    for (var gratitude in gratitudes) {
      final dateKey = gratitude.dateOnly;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(gratitude);
    }

    return grouped;
  }
}
