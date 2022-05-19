import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../utils/dg_focus_node.dart';
import '../../models/documents/attribute.dart';
import '../../models/documents/style.dart';
import '../../models/themes/quill_icon_theme.dart';
import '../../translations/toolbar.i18n.dart';
import '../../utils/color.dart';
import '../color_picker_dialog.dart';
import '../controller.dart';
import '../toolbar.dart';

/// Controls color styles.
///
/// When pressed, this button displays overlay toolbar with
/// buttons for each color.
class ColorButton extends StatefulWidget {
  const ColorButton({
    required this.icon,
    required this.controller,
    required this.background,
    required this.showTitle,
    this.iconSize = kDefaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final double iconSize;
  final bool background;
  final bool showTitle;
  final QuillController controller;
  final QuillIconTheme? iconTheme;

  @override
  _ColorButtonState createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton> {
  late bool _isToggledColor;
  late bool _isToggledBackground;
  late bool _isWhite;
  late bool _isWhiteBackground;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggledColor =
          _getIsToggledColor(widget.controller.getSelectionStyle().attributes);
      _isToggledBackground = _getIsToggledBackground(
          widget.controller.getSelectionStyle().attributes);
      _isWhite = _isToggledColor &&
          _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhiteBackground = _isToggledBackground &&
          _selectionStyle.attributes['background']!.value == '#ffffff';
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
    _isToggledBackground = _getIsToggledBackground(_selectionStyle.attributes);
    _isWhite = _isToggledColor &&
        _selectionStyle.attributes['color']!.value == '#ffffff';
    _isWhiteBackground = _isToggledBackground &&
        _selectionStyle.attributes['background']!.value == '#ffffff';
    widget.controller.addListener(_didChangeEditingValue);
  }

  bool _getIsToggledColor(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.color.key);
  }

  bool _getIsToggledBackground(Map<String, Attribute> attrs) {
    return attrs.containsKey(Attribute.background.key);
  }

  @override
  void didUpdateWidget(covariant ColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
      _isToggledBackground =
          _getIsToggledBackground(_selectionStyle.attributes);
      _isWhite = _isToggledColor &&
          _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhiteBackground = _isToggledBackground &&
          _selectionStyle.attributes['background']!.value == '#ffffff';
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
    final fillColor = _isToggledColor && !widget.background && _isWhite
        ? stringToColor('#ffffff')
        : (widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor);
    final fillColorBackground =
        _isToggledBackground && widget.background && _isWhiteBackground
            ? stringToColor('#ffffff')
            : (widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor);

    return QuillIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * kIconButtonFactor,
      icon:
          Icon(widget.icon, size: widget.iconSize, color: _getIconColor(theme)),
      fillColor: widget.background ? fillColorBackground : fillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: _showColorPicker,
    );
  }

  Color _getIconColor(ThemeData theme) {
    if (widget.background) {
      return (_isToggledBackground &&
                  widget.background &&
                  !_isWhiteBackground &&
                  _selectionStyle.attributes.containsKey('background')
              ? stringToColor(_selectionStyle.attributes['background']!.value)
              : (widget.iconTheme?.iconUnselectedColor ??
                  theme.iconTheme.color)) ??
          Colors.black;
    }
    return (_isToggledColor &&
                !widget.background &&
                !_isWhite &&
                _selectionStyle.attributes.containsKey('color')
            ? stringToColor(_selectionStyle.attributes['color']!.value)
            : (widget.iconTheme?.iconUnselectedColor ??
                theme.iconTheme.color)) ??
        Colors.black;
  }

  void _changeColor(Color color) {
    var hex = color.value.toRadixString(16);
    if (hex.startsWith('ff')) {
      hex = hex.substring(2);
    }
    hex = '#$hex';
    widget.controller.formatSelection(
        widget.background ? BackgroundAttribute(hex) : ColorAttribute(hex));
  }

  Future<void> _showColorPicker() async {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context)
          .requestFocus(DgBsFocusNode(debugLabel: 'ColorButton'));
    });
    var color = _getIconColor(Theme.of(context));
    await showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        title: widget.showTitle ? Text('Select Color'.i18n) : null,
        color: color,
        onChanged: (c, fromMaterial) => color = c,
      ),
    );
    _changeColor(color);
  }
}
