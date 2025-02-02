import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

import '../models/documents/attribute.dart';
import '../models/documents/document.dart';
import '../models/documents/nodes/embeddable.dart';
import '../models/documents/nodes/leaf.dart';
import '../models/documents/style.dart';
import '../models/quill_delta.dart';
import '../utils/delta.dart';

typedef ReplaceTextCallback = bool Function(int index, int len, Object? data);
typedef DeleteCallback = void Function(int cursorPosition, bool forward);
typedef FormatCallback = void Function(
  TextSelection selection,
  Attribute? attribute,
);

class QuillController extends ChangeNotifier {
  QuillController({
    required this.document,
    required TextSelection selection,
    bool keepStyleOnNewLine = false,
    this.onReplaceText,
    this.isSingleLine = false,
    this.onDelete,
    this.onFormat,
    this.onSelectionCompleted,
    this.onSelectionChanged,
  })  : _selection = selection,
        _keepStyleOnNewLine = keepStyleOnNewLine;

  factory QuillController.basic() {
    return QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  /// Document managed by this controller.
  final Document document;

  /// Tells whether to keep or reset the [toggledStyle]
  /// when user adds a new line.
  final bool _keepStyleOnNewLine;
  final bool isSingleLine;

  /// Currently selected text within the [document].
  TextSelection get selection => _selection;
  TextSelection _selection;

  /// Custom [replaceText] handler
  /// Return false to ignore the event
  ReplaceTextCallback? onReplaceText;

  /// Custom delete handler
  DeleteCallback? onDelete;
  FormatCallback? onFormat;

  void Function()? onSelectionCompleted;
  void Function(TextSelection textSelection)? onSelectionChanged;

  /// Store any styles attribute that got toggled by the tap of a button
  /// and that has not been applied yet.
  /// It gets reset after each format action within the [document].
  Style toggledStyle = Style();

  bool ignoreFocusOnTextChange = false;

  /// True when this [QuillController] instance has been disposed.
  ///
  /// A safety mechanism to ensure that listeners don't crash when adding,
  /// removing or listeners to this instance.
  bool _isDisposed = false;

  // item1: Document state before [change].
  //
  // item2: Change delta applied to the document.
  //
  // item3: The source of this change.
  Stream<Tuple3<Delta, Delta, ChangeSource>> get changes => document.changes;

  TextEditingValue get plainTextEditingValue => TextEditingValue(
        text: document.toPlainText(),
        selection: selection,
      );

  /// Only attributes applied to all characters within this range are
  /// included in the result.
  Style getSelectionStyle() {
    return document
        .collectStyle(selection.start, selection.end - selection.start)
        .mergeAll(toggledStyle);
  }

  Style collectStyle(int start, int end) {
    return document.collectStyle(start, end - start);
  }

  /// Returns all styles for each node within selection
  List<Tuple2<int, Style>> getAllIndividualSelectionStyles() {
    final styles = document.collectAllIndividualStyles(
        selection.start, selection.end - selection.start);
    return styles;
  }

  /// Returns plain text for each node within selection
  String getPlainText() {
    final text =
        document.getPlainText(selection.start, selection.end - selection.start);
    return text;
  }

  /// Returns all styles for any character within the specified text range.
  List<Style> getAllSelectionStyles() {
    final styles = document.collectAllStyles(
        selection.start, selection.end - selection.start)
      ..add(toggledStyle);
    return styles;
  }

  Style getAllStyles() {
    return document.collectStyle(0, document.length);
  }

  void undo() {
    final tup = document.undo();
    if (tup.item1) {
      _handleHistoryChange(tup.item2);
    }
  }

  void newLine({bool keepFormat = true}) {
    final style = getSelectionStyle();
    replaceText(
      selection.start,
      selection.end - selection.start,
      '\n',
      TextSelection.collapsed(offset: selection.start + 1),
    );
    if (keepFormat) {
      style.attributes.forEach((key, attr) {
        formatSelection(attr);
      });
    }
  }

  void _handleHistoryChange(int? len) {
    if (len! != 0) {
      // if (this.selection.extentOffset >= document.length) {
      // // cursor exceeds the length of document, position it in the end
      // updateSelection(
      // TextSelection.collapsed(offset: document.length), ChangeSource.LOCAL);
      updateSelection(
          TextSelection.collapsed(offset: selection.baseOffset + len),
          ChangeSource.LOCAL);
    } else {
      // no need to move cursor
      notifyListeners();
    }
  }

  void redo() {
    final tup = document.redo();
    if (tup.item1) {
      _handleHistoryChange(tup.item2);
    }
  }

  bool get hasUndo => document.hasUndo;

  bool get hasRedo => document.hasRedo;

  /// clear editor
  void clear() {
    replaceText(0, plainTextEditingValue.text.length - 1, '',
        const TextSelection.collapsed(offset: 0));
  }

  void replaceText(
      int index, int len, Object? data, TextSelection? textSelection,
      {bool ignoreFocus = false}) {
    assert(data is String || data is Embeddable);

    if (onReplaceText != null && !onReplaceText!(index, len, data)) {
      return;
    }

    Delta? delta;
    if (len > 0 || data is! String || data.isNotEmpty) {
      delta = document.replace(index, len, data);
      if (data is String && data.isNotEmpty) {
        final shouldRetainDelta = toggledStyle.isNotEmpty && delta.isNotEmpty;
        if (shouldRetainDelta) {
          final retainDelta = Delta()
            ..retain(index)
            ..retain(data.length, toggledStyle.toJson());
          document.compose(retainDelta, ChangeSource.LOCAL);
        }
      }
    }

    if (textSelection != null) {
      if (delta == null || delta.isEmpty) {
        _updateSelection(textSelection, ChangeSource.LOCAL);
      } else {
        final user = Delta()
          ..retain(index)
          ..insert(data)
          ..delete(len);
        final positionDelta = getPositionDelta(user, delta);
        _updateSelection(
          textSelection.copyWith(
            baseOffset: textSelection.baseOffset + positionDelta,
            extentOffset: textSelection.extentOffset + positionDelta,
          ),
          ChangeSource.LOCAL,
        );
      }
    }

    if (_keepStyleOnNewLine) {
      final style = getSelectionStyle();
      final notInlineStyle = style.attributes.values.where((s) => !s.isInline);
      toggledStyle = style.removeAll(notInlineStyle.toSet());
    } else {
      toggledStyle = Style();
    }

    if (ignoreFocus) {
      ignoreFocusOnTextChange = true;
    }
    notifyListeners();
    ignoreFocusOnTextChange = false;
  }

  /// Called in two cases:
  /// forward == false && textBefore.isEmpty
  /// forward == true && textAfter.isEmpty
  /// Android only
  /// see https://github.com/singerdmx/flutter-quill/discussions/514
  void handleDelete(int cursorPosition, bool forward) =>
      onDelete?.call(cursorPosition, forward);

  void formatTextStyle(int index, int len, Style style) {
    style.attributes.forEach((key, attr) {
      formatText(index, len, attr);
    });
  }

  void formatText(int index, int len, Attribute? attribute,
      {bool notify = true}) {
    if (len == 0 &&
        attribute!.isInline &&
        attribute.key != Attribute.link.key &&
        attribute.key != Attribute.user.key) {
      // Add the attribute to our toggledStyle.
      // It will be used later upon insertion.
      toggledStyle = toggledStyle.put(attribute);
    }

    final change = document.format(index, len, attribute);
    // Transform selection against the composed change and give priority to
    // the change. This is needed in cases when format operation actually
    // inserts data into the document (e.g. embeds).
    final adjustedSelection = selection.copyWith(
        baseOffset: change.transformPosition(selection.baseOffset),
        extentOffset: change.transformPosition(selection.extentOffset));
    if (selection != adjustedSelection) {
      _updateSelection(adjustedSelection, ChangeSource.LOCAL);
    }
    onFormat?.call(adjustedSelection, attribute);
    if (notify) {
      // ignoreFocusOnTextChange to prevent the keyboard from opening while
      // formatting (ex: white editing the text size from the bottom sheet)
      ignoreFocusOnTextChange = true;
      notifyListeners();
      ignoreFocusOnTextChange = false;
    }
  }

  void clearSelectionFormat() {
    final attrs = <Attribute>{};
    for (final style in getAllSelectionStyles()) {
      for (final attr in style.attributes.values) {
        attrs.add(attr);
      }
    }
    for (final attr in attrs) {
      formatSelection(Attribute.clone(attr, null));
    }
    toggledStyle = Style();
  }

  void formatSelection(Attribute? attribute) {
    formatText(selection.start, selection.end - selection.start, attribute);
  }

  void formatAll(Attribute? attribute, {bool notify = true}) {
    formatText(0, document.length, attribute, notify: notify);
  }

  void moveCursorToStart() {
    updateSelection(
        const TextSelection.collapsed(offset: 0), ChangeSource.LOCAL);
  }

  void moveCursorToPosition(int position) {
    updateSelection(
        TextSelection.collapsed(offset: position), ChangeSource.LOCAL);
  }

  void moveCursorToEnd() {
    updateSelection(
        TextSelection.collapsed(offset: plainTextEditingValue.text.length),
        ChangeSource.LOCAL);
  }

  void updateSelection(TextSelection textSelection, ChangeSource source) {
    _updateSelection(textSelection, source);
    notifyListeners();
  }

  void replaceSelection(String plainText) {
    final start = selection.start;
    final end = selection.end;
    final delta = Delta()
      ..retain(start)
      ..delete(end - start)
      ..insert(plainText);
    final newSelection =
        TextSelection.collapsed(offset: start + plainText.length);
    compose(delta, newSelection, ChangeSource.LOCAL);
    _updateSelection(newSelection, ChangeSource.LOCAL);
  }

  void compose(Delta delta, TextSelection textSelection, ChangeSource source,
      {bool ignoreFocus = false}) {
    if (delta.isNotEmpty) {
      document.compose(delta, source);
    }

    textSelection = selection.copyWith(
        baseOffset: delta.transformPosition(selection.baseOffset, force: false),
        extentOffset:
            delta.transformPosition(selection.extentOffset, force: false));
    if (selection != textSelection) {
      _updateSelection(textSelection, source);
    }
    if (ignoreFocus) {
      ignoreFocusOnTextChange = true;
    }
    notifyListeners();
    ignoreFocusOnTextChange = false;
  }

  @override
  void addListener(VoidCallback listener) {
    // By using `_isDisposed`, make sure that `addListener` won't be called on a
    // disposed `ChangeListener`
    if (!_isDisposed) {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    // By using `_isDisposed`, make sure that `removeListener` won't be called
    // on a disposed `ChangeListener`
    if (!_isDisposed) {
      super.removeListener(listener);
    }
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      document.close();
    }

    _isDisposed = true;
    super.dispose();
  }

  void _updateSelection(TextSelection textSelection, ChangeSource source) {
    if (document.toPlainText().startsWith(Document.zeroWidthChar) != true) {
      document.insert(0, '${Document.zeroWidthChar}');
    }

    if (textSelection.baseOffset == 0) {
      if (textSelection.isCollapsed) {
        textSelection = const TextSelection.collapsed(offset: 1);
      } else {
        textSelection = textSelection.copyWith(baseOffset: 1);
      }
    }
    _selection = textSelection;
    final end = document.length - 1;
    _selection = selection.copyWith(
        baseOffset: math.min(selection.baseOffset, end),
        extentOffset: math.min(selection.extentOffset, end));

    // Update toggled style
    if (_selection.isCollapsed) {
      final style = document.isEmpty()
          ? Style()
          : document.collectStyle(textSelection.baseOffset, 0);
      toggledStyle = Style();
      style.attributes.forEach((key, value) {
        if (value.isInline && value.key != Attribute.user.key) {
          toggledStyle = toggledStyle.merge(value);
        }
      });
    }
    onSelectionChanged?.call(textSelection);
  }

  String? getCommandWords(Iterable<String> commands) {
    for (final command in commands) {
      final result = getCommandWord(command);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  String? getCommandWord(String command) {
    if (document.isEmpty()) {
      return null;
    }
    final _linkBreak = RegExp('[\\s\n]');
    final input = plainTextEditingValue.text;
    final before = input.substring(0, max(selection.baseOffset, 0));
    final start = before.lastIndexOf(command);
    if (start == -1) {
      return null;
    }
    if (start > 1) {
      // because there is a zero w char at position 0
      if (input.substring(start - 1, start).trim().isNotEmpty) {
        return null;
      }
    }
    final after = input.substring(start);
    var len = after.indexOf(_linkBreak);
    if (len == -1) {
      len = after.length;
    }
    final query = input.substring(start, start + len);
    if (!query.startsWith(command)) {
      return null;
    }
    if (start + len < selection.baseOffset) {
      return null;
    }
    return query.replaceAll(command, '');
  }

  void removeCommandWord(String command) {
    if (document.isEmpty()) {
      return null;
    }
    final _linkBreak = RegExp('[\\s\n]');
    final input = plainTextEditingValue.text;
    final before = input.substring(0, max(selection.baseOffset, 0));
    final start = before.lastIndexOf(command);
    if (start == -1) {
      return null;
    }
    if (start > 1) {
      // because there is a zero w char at position 0
      if (input.substring(start - 1, start).trim().isNotEmpty) {
        return null;
      }
    }
    final after = input.substring(start);
    var len = after.indexOf(_linkBreak);
    if (len == -1) {
      len = after.length;
    }
    final query = input.substring(start, start + len);
    if (!query.startsWith(command)) {
      return null;
    }
    if (start + len < selection.baseOffset) {
      return null;
    }
    replaceText(start, start + len, '', TextSelection.collapsed(offset: start));
  }

  void unCollapse() {
    if (selection.isCollapsed == false) {
      updateSelection(
        TextSelection.collapsed(offset: selection.baseOffset),
        ChangeSource.LOCAL,
      );
    }
  }

  /// Given offset, find its leaf node in document
  Leaf? queryNode(int offset) {
    return document.querySegmentLeafNode(offset).item2;
  }

  void toggleAttribute(Attribute attribute) {
    final isToggled = _getIsToggled(attribute, getSelectionStyle().attributes);
    formatSelection(isToggled ? Attribute.clone(attribute, null) : attribute);
  }

  bool _getIsToggled(Attribute attr, Map<String, Attribute> attrs) {
    if (attr.key == attr.key) {
      final attribute = attrs[attr.key];
      if (attribute == null) {
        return false;
      }
      return attribute.value == attr.value;
    }
    return attrs.containsKey(attr.key);
  }

  /// Clipboard for image url and its corresponding style
  /// item1 is url and item2 is style string
  Tuple2<String, String>? _copiedImageUrl;

  Tuple2<String, String>? get copiedImageUrl => _copiedImageUrl;

  set copiedImageUrl(Tuple2<String, String>? value) {
    _copiedImageUrl = value;
    Clipboard.setData(const ClipboardData(text: ''));
  }

  // Notify toolbar buttons directly with attributes
  Map<String, Attribute> toolbarButtonToggler = {};
}
