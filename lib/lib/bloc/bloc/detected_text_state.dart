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

  DetectedTextSuccess(this.text) : super([text]);

  @override
  String toString() =>
      'DetectedTextStateSuccess { text: ${text.blocks.length} }';
}

class IntersectedText extends DetectedTextState {
  final List<TextBlock> text;

  IntersectedText(this.text) : super([text]);

  @override
  String toString() =>
      'IntersectedText { text: ${text.length} }';
}
