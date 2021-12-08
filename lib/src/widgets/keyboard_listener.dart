import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

//fixme workaround flutter MacOS issue https://github.com/flutter/flutter/issues/75595
extension _LogicalKeyboardKeyCaseExt on LogicalKeyboardKey {
  static const _kUpperToLowerDist = 0x20;
  static final _kLowerCaseA = LogicalKeyboardKey.keyA.keyId;
  static final _kLowerCaseZ = LogicalKeyboardKey.keyZ.keyId;

  LogicalKeyboardKey toUpperCase() {
    if (keyId < _kLowerCaseA || keyId > _kLowerCaseZ) return this;
    return LogicalKeyboardKey(keyId - _kUpperToLowerDist);
  }
}

enum InputShortcut {
  CUT,
  COPY,
  PASTE,
  SELECT_ALL,
  UNDO,
  REDO,
  BOLD,
  ITALIC,
  UNDERLINE,
  NEW_LINE,
  NEW_TEXT,
}

typedef CursorMoveCallback = void Function(
    LogicalKeyboardKey key, bool wordModifier, bool lineModifier, bool shift);
typedef InputShortcutCallback = void Function(InputShortcut? shortcut);
typedef OnDeleteCallback = void Function(bool forward);
typedef OnNewLineCallback = void Function();

class KeyboardEventHandler {
  KeyboardEventHandler(
    this.onCursorMove,
    this.onShortcut,
    this.onDelete,
  );

  final CursorMoveCallback onCursorMove;
  final InputShortcutCallback onShortcut;
  final OnDeleteCallback onDelete;

  static final Set<LogicalKeyboardKey> _moveKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
  };

  static final Map<LogicalKeyboardKey, InputShortcut> _ctrlKeyToShortcut = {
    LogicalKeyboardKey.keyX: InputShortcut.CUT,
    LogicalKeyboardKey.keyC: InputShortcut.COPY,
    LogicalKeyboardKey.keyV: InputShortcut.PASTE,
    LogicalKeyboardKey.keyA: InputShortcut.SELECT_ALL,
    LogicalKeyboardKey.keyB: InputShortcut.BOLD,
    LogicalKeyboardKey.keyI: InputShortcut.ITALIC,
    LogicalKeyboardKey.keyU: InputShortcut.UNDERLINE,
  };

  static final Map<LogicalKeyboardKey, InputShortcut> _shiftKeyToShortcut = {
    LogicalKeyboardKey.enter: InputShortcut.NEW_LINE,
  };

  static final Map<LogicalKeyboardKey, InputShortcut> _webKeyToShortcut = {
    LogicalKeyboardKey.enter: InputShortcut.NEW_TEXT,
    LogicalKeyboardKey.numpadEnter: InputShortcut.NEW_TEXT,
  };

  KeyEventResult handleRawKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isMacOS = event.data is RawKeyEventDataMacOs;
    final isCtrlPressed =
        isMacOS ? event.isMetaPressed : event.isControlPressed;
    final isShiftPressed = event.isShiftPressed;

    if (isCtrlPressed && _ctrlKeyToShortcut.containsKey(key)) {
      onShortcut(_ctrlKeyToShortcut[key]);
      return KeyEventResult.handled;
    }

    if (isShiftPressed && _shiftKeyToShortcut.containsKey(key)) {
      onShortcut(_shiftKeyToShortcut[key]);
      return KeyEventResult.handled;
    }

    if (_webKeyToShortcut.containsKey(key)) {
      onShortcut(_webKeyToShortcut[key]);
      return KeyEventResult.handled;
    }

    if (kIsWeb) {
      // On web platform, we ignore the key because it's already processed.
      return KeyEventResult.ignored;
    }

    if (_moveKeys.contains(key)) {
      onCursorMove(
          key,
          isMacOS ? event.isAltPressed : event.isControlPressed,
          isMacOS ? event.isMetaPressed : event.isAltPressed,
          event.isShiftPressed);
    } else if (isCtrlPressed && _ctrlKeyToShortcut.containsKey(key)) {
      if (key == LogicalKeyboardKey.keyZ ||
          key == LogicalKeyboardKey.keyZ.toUpperCase()) {
        onShortcut(
            event.isShiftPressed ? InputShortcut.REDO : InputShortcut.UNDO);
      } else {
        onShortcut(_ctrlKeyToShortcut[key]);
      }
    } else if (key == LogicalKeyboardKey.delete) {
      onDelete(true);
    } else if (key == LogicalKeyboardKey.backspace) {
      onDelete(false);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}
