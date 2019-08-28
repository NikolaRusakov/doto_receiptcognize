import 'dart:ui';

import 'package:doto_receiptcognize/lib/types/text.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

List<Block> checkForIntersection(List<Block> blocks, Rect rectangle) {
  var intersectedText = blocks
      .map((block) => Block({
            "text": block.text,
            "boundingBox": block.boundingBox,
            "lines": block.lines
                .where((item) =>
                    item.boundingBox.center != null &&
                    rectangle.contains(item.boundingBox.center) == true)
                .toList()
          }))
      .where(((block) => block.lines.length != 0))
      .toList();

  return intersectedText;
}

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
