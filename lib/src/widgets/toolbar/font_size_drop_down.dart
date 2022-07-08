import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../flutter_quill.dart' hide Text;

class FontSizeDropDown extends StatefulWidget {
  const FontSizeDropDown({
    required this.controller,
    required this.fontSizeBehavior,
    this.iconSize = kDefaultIconSize,
    this.iconTheme,
    this.fontSizeValues,
    Key? key,
  }) : super(key: key);

  final QuillController controller;
  final double iconSize;
  final FontSizeBehavior fontSizeBehavior;

  final QuillIconTheme? iconTheme;
  final Map<String, int>? fontSizeValues;

  @override
  _FontSizeDropDownState createState() => _FontSizeDropDownState();
}

const int minFontSize = 8;
const int maxFontSize = 128;

class _FontSizeDropDownState extends State<FontSizeDropDown> {
  late final fontSizes = widget.fontSizeValues ??
      {
        '8': minFontSize,
        '10': 10,
        '12': 12,
        '14': 14,
        '16': 0,
        '18': 18,
        '20': 20,
        '24': 24,
        '28': 28,
        '32': 32,
        '36': 36,
        '40': 40,
        '48': 48,
        '64': 64,
        '96': 96,
        '128': maxFontSize,
      };

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  Widget build(BuildContext context) {
    //default font size values
    final suffix =
        widget.fontSizeBehavior == FontSizeBehavior.proportional ? '*' : '';
    final initialFontSizeValue = _getFontSizeIndex(fontSizes);
    return QuillDropdownButton(
      iconTheme: widget.iconTheme,
      iconSize: widget.iconSize,
      attribute: Attribute.size,
      controller: widget.controller,
      suffix: suffix,
      items: [
        for (MapEntry<String, int> fontSize in fontSizes.entries)
          PopupMenuItem<int>(
            key: ValueKey(fontSize.key),
            value: fontSize.value,
            child: Text(fontSize.key.toString() + suffix),
          ),
      ],
      onSelected: (newSize) {
        if ((newSize != null) && (newSize as int > 0)) {
          widget.controller
              .formatSelection(Attribute.fromKeyValue('size', newSize));
        }
        if (newSize as int == 0) {
          widget.controller
              .formatSelection(Attribute.fromKeyValue('size', null));
        }
      },
      rawitemsmap: fontSizes,
      initialValue: initialFontSizeValue,
    );
  }

  static List<TextStyle?> _getHeaderStyles(BuildContext context) {
    final defaultStyles = DefaultStyles.getInstance(context);
    return [
      const TextStyle(fontSize: 16),
      defaultStyles.h1?.style,
      defaultStyles.h2?.style,
      defaultStyles.h3?.style,
    ];
  }

  void _didChangeEditingValue() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  int _getFontSizeIndex(Map<String, int> fontSizes) {
    final value = widget.controller
            .getAllStyles()
            .attributes
            .values
            .firstWhereOrNull((e) => e.key == Attribute.size.key)
            ?.value ??
        '';
    final customFontSize =
        int.tryParse(value is String ? value : value.toString());
    if (customFontSize != null) {
      final key = customFontSize.toString();
      if (!fontSizes.containsKey(key)) {
        fontSizes[key] = customFontSize;
      }
      return fontSizes.values.toList().indexOf(customFontSize);
    } else {
      final int? level = widget.controller
          .getAllStyles()
          .attributes
          .values
          .firstWhereOrNull((e) => e.key == Attribute.header.key)
          ?.value;
      if (level != null) {
        final fontSize = _getHeaderStyles(context)[level]!.fontSize!.toInt();
        final key = fontSize.toString();
        if (!fontSizes.containsKey(key)) {
          fontSizes[key] = fontSize;
        }
        return fontSizes.values.toList().indexOf(fontSize);
      }
    }
    return fontSizes.values.toList().indexOf(0);
  }
}
