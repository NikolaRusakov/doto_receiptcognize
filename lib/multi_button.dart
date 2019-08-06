import 'package:doto_receiptcognize/lib/multi_touch_gesture_recognizer.dart';
import "package:flutter/material.dart";

class MultiButton extends StatelessWidget {

  final MultiTapButtonCallback onTapCallback;
  final int minTouches;
  final Color backgroundColor;
  final Color borderColor;

  MultiButton(this.backgroundColor, this.borderColor, this.minTouches, this.onTapCallback);

  void onTap(bool correctNumberOfTouches) {
    print(correctNumberOfTouches);
    this.onTapCallback(correctNumberOfTouches);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        MultiTouchGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            MultiTouchGestureRecognizer>(
              () => MultiTouchGestureRecognizer(),
              (MultiTouchGestureRecognizer instance) {
            instance.minNumberOfTouches = this.minTouches;
            instance.onMultiTap = (correctNumberOfTouches) => this.onTap(correctNumberOfTouches);
          },
        ),
      },
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child:
              Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: this.backgroundColor,
                  border: Border(
                    top: BorderSide(width: 1.0, color: borderColor),
                    left: BorderSide(width: 1.0, color: borderColor),
                    right: BorderSide(width: 1.0, color: borderColor),
                    bottom: BorderSide(width: 1.0, color: borderColor),
                  ),
                ),
                child: Text("Tap with " + "min" + " finger(s).", textAlign: TextAlign.center),
              ),
            ),
          ]),
    );
  }
}

typedef MultiTapButtonCallback = void Function(bool correctNumberOfTouches);