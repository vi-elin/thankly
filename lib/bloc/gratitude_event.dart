import 'package:equatable/equatable.dart';
import '../models/gratitude.dart';

abstract class GratitudeEvent extends Equatable {
  const GratitudeEvent();

  @override
  List<Object?> get props => [];
}

class LoadGratitudes extends GratitudeEvent {
  const LoadGratitudes();
}

class AddGratitude extends GratitudeEvent {
  final Gratitude gratitude;

  const AddGratitude(this.gratitude);

  @override
  List<Object?> get props => [gratitude];
}

class UpdateGratitude extends GratitudeEvent {
  final Gratitude gratitude;

  const UpdateGratitude(this.gratitude);

  @override
  List<Object?> get props => [gratitude];
}

class DeleteGratitude extends GratitudeEvent {
  final int id;

  const DeleteGratitude(this.id);

  @override
  List<Object?> get props => [id];
}
