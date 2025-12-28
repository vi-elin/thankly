import 'package:equatable/equatable.dart';
import '../models/gratitude.dart';

abstract class GratitudeState extends Equatable {
  const GratitudeState();

  @override
  List<Object?> get props => [];
}

class GratitudeInitial extends GratitudeState {
  const GratitudeInitial();
}

class GratitudeLoading extends GratitudeState {
  const GratitudeLoading();
}

class GratitudeLoaded extends GratitudeState {
  final List<Gratitude> gratitudes;
  final Map<DateTime, List<Gratitude>> groupedGratitudes;

  const GratitudeLoaded({
    required this.gratitudes,
    required this.groupedGratitudes,
  });

  @override
  List<Object?> get props => [gratitudes, groupedGratitudes];
}

class GratitudeError extends GratitudeState {
  final String message;

  const GratitudeError(this.message);

  @override
  List<Object?> get props => [message];
}
