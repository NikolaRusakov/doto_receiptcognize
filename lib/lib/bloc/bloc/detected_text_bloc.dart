import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:doto_receiptcognize/lib/types/text.dart';
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
      List<Block> localBlocks =
          adjustTextToLocal(event.text.blocks, event.screen);
      yield DetectedTextSuccess(event.text, localBlocks);
    } else if (event is CheckForIntersection) {
      final listState = currentState;
      if (listState is DetectedTextSuccess) {
        var intersectedBlocks =
            checkForIntersection(listState.blockPositions, event.rectangle);

        List<LineRef> blocksByXaxis = intersectedBlocks
            .map((block) => block.lines.map((line) => LineRef({
                  'elements': line.elements,
                  'text': line.text,
                  'boundingBox': line.boundingBox,
                }, block)))
            .toList()
            .expand((lines) => lines)
            .toList();

        blocksByXaxis
            .sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

        var sortedBlocksByXaxis =
            blocksByXaxis.fold<Map<String, List<LineRef>>>(
                {"left": [], "right": []},
                (c, line) => line.boundingBox.left < getAverage(blocksByXaxis)
                    ? {
                        "left": [...c["left"], line],
                        "right": [...c["right"]]
                      }
                    : {
                        "left": [...c["left"]],
                        "right": [...c["right"], line]
                      });

        var sortedSegments = sortedBlocksByXaxis.map((key, list) {
          var sorted = list;
          sorted.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
          return MapEntry(key, sorted);
        });
        RegExp regEx = RegExp(r'\d');
        sortedSegments['right']
            .removeWhere((value) => regEx.hasMatch(value.text) == false);
        List<Map<LineRef,List<LineRef>>> transformed = mergeSegments(sortedSegments);
        print(transformed);
        yield IntersectedText(listState.text.blocks, transformed);
//        yield IntersectedText(intersectedBlocks);
      }
    }
  }

  @override
  DetectedTextState get initialState => DetectedTextStateEmpty();
}
