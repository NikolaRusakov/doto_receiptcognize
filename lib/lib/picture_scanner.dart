// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/painting.dart';
import 'package:random_color/random_color.dart';

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
    ImageListener imageListener = (ImageInfo info, syncCall) {
      completer.complete(Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      ));
    };
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
//    _currentLabels.blocks.asMap().map((key,value)=>value.boundingBox);
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
    return Scaffold(
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
  Map<int, MovableSelectionItem> movableSelections = {};

  @override
  Widget build(BuildContext context) {
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
              }
              ..onTapUp = (int pointer, TapUpDetails details) {
                print('trigger $pointer tap up');
              }
              ..onLongTapDown = (int pointer, TapDownDetails details) {
                print('trigger $pointer Long tap Down');
                setState(() {
                  movableSelections[pointer] =
                      MovableSelectionItem(start: details.globalPosition);
                });
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
                      (DragUpdateDetails details) {
                    print('Drag update $details');
                    setState(() {
                      movableSelections;
                    });
                  };

                  final GestureDragEndCallback endDrag =
                      (DragEndDetails details) => print('Drag End $details');

                  return new ItemDrag(onUpdate, endDrag);
                };
            },
          )
        },
        child: Stack(
          children: <Widget>[
            ...movableSelections.values.toList(),
            widget.child,
            MovableSelectionItem(start: Offset(300, 200))
          ],
        ));
  }

  void _onLongPressDragUpdate(details, BuildContext context) {
    var localTouchPosition = (context.findRenderObject() as RenderBox)
        .globalToLocal(details.globalPosition);
    print(
        '_onLongPressDragUpdate details: ${details.globalPosition} - localTouchPosition: $localTouchPosition');
  }
}

class MovableSelectionItem extends StatefulWidget {
  final Offset start;
  final Offset changes;

  MovableSelectionItem({Key key, @required this.start, this.changes})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MovableSelectionState();
}

class _MovableSelectionState extends State<MovableSelectionItem> {
  double xPosition = 500;
  double yPosition = 500;
  Color color;

  @override
  void initState() {
    color = RandomColor().randomColor();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: yPosition,
      left: xPosition,
      child: Container(
        width: 150,
        height: 150,
        color: color,
      ),
    );
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

class SelectionSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SelectionSectionState();
}

class _SelectionSectionState extends State<SelectionSection> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: 400,
        top: 400,
        child: RaisedButton(
          onPressed: () {},
          child: const Text('Enabled Button', style: TextStyle(fontSize: 20)),
        ));
  }
}

class _ImmediatePointerState extends MultiDragPointerState {
  _ImmediatePointerState(Offset initialPosition) : super(initialPosition);

  @override
  void checkForResolutionAfterMove() {
    assert(pendingDelta != null);
    if (pendingDelta.distance > kTouchSlop)
      resolve(GestureDisposition.accepted);
  }

  @override
  void accepted(GestureMultiDragStartCallback starter) {
    starter(initialPosition);
  }
}
/*gestures: <Type, GestureRecognizerFactory>{
  MultiTapRecognizer:
  GestureRecognizerFactoryWithHandlers<MultiTapRecognizer>(
  () => MultiTapRecognizer(
  onPanDown: _onPanDown,
  onPanUpdate: _onPanUpdate,
  onPanEnd: _onPanEnd),
  (MultiTapRecognizer instance) {},
  ),
  },*/

/*
class MultiTapRecognizer extends MultiTapGestureRecognizer {

  MultiTapRecognizer(
);

  @override
  void addPointer(PointerEvent event) {
    if (this.onTapDown) {
      startTrackingPointer(event.pointer);
      resolve(GestureDisposition.accepted);
    } else {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onPanUpdate(event.position);
    }
    if (event is PointerUpEvent) {
      onPanEnd(event.position);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'customPan';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}*/
