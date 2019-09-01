import 'package:doto_receiptcognize/lib/types/text.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:meta/meta.dart';

@immutable
abstract class DetectedTextState extends Equatable {
  DetectedTextState([List props = const <dynamic>[]]) : super(props);
}

class DetectedTextStateEmpty extends DetectedTextState {
  @override
  String toString() => 'DetectedTextStateEmpty';
}

class DetectedTextSuccess extends DetectedTextState {
  final VisionText text;
  final List<Block> blockPositions;

  DetectedTextSuccess(this.text, this.blockPositions)
      : super([text, blockPositions]);

  @override
  String toString() =>
      'DetectedTextSuccess { text: ${text.blocks.length}, blockPositions ${text.blocks.length} }';
}

class IntersectedText extends DetectedTextState {
  final List<TextBlock> text;
  final List<LineRef> transformed;

  IntersectedText(this.text, this.transformed) : super([text, transformed]);

  @override
  String toString() => 'IntersectedText { text: ${text.length} }';
}
