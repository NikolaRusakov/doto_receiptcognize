import 'package:equatable/equatable.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:meta/meta.dart';

@immutable
abstract class DetectedTextEvent extends Equatable {
  DetectedTextEvent([List props = const <dynamic>[]]) : super(props);
}

class SaveDetectedText extends DetectedTextEvent {
  final VisionText text;

  SaveDetectedText({this.text}) : super([text]);

  @override
  String toString() => 'TextChanged {}';
}
