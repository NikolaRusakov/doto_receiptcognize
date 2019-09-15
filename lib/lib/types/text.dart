import 'dart:ui';

abstract class BaseElement {
  BaseElement(Map<dynamic, dynamic> data)
      : boundingBox = data['boundingBox'] != null ? data['boundingBox'] : null,
        text = data['text'];
  Rect boundingBox;
  String text;
}

class Block extends BaseElement {
  Block(Map<dynamic, dynamic> data)
      : lines = List<Line>.unmodifiable(
            data['lines'].map<Line>((dynamic line) => Line({
                  'elements': line.elements,
                  'text': line.text,
                  'boundingBox': line.boundingBox,
                }))),
        _lineMap = data,
        super(data);

  List<Line> lines;

  Map<dynamic, dynamic> _lineMap;

  get lineToMap => Map.from(_lineMap);
}

class Line extends BaseElement {
  Line(Map<dynamic, dynamic> data)
      : elements = List<Element>.unmodifiable(data['elements'].map<Element>(
            (dynamic element) => Element(
                {'boundingBox': element.boundingBox, 'text': element.text}))),
        _lineMap = data,
        super(data);

  Map<dynamic, dynamic> _lineMap;

  List<Element> elements;

  get lineToMap => Map.from(_lineMap);
}

class Element extends BaseElement {
  Element(Map<dynamic, dynamic> data)
      : _lineMap = data,
        super(data);

  Map<dynamic, dynamic> _lineMap;

  get lineToMap => Map.from(_lineMap);
}

class LineRef extends Line {
  LineRef(Map<dynamic, dynamic> data, Block ref)
      : ref = ref,
        _lineMap = data,
        super(data);

  Block ref;

  Map<dynamic, dynamic> _lineMap;

  get lineToMap => Map.from(_lineMap);
}
