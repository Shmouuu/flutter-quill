import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/documents/attribute.dart';
import '../../models/documents/style.dart';
import '../../models/themes/quill_icon_theme.dart';
import '../controller.dart';
import '../toolbar.dart';

final headerToString = <String>['N', 'H1', 'H2', 'H3'];

class SelectHeaderStyleButton extends StatefulWidget {
  const SelectHeaderStyleButton({
    required this.controller,
    this.iconSize = kDefaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  final QuillController controller;
  final double iconSize;

  final QuillIconTheme? iconTheme;

  @override
  _SelectHeaderStyleButtonState createState() =>
      _SelectHeaderStyleButtonState();
}

class _SelectHeaderStyleButtonState extends State<SelectHeaderStyleButton> {
  Attribute? _value;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    setState(() {
      _value = _getHeaderValue();
    });
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  Widget build(BuildContext context) {
    final _valueToText = <Attribute, String>{
      Attribute.header: 'N',
      Attribute.h1: 'H1',
      Attribute.h2: 'H2',
      Attribute.h3: 'H3',
    };

    final _valueAttribute = <Attribute>[
      Attribute.header,
      Attribute.h1,
      Attribute.h2,
      Attribute.h3
    ];

    final theme = Theme.of(context);
    final style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: widget.iconSize * 0.7,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Padding(
          // ignore: prefer_const_constructors
          padding: EdgeInsets.symmetric(horizontal: !kIsWeb ? 1.0 : 5.0),
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: widget.iconSize * kIconButtonFactor,
              height: widget.iconSize * kIconButtonFactor,
            ),
            child: RawMaterialButton(
              hoverElevation: 0,
              highlightElevation: 0,
              elevation: 0,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      widget.iconTheme?.borderRadius ?? 2)),
              fillColor: _valueToText[_value] == headerToString[index]
                  ? (widget.iconTheme?.iconSelectedFillColor ??
                      theme.toggleableActiveColor)
                  : (widget.iconTheme?.iconUnselectedFillColor ??
                      theme.canvasColor),
              onPressed: () {
                widget.controller.formatSelection(SizeAttribute(null));
                widget.controller.formatSelection(_valueAttribute[index]);
              },
              child: Text(
                headerToString[index],
                style: style.copyWith(
                  color: _valueToText[_value] == headerToString[index]
                      ? (widget.iconTheme?.iconSelectedColor ??
                          theme.primaryIconTheme.color)
                      : (widget.iconTheme?.iconUnselectedColor ??
                          theme.iconTheme.color),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _didChangeEditingValue() {
    setState(() {
      _value = _getHeaderValue();
    });
  }

  Attribute<dynamic> _getHeaderValue() {
    final attr = widget.controller.toolbarButtonToggler[Attribute.header.key];
    if (attr != null) {
      // checkbox tapping causes controller.selection to go to offset 0
      widget.controller.toolbarButtonToggler.remove(Attribute.header.key);
      return attr;
    }
    return _selectionStyle.attributes[Attribute.header.key] ?? Attribute.header;
  }

  @override
  void didUpdateWidget(covariant SelectHeaderStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _value = _getHeaderValue();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }
}
