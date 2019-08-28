import 'dart:ui';

class Block extends BaseElement {
  Block(Map<dynamic, dynamic> data)
      : lines = List<Line>.unmodifiable(
            data['lines'].map<Line>((dynamic line) => Line({
                  "elements": line.elements,
                  "text": line.text,
                  "boundingBox": line.boundingBox,
                }))),
        super(data);
  List<Line> lines;
}

class Line extends BaseElement {
  Line(Map<dynamic, dynamic> data)
      : elements = List<Element>.unmodifiable(data['elements'].map<Element>(
            (dynamic element) => Element(
                {"boundingBox": element.boundingBox, "text": element.text}))),
        super(data);
  List<Element> elements;
}

class Element extends BaseElement {
  Element(Map<dynamic, dynamic> data) : super(data);
}

abstract class BaseElement {
  BaseElement(Map<dynamic, dynamic> data)
      : boundingBox = data['boundingBox'] != null ? data['boundingBox'] : null,
        text = data['text'];
  Rect boundingBox;
  String text;
}
