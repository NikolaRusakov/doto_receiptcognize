import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:doto_receiptcognize/main.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

import 'detector_painters.dart';

class PictureScanner extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PictureScannerState();
}

class _PictureScannerState extends State<PictureScanner> {
  File _imageFile;
  Size _imageSize;
  dynamic _scanResults;
  Detector _currentDetector = Detector.text;
  final BarcodeDetector _barcodeDetector =
      FirebaseVision.instance.barcodeDetector();
  final FaceDetector _faceDetector = FirebaseVision.instance.faceDetector();
  final ImageLabeler _imageLabeler = FirebaseVision.instance.imageLabeler();
  final ImageLabeler _cloudImageLabeler =
      FirebaseVision.instance.cloudImageLabeler();
  final TextRecognizer _recognizer = FirebaseVision.instance.textRecognizer();
  final TextRecognizer _cloudRecognizer =
      FirebaseVision.instance.cloudTextRecognizer();

  Future<void> _getAndScanImage() async {
    setState(() {
      _imageFile = null;
      _imageSize = null;
    });

    final File imageFile =
        await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      _getImageSize(imageFile);
      _scanImage(imageFile);
    }

    setState(() {
      _imageFile = imageFile;
    });
  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
//    ImageListener imageListener = (ImageInfo info, syncCall) {
//      completer.complete(Size(
//        info.image.width.toDouble(),
//        info.image.height.toDouble(),
//      ));
//    };
//    ImageStreamListener listenerStream = new ImageStreamListener(imageListener);
//    stream.addListener(ImageStreamListener(imageListener));
//    stream.removeListener(ImageStreamListener(imageListener));
    image.image.resolve(const ImageConfiguration()).addListener(
      ((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  Future<void> _scanImage(File imageFile) async {
    setState(() {
      _scanResults = null;
    });

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    dynamic results;
    switch (_currentDetector) {
      case Detector.barcode:
        results = await _barcodeDetector.detectInImage(visionImage);
        break;
      case Detector.face:
        results = await _faceDetector.processImage(visionImage);
        break;
      case Detector.label:
        results = await _imageLabeler.processImage(visionImage);
        break;
      case Detector.cloudLabel:
        results = await _cloudImageLabeler.processImage(visionImage);
        break;
      case Detector.text:
        results = await _recognizer.processImage(visionImage);
        break;
      case Detector.cloudText:
        results = await _cloudRecognizer.processImage(visionImage);
        break;
      default:
        return;
    }
    VisionText _currentLabels;
    _currentLabels = results;
    _currentLabels.blocks.asMap();
    for (var text in _currentLabels.blocks) {
      print("text : ${text.text}");
    }
    setState(() {
      _scanResults = results;
    });
  }

  CustomPaint _buildResults(Size imageSize, dynamic results) {
    CustomPainter painter;
    switch (_currentDetector) {
      case Detector.barcode:
        painter = BarcodeDetectorPainter(_imageSize, results);
        break;
      case Detector.face:
        painter = FaceDetectorPainter(_imageSize, results);
        break;
      case Detector.label:
        painter = LabelDetectorPainter(_imageSize, results);
        break;
      case Detector.cloudLabel:
        painter = LabelDetectorPainter(_imageSize, results);
        break;
      case Detector.text:
        painter = TextDetectorPainter(_imageSize, results);
        break;
      case Detector.cloudText:
        painter = TextDetectorPainter(_imageSize, results);
        break;
      default:
        break;
    }

    return CustomPaint(
      painter: painter,
    );
  }

  Widget _buildImage() {
    return MultiTapRecognize(
        child: Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Image.file(_imageFile).image,
          fit: BoxFit.contain,
        ),
      ),
      child: _imageSize == null || _scanResults == null
          ? const Center(
              child: Text(
                'Scanning...',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 30.0,
                ),
              ),
            )
          : _buildResults(_imageSize, _scanResults),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return WrapperWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Picture Scanner'),
          actions: <Widget>[
            PopupMenuButton<Detector>(
              onSelected: (Detector result) {
                _currentDetector = result;
                if (_imageFile != null) _scanImage(_imageFile);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<Detector>>[
                    const PopupMenuItem<Detector>(
                      child: Text('Detect Barcode'),
                      value: Detector.barcode,
                    ),
                    const PopupMenuItem<Detector>(
                      child: Text('Detect Face'),
                      value: Detector.face,
                    ),
                    const PopupMenuItem<Detector>(
                      child: Text('Detect Label'),
                      value: Detector.label,
                    ),
                    const PopupMenuItem<Detector>(
                      child: Text('Detect Cloud Label'),
                      value: Detector.cloudLabel,
                    ),
                    const PopupMenuItem<Detector>(
                      child: Text('Detect Text'),
                      value: Detector.text,
                    ),
                    const PopupMenuItem<Detector>(
                      child: Text('Detect Cloud Text'),
                      value: Detector.cloudText,
                    ),
                  ],
            ),
          ],
        ),
        body: _imageFile == null
            ? const Center(child: Text('No image selected.'))
            : _buildImage(),
        floatingActionButton: FloatingActionButton(
          onPressed: _getAndScanImage,
          tooltip: 'Pick Image',
          child: const Icon(Icons.add_a_photo),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barcodeDetector.close();
    _faceDetector.close();
    _imageLabeler.close();
    _cloudImageLabeler.close();
    _recognizer.close();
    _cloudRecognizer.close();
    super.dispose();
  }
}

class MultiTapRecognize extends StatefulWidget {
  MultiTapRecognize({Key key, @required this.child}) : super(key: key);

  final Widget child;

  @override
  _MultiTapRecognizeState createState() {
    return _MultiTapRecognizeState();
  }
}

class _MultiTapRecognizeState extends State<MultiTapRecognize> {
  final DelayedMultiDragGestureRecognizer dragGesture =
      new DelayedMultiDragGestureRecognizer();
  Map<int, Offset> movableSelections = {};

  @override
  Widget build(BuildContext context) {
    final MediaQueryData queryData = MediaQuery.of(context);
    Scaffold child = getChild<Scaffold>(context);
    var appBarHeight = child.appBar.preferredSize.height;
    return RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          MultiTapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<MultiTapGestureRecognizer>(
                  () => MultiTapGestureRecognizer(
                      longTapDelay: Duration(seconds: 1)),
                  (MultiTapGestureRecognizer instance) {
            instance
              ..onTapDown = (int pointer, TapDownDetails details) {
                print('trigger $pointer tap down');
                dragGesture.acceptGesture(pointer);
                setState(() {
                  movableSelections[pointer] = details.globalPosition;
                });
              }
              ..onTapUp = (int pointer, TapUpDetails details) {
                print('trigger $pointer tap up');
              }
              ..onLongTapDown = (int pointer, TapDownDetails details) {
                print('trigger $pointer $details Long tap Down');
              }
              ..onTapCancel = (int pointer) {
                print('trigger $pointer Long tap Cancel');
              };
          }),
          DelayedMultiDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                  DelayedMultiDragGestureRecognizer>(
            () => DelayedMultiDragGestureRecognizer(),
            (DelayedMultiDragGestureRecognizer instance) {
              instance
                ..onStart = (Offset pointer) {
                  print('trigger ${pointer.toString()} start draggin');
                  final GestureDragUpdateCallback onUpdate =
                      (DragUpdateDetails details) {};

                  final GestureDragEndCallback endDrag =
                      (DragEndDetails details) {
                    print('Drag End $details $pointer');
                    print(movableSelections[pointer]);
                  };

                  return new ItemDrag(onUpdate, endDrag);
                };
            },
          )
        },
        child: Stack(
          children: <Widget>[
            widget.child,
            FittedBox(
                child: SizedBox(
                    width: queryData.size.width,
                    height: queryData.size.height - appBarHeight,
                    child: new Listener(
                        onPointerMove: (PointerMoveEvent event) {
                          setState(() {
                            movableSelections[event.pointer] =
                                transfromWithoutAppBar(
                                    event.position, appBarHeight);
                          });
                        },
                        onPointerUp: (PointerUpEvent event) {
                          setState(() {
                            movableSelections.remove(event.pointer);
                          });
                        },
                        child: new CustomPaint(
                          isComplex: true,
                          painter: ConstraintPainter(
                              points: movableSelections,
                              queryData: queryData,
                              context: context),
                          willChange: true,
                        ))))
          ],
        ));
  }
}

