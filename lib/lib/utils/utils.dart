import 'dart:ui';

import 'package:doto_receiptcognize/lib/types/text.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

List<Block> checkForIntersection(List<Block> blocks, Rect rectangle) {
  var intersectedText = blocks
      .map((block) => Block({
            "text": block.text,
            "boundingBox": block.boundingBox,
            "lines": block.lines
                .where((line) => intersectsRect(rectangle, line.boundingBox))
                .toList()
          }))
      .where(((block) => block.lines.length > 0))
      .toList();

  return intersectedText;
}

bool intersectsRect(Rect rectangle, Rect line) => ((rectangle.top < line.top) &&
    ((rectangle.left < line.left) || (rectangle.left < line.right)) &&
    (rectangle.right > line.right) &&
    (rectangle.bottom > line.bottom));

Rect adjustRect(TextContainer container, List<double> screenSize) {
  return Rect.fromLTRB(
      container.boundingBox.left * screenSize[0],
      container.boundingBox.top * screenSize[1],
      container.boundingBox.right * screenSize[0],
      container.boundingBox.bottom * screenSize[1]);
}

List<Block> adjustTextToLocal(List<TextBlock> blocks, List<double> screen) {
  var bls = blocks
      .map((block) => Block({
            "text": block.text,
            "boundingBox": scaleRect(block, screen),
            "lines": block.lines
                .map((line) => Line({
                      "text": line.text,
                      "boundingBox": scaleRect(line, screen),
                      "elements": line.elements
                          .map((element) => Element({
                                "text": element.text,
                                "boundingBox": scaleRect(element, screen)
                              }))
                          .toList(),
                    }))
                .toList()
          }))
      .toList();
  return bls;
}

Rect scaleRect(TextContainer container, List<double> screenSize) {
  return Rect.fromLTRB(
      container.boundingBox.left * screenSize[0],
      container.boundingBox.top * screenSize[1],
      container.boundingBox.right * screenSize[0],
      container.boundingBox.bottom * screenSize[1]);
}

double getAverage(List<Line> list) =>
    (list.first.boundingBox.left + list.last.boundingBox.left) / 1.5;

bool detectTopFirst(Map<String, List<LineRef>> segments) {
  var leftDy = segments['left'].first.boundingBox.center.dy;
  var right = segments['right'].first.boundingBox;
  return leftDy < right.top;
}

List<LineRef> mergeSegments(Map<String, List<LineRef>> sortedSegments) {
  var topFirst = detectTopFirst(sortedSegments);
  var segments = topFirst
      ? sortedSegments
      : sortedSegments.map((k, v) => MapEntry(k, v.reversed.toList()));
  //TODO optimize algorithm to make it work with normal use-cases
  var mergedSegments = segments['right']
      .fold({'stack': segments['left'], 'transformed': []}, (curr, next) {
    var currStack = (curr['stack'] as List<LineRef>);
    var stackSet = currStack
//        .where((line) => line.boundingBox.top < next.boundingBox.center.dy)
//        .where((line) => intersectsLine(line, next, topFirst))
        .where((line) => topFirst
            ? line.boundingBox.top < next.boundingBox.center.dy
            : line.boundingBox.center.dy > next.boundingBox.top)
        .toSet();
    currStack.sublist(stackSet.length, currStack.length);
    return {
      'stack': currStack.sublist(stackSet.length, currStack.length),
      'transformed': [
        ...curr['transformed'],
        {
          next:
              topFirst ? stackSet.toList() : stackSet.toList().reversed.toList()
        }
      ]
    };
  });

  var merged = topFirst
      ? mergedSegments
      : mergedSegments.map((k, v) => MapEntry(k, v.reversed.toList()));
  return merged['transformed'];
}
