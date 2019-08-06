// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:doto_receiptcognize/lib/multi_touch_gesture_recognizer.dart';
import 'package:doto_receiptcognize/multi_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:doto_receiptcognize/lib/camera_preview_scanner.dart';
import 'package:doto_receiptcognize/lib/material_barcode_scanner.dart';
import 'package:doto_receiptcognize/lib/picture_scanner.dart';

void main() {
//  debugPrintGestureArenaDiagnostics = true;
  debugPrintGestureArenaDiagnostics = true;
  runApp(
    MaterialApp(
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => _ExampleList(),
        '/$PictureScanner': (BuildContext context) => PictureScanner(),
        '/$CameraPreviewScanner': (BuildContext context) =>
            CameraPreviewScanner(),
        '/$MaterialBarcodeScanner': (BuildContext context) =>
            const MaterialBarcodeScanner(),
      },
    ),
  );
}

class _ExampleList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ExampleListState();
}

class _ExampleListState extends State<_ExampleList> {
  static final List<String> _exampleWidgetNames = <String>[
    '$PictureScanner',
    '$CameraPreviewScanner',
    '$MaterialBarcodeScanner',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example List'),
      ),
      body: ListView.builder(
        itemCount: _exampleWidgetNames.length,
        itemBuilder: (BuildContext context, int index) {
          final String widgetName = _exampleWidgetNames[index];

          return Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: ListTile(
              title: Text(widgetName),
              onTap: () => Navigator.pushNamed(context, '/$widgetName'),
            ),
          );
        },
      ),
    );
  }
}
