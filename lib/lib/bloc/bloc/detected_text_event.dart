import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:meta/meta.dart';

@immutable
abstract class DetectedTextEvent extends Equatable {
  DetectedTextEvent([List props = const <dynamic>[]]) : super(props);
}

class SaveDetectedText extends DetectedTextEvent {
  final VisionText text;
  final List<double> screen;

  SaveDetectedText({this.text, this.screen}) : super([text, screen]);

  @override
  String toString() => 'TextChanged {}';
}

class CheckForIntersection extends DetectedTextEvent {
  final Rect rectangle;

  CheckForIntersection({this.rectangle}) : super([rectangle]);

  @override
  String toString() => 'TextChanged {}';
}
