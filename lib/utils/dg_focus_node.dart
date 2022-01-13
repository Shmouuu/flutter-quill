import 'package:flutter/widgets.dart';

class DgFocusNode extends FocusNode {
  DgFocusNode({this.isShortCuts = false, String? debugLabel})
      : super(debugLabel: debugLabel);

  final bool isShortCuts;
}
