import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:doto_receiptcognize/lib/utils/utils.dart';
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
      adjustTextToLocal(event.text.blocks, event.screen);
      yield DetectedTextSuccess(event.text);
    } else if (event is CheckForIntersection) {
      final listState = currentState;
      if (listState is DetectedTextSuccess) {
//        var intersectedBlocks = checkForIntersection(
//            listState.text, event.rectangle);
        yield IntersectedText(listState.text.blocks);
//        yield IntersectedText(intersectedBlocks);
      }
    }
  }

  @override
  DetectedTextState get initialState => DetectedTextStateEmpty();
}
