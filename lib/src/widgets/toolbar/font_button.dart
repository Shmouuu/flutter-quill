import 'package:flutter/material.dart';

import '../../models/documents/attribute.dart';
import '../../models/documents/style.dart';
import '../../models/themes/quill_icon_theme.dart';
import '../controller.dart';
import '../toolbar.dart';
import 'font_picker_dialog.dart';

/// Controls color styles.
///
/// When pressed, this button displays overlay toolbar with
/// buttons for each color.
class FontButton extends StatefulWidget {
  const FontButton({
    required this.icon,
    required this.controller,
    this.iconSize = kDefaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final double iconSize;
  final QuillController controller;
  final QuillIconTheme? iconTheme;

  @override
  _FontButtonState createState() => _FontButtonState();
}

class _FontButtonState extends State<FontButton> {
  late FontAttribute? _attribute;
  bool get _isToggled => _attribute != null;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _attribute =
          _getIsToggledFont(widget.controller.getSelectionStyle().attributes);
    });
  }

  @override
  void initState() {
    super.initState();
    _attribute = _getIsToggledFont(_selectionStyle.attributes);
    widget.controller.addListener(_didChangeEditingValue);
  }

  FontAttribute? _getIsToggledFont(Map<String, Attribute> attrs) {
    final attr = attrs[Attribute.font.key];
    return attr is FontAttribute? ? attr : null;
  }

  @override
  void didUpdateWidget(covariant FontButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _attribute = _getIsToggledFont(_selectionStyle.attributes);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _isToggled
        ? (widget.iconTheme?.iconSelectedColor ??
            theme.primaryIconTheme.color) //You can specify your own icon color
        : (widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color);
    final fill = _isToggled
        ? (widget.iconTheme?.iconSelectedFillColor ??
            theme.toggleableActiveColor) //Selected icon fill color
        : (widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor); //

    return QuillIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * kIconButtonFactor,
      icon: Icon(widget.icon, size: widget.iconSize, color: iconColor),
      fillColor: fill,
      onPressed: _showFontPicker,
    );
  }

  void _showFontPicker() {
    showDialog(
      context: context,
      builder: (context) => FontPickerDialog(
        fontFamily: _attribute?.value,
        onChanged: _onChanged,
      ),
    );
  }

  void _onChanged(String? value) {
    widget.controller.formatSelection(FontAttribute(value));
  }
}