class DrawingPoints {
  Paint paint;
  Offset points;

  DrawingPoints({this.points, this.paint});
}

class ConstraintPainter extends CustomPainter {
  ConstraintPainter({this.points, this.queryData, this.context});

  final MediaQueryData queryData;

  Map<int, Offset> points;

  BuildContext context;

  final linePainter = Paint()
    ..color = Colors.red
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.butt;

  final rectPainter = Paint()
    ..color = Colors.amberAccent
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.square;

  @override
  void paint(Canvas canvas, Size size) {
    for (Offset point in points.values.toList()) {
      canvas.drawLine(Offset(0, point.dy),
          Offset(queryData.size.width * 2, point.dy), linePainter);
      canvas.drawCircle(Offset(point.dx, point.dy), 20, linePainter);
    }
    if (points.values.toList().length == 2) {
      for (var i = 0; i <= points.values.toList().length - 1; i++) {
        drawRects(i, points.values.toList(), canvas);
      }
    }
  }

  drawRects(int pos, List<Offset> points, canvas) {
    print({pos, points});

    pos > 0
        ? canvas.drawRect(
            Rect.fromPoints(Offset(points[pos - 1].dx, points[pos - 1].dy),
                Offset(queryData.size.width * 2, points[pos].dy)),
            rectPainter)
        : canvas.drawRect(
            Rect.fromPoints(Offset(0, points[pos].dy),
                Offset(points[pos + 1].dx, points[pos + 1].dy)),
            linePainter);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class ItemDrag extends Drag {
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;

  ItemDrag(this.onUpdate, this.onEnd);

  @override
  void update(DragUpdateDetails details) {
    super.update(details);
    print(details);
    onUpdate(details);
  }

  @override
  void end(DragEndDetails details) {
    super.end(details);
    onEnd(details);
  }
}

getChild<C>(BuildContext context) =>
    WrapperWidget.of(context).widget.child as C;

Offset transfromWithoutAppBar(Offset offset, double appBarOffset) =>
    Offset(offset.dx, offset.dy - appBarOffset);
//abstract class StateWithRef<U> {
//  U of<U>(BuildContext context);
//}
//
//abstract class InheritedWithRef<U> {
//  U data;
//}
//State getAppBarHeight<T extends StatefulWidget, U extends State<T>,
//            I extends InheritedWithRef<U>, Inf>(StateWithRef<T, U> state,
//    BuildContext context) =>
//    state.of<I>(context).data;
