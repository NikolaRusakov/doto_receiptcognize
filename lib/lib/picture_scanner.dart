import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:doto_receiptcognize/main.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'bloc/bloc/bloc.dart';
import 'bloc/bloc/detected_text_bloc.dart';
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

  DetectedTextBloc _detectedTextBloc;

  @override
  void initState() {
    super.initState();
    _detectedTextBloc = BlocProvider.of<DetectedTextBloc>(context);
  }

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
    VisionText _currentText;
    _currentText = results;
    print(_currentText.blocks.asMap());
    for (var text in _currentText.blocks) {
      print("text : ${text.text}");
    }
    setState(() {
      _scanResults = results;
      final MediaQueryData screenSize = MediaQuery.of(context);
      final double scaleX = screenSize.size.width / _imageSize.width;
      final double scaleY = screenSize.size.height / _imageSize.height;
      List<double> screen = [scaleX, scaleY];
      _detectedTextBloc
          .dispatch(SaveDetectedText(text: _currentText, screen: screen));
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

  Widget _buildImage({size: Size}) {
    return MultiTapRecognize(
        size: size,
        child:Stack(
            children: [
        Container(
            constraints: const BoxConstraints.expand(),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: Image.file(
                  _imageFile,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                ).image,
                fit: BoxFit.fitHeight,
              ),
            ),
            child:  _imageSize == null || _scanResults == null
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
              )
            ]));
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
            : _buildImage(size: _imageSize),
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
  MultiTapRecognize({Key key, @required this.child, @required this.size})
      : super(key: key);

  final Widget child;
  final Size size;

  @override
  _MultiTapRecognizeState createState() {
    return _MultiTapRecognizeState();
  }
}

class _MultiTapRecognizeState extends State<MultiTapRecognize> {
  final DelayedMultiDragGestureRecognizer dragGesture =
      new DelayedMultiDragGestureRecognizer();
  Map<int, Offset> movableSelections = {};
  Map<int, Rect> rectSelections = {};
  VisionText _visionText;

  DetectedTextBloc _detectedTextBloc;

  @override
  void initState() {
    super.initState();
    _detectedTextBloc = BlocProvider.of<DetectedTextBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData queryData = MediaQuery.of(context);

    Scaffold child = getChild<Scaffold>(context);
    var appBarHeight = child.appBar.preferredSize.height;

    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        MultiTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                MultiTapGestureRecognizer>(
            () => MultiTapGestureRecognizer(longTapDelay: Duration(seconds: 1)),
            (MultiTapGestureRecognizer instance) {
          instance
            ..onTapDown = (int pointer, TapDownDetails details) {
              print('trigger $pointer tap down');
              dragGesture.acceptGesture(pointer);
              setState(() {
                movableSelections[pointer] = transformWithoutAppBar(
                    details.globalPosition, appBarHeight);
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
        DelayedMultiDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
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
      child: Stack(children: <Widget>[
        widget.child,
        Container(
            constraints: const BoxConstraints.expand(),
            child: MultiBlocListener(
                listeners: [
                  BlocListener<DetectedTextBloc, DetectedTextState>(
                    listener: (context, state) {
                      print(state);
//                      if(state is DetectedTextStateSuccess)
//                      _visionText = state as VisionText;
                    },
                  )
                ],
                child: Listener(
                    onPointerMove: (PointerMoveEvent event) {
                      setState(() {
                        movableSelections[event.pointer] =
                            transformWithoutAppBar(
                                event.position, appBarHeight);
                      });
                    },
                    onPointerUp: (PointerUpEvent event) {
                      setState(() {
                        movableSelections.remove(event.pointer);
//                        #TODO  print(_detectedTextBloc.currentState);
                        print(_visionText);
//                        _detectedTextBloc.dispatch(SaveDetectedText(text: _visionText));
                        _detectedTextBloc.dispatch(CheckForIntersection(
                            rectangle: rectSelections.values.toList()[0]));
                      });
                    },
                    child: new CustomPaint(
                      isComplex: true,
                      painter: ConstraintPainter(
                          points: movableSelections,
                          queryData: queryData,
                          imageSize: widget.size,
                          context: context,
                          onPaintRectangles: (List<Rect> rectangles) {
                            rectSelections = rectangles
                                .asMap()
                                .map((index, rect) => MapEntry(index, rect));
                          }),
                      willChange: true,
                    )))),
      ]),
    );
  }
}

class DrawingPoints {
  Paint paint;
  Offset points;

  DrawingPoints({this.points, this.paint});
}

typedef onPaintRectangleCallBack = void Function(List<Offset> points);

class ConstraintPainter extends CustomPainter {
  ConstraintPainter(
      {this.points,
      this.queryData,
      this.context,
      this.imageSize,
      @required this.onPaintRectangles});

  final onPaintRectangles;
  final MediaQueryData queryData;
  final Size imageSize;

  Map<int, Offset> points;

  BuildContext context;

  final linePainter = Paint()
    ..color = Colors.red
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.butt;

  final rectPainter = (BlendMode blend, Color col) => Paint()
    ..color = col
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.square
    ..blendMode = blend;

  @override
  void paint(Canvas canvas, Size size) {
    List<Offset> pointsList = points.values.toList();
    for (Offset point in pointsList) {
      canvas.drawLine(Offset(0, point.dy),
          Offset(queryData.size.width, point.dy), linePainter);
      canvas.drawCircle(Offset(point.dx, point.dy), 20, linePainter);
    }
    if (pointsList.length == 2) {
      List<Rect> rectangles = [];
//      for (var i = 0; i <= pointsList.length - 1; i++) {
//        rectangles.add(drawRect(i, pointsList, canvas));
      rectangles.add(drawDetectRect(pointsList, canvas));
//        print(rect);
//      }
      onPaintRectangles(rectangles);
    }
  }

  Rect drawDetectRect(List<Offset> points, canvas) {
    Rect rectangle = Rect.fromPoints(points[0], points[1]);
    canvas.drawRect(
        rectangle, rectPainter(BlendMode.hardLight, Colors.blueAccent));
    return rectangle;
  }

  Rect drawRect(int pos, List<Offset> points, canvas) {
    Rect right() => Rect.fromPoints(
        Offset(points[pos - 1].dx, points[pos - 1].dy),
        Offset(queryData.size.width, points[pos].dy));
    Rect left() => Rect.fromPoints(Offset(0, points[pos].dy),
        Offset(points[pos + 1].dx, points[pos + 1].dy));
    if (pos > 0) {
      var returnRect = right();
      canvas.drawRect(
          returnRect, rectPainter(BlendMode.hardLight, Colors.blueAccent));
      return returnRect;
    } else {
      var returnRect = left();

      canvas.drawRect(
          returnRect, rectPainter(BlendMode.softLight, Colors.yellowAccent));
      return returnRect;
    }
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

Offset transformWithoutAppBar(Offset offset, double appBarOffset) =>
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
