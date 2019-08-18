import 'package:bloc/bloc.dart';
import 'package:doto_receiptcognize/lib/bloc/bloc/bloc.dart';
import 'package:doto_receiptcognize/lib/bloc/bloc_delegate.dart';
import 'package:doto_receiptcognize/lib/camera_preview_scanner.dart';
import 'package:doto_receiptcognize/lib/material_barcode_scanner.dart';
import 'package:doto_receiptcognize/lib/picture_scanner.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

AppBar appBar = AppBar(
  title: Text('Receiptgocnizer'),
);

void main() {
//  debugPrintGestureArenaDiagnostics = true;
  debugPrintGestureArenaDiagnostics = true;
  BlocSupervisor.delegate = SimpleBlocDelegate();
  runApp(
    MultiBlocProvider(
        providers: [
//          BlocProvider<AuthenticationBloc>(bloc: _authenticationBloc),
          BlocProvider<DetectedTextBloc>(
        builder: (BuildContext context) => DetectedTextBloc()),
//          BlocProvider<GoogleLoginBloc>(
//              bloc: _googleLoginBloc),
        ],
        child: MaterialApp(
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => _ExampleList(),
            '/$PictureScanner': (BuildContext context) => PictureScanner(),
            '/$CameraPreviewScanner': (BuildContext context) =>
                CameraPreviewScanner(),
            '/$MaterialBarcodeScanner': (BuildContext context) =>
                const MaterialBarcodeScanner(),
          },
        )),
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
    return WrapperWidget(
        child: Scaffold(
      appBar: appBar,
      body:
          /*BlocProvider<DetectedTextBloc>(
            builder: (context) => DetectedTextBloc(),
            child: */
          ListView.builder(
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
    ));
  }
}

class EntryWidget extends InheritedWidget {
  EntryWidget({
    Key key,
    @required Widget child,
    @required this.data,
  }) : super(key: key, child: child);

  final WrapperWidgetState data;

  get widget {
    return child;
  }

  @override
  bool updateShouldNotify(EntryWidget oldWidget) {
    return true;
  }
}

class WrapperWidget extends StatefulWidget {
  WrapperWidget({
    Key key,
    @required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  WrapperWidgetState createState() => new WrapperWidgetState();

  static Size ofAppBar(BuildContext context) {
    return appBar.preferredSize;
  }

  static WrapperWidgetState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(EntryWidget) as EntryWidget)
        .data;
  }
}

class WrapperWidgetState extends State<WrapperWidget> {
  @override
  Widget build(BuildContext context) {
    return new EntryWidget(
      child: widget.child,
      data: this,
    );
  }
}
