import 'package:flutter/material.dart';

import '../../models/documents/attribute.dart';
import '../../models/documents/style.dart';
import '../../models/themes/quill_icon_theme.dart';
import '../controller.dart';

class QuillDropdownButton extends StatefulWidget {
  const QuillDropdownButton({
    required this.initialValue,
    required this.items,
    required this.rawitemsmap,
    required this.attribute,
    required this.controller,
    required this.onSelected,
    this.iconSize = 40,
    this.fillColor,
    this.suffix,
    this.hoverElevation = 1,
    this.highlightElevation = 1,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  final double iconSize;
  final Color? fillColor;
  final String? suffix;
  final double hoverElevation;
  final double highlightElevation;
  final String initialValue;
  final List<PopupMenuEntry<String>> items;
  final Map<String, int> rawitemsmap;
  final ValueChanged<String> onSelected;
  final QuillIconTheme? iconTheme;
  final Attribute attribute;
  final QuillController controller;

  @override
  _QuillDropdownButtonState<String> createState() =>
      _QuillDropdownButtonState();
}

// ignore: deprecated_member_use_from_same_package
class _QuillDropdownButtonState<T> extends State<QuillDropdownButton> {
  String _currentValue = '';

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeEditingValue);
    _currentValue = widget.initialValue;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuillDropdownButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
    }
    if (widget.initialValue != oldWidget.initialValue) {
      _currentValue = widget.initialValue;
    }
  }

  void _didChangeEditingValue() {
    setState(() => _currentValue = _getKeyName(_selectionStyle.attributes));
  }

  String _getKeyName(Map<String, Attribute> attrs) {
    if (widget.attribute.key == Attribute.size.key) {
      final attribute = attrs[widget.attribute.key];

      if (attribute == null) {
        return widget.initialValue;
      } else {
        return widget.rawitemsmap.entries
            .firstWhere((element) => element.key == attribute.value.toString(),
                orElse: () => widget.rawitemsmap.entries.first)
            .key;
      }
    }
    return widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: widget.iconSize * 1.81),
      child: RawMaterialButton(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(widget.iconTheme?.borderRadius ?? 2)),
        fillColor: widget.fillColor,
        elevation: 0,
        hoverElevation: widget.hoverElevation,
        highlightElevation: widget.hoverElevation,
        onPressed: _showMenu,
        child: _buildContent(context),
      ),
    );
  }

  void _showMenu() {
    final popupMenuTheme = PopupMenuTheme.of(context);
    final button = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomLeft(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    showMenu<String>(
      context: context,
      elevation: 4,
      initialValue: widget.initialValue,
      items: widget.items,
      position: position,
      shape: popupMenuTheme.shape,
      color: popupMenuTheme.color,
    ).then((newValue) {
      if (newValue == null) {
        return null;
      }
      if (mounted) {
        setState(() {
          _currentValue = widget.rawitemsmap.entries
              .firstWhere((element) => element.key == newValue,
                  orElse: () => widget.rawitemsmap.entries.first)
              .key;
        });
      }
      widget.onSelected(newValue);
    });
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              _currentValue.toString() +
                  (widget.suffix == null ? '' : widget.suffix!),
              style: TextStyle(
                  fontSize: widget.iconSize / 1.15,
                  color: widget.iconTheme?.iconUnselectedColor ??
                      theme.iconTheme.color)),
          const SizedBox(width: 3),
          Icon(Icons.arrow_drop_down,
              size: widget.iconSize / 1.15,
              color: widget.iconTheme?.iconUnselectedColor ??
                  theme.iconTheme.color)
        ],
      ),
    );
  }
}
