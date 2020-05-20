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

List<Map<LineRef, List<LineRef>>> mergeSegments(
    Map<String, List<LineRef>> sortedSegments) {
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
              next: topFirst
                  ? stackSet.toList()
                  : stackSet.toList().reversed.toList()
            }
          ]
        };
      })
      .entries
      .firstWhere((entry) {
        return entry.key.startsWith('transformed');
      })
      .value
      .cast<Map<LineRef, List<LineRef>>>()
      .toList();

  return topFirst ? mergedSegments : mergedSegments.reversed.toList();
}

List<Block> sortAndReturnExtremes(List<Block> blocks) {
  var sortedLeft = blocks;
  sortedLeft.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
  var sortedRight = blocks;
  sortedRight
      .sort((a, b) => a.boundingBox.right.compareTo(b.boundingBox.right));
  var start = sortedLeft.first.boundingBox.left.floor();
  var blocksMedian =
      ((sortedRight.reversed.toList().first.boundingBox.right - start) / 2)
          .floor();

  var invertedBlocks = sortedLeft.reversed.toList();
  var sortedBlocks = invertedBlocks
      .fold<Map<String, List<Block>>>({'left': [], 'right': []}, (curr, next) {
    return {
      ...curr,
      ...(vectorCenter(next, blocksMedian, start)
          ? {
              "right": [...curr["right"], next],
            }
          : {
              "left": [...curr["left"], next],
            })
    };
  })
//          .cast<String, List<Block>>()

      .map((k, v) {
    var values = v;
    values.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    return MapEntry(k, values);
  });

  return sortedBlocks['left'];
}

bool measureRightExtreme(Block block, int median) {
  var center = (block.boundingBox.right - block.boundingBox.left) / 2;
  return center >= median;
}

bool vectorCenter(Block blockA, int center, int start) {
  if (center < blockA.boundingBox.left) {
    return true;
  }

  if (center - blockA.boundingBox.left <
      calculateWithStart(blockA, start) / 2) {
    return true;
  }
  return false;
}

int calculateWithStart(Block block, int start) {
  var blockRight = block.boundingBox.right;
  if ((start - start * 0.1) < blockRight &&
      blockRight < (start + start * 0.1)) {
    return (blockRight / 2).floor();
  } else {
    return ((blockRight - block.boundingBox.left) / 2).floor();
  }
}