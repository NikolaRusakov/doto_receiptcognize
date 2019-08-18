import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import './bloc.dart';

class DetectedTextBloc extends Bloc<DetectedTextEvent, DetectedTextState> {
  @override
  Stream<DetectedTextState> transform(
    Stream<DetectedTextEvent> events,
    Stream<DetectedTextState> Function(DetectedTextEvent event) next,
  ) {
    return super.transform(
      (events as Observable<DetectedTextEvent>).debounceTime(
        Duration(milliseconds: 100),
      ),
      next,
    );
  }

  @override
  Stream<DetectedTextState> mapEventToState(
    DetectedTextEvent event,
  ) async* {
    if (event is SaveDetectedText) {
      yield DetectedTextSuccess(event.text);
    }
  }

  @override
  DetectedTextState get initialState => DetectedTextStateEmpty();
}
