import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../flutter_quill.dart';
import 'text_selection.dart';

typedef EmbedBuilder = Widget Function(
    BuildContext context, Embed node, bool readOnly);

typedef CustomStyleBuilder = TextStyle Function(Attribute attribute);

abstract class EditorTextSelectionGestureDetectorBuilderDelegate {
  GlobalKey<EditorState> getEditableTextKey();

  bool getForcePressEnabled();

  bool getSelectionEnabled();
}

class EditorTextSelectionGestureDetectorBuilder {
  EditorTextSelectionGestureDetectorBuilder(this.delegate, this.listener);

  final EditorTextSelectionGestureDetectorBuilderDelegate delegate;
  final EditorGestureListener? listener;
  bool shouldShowSelectionToolbar = true;

  EditorState? getEditor() {
    return delegate.getEditableTextKey().currentState;
  }

  RenderEditor? getRenderEditor() {
    return getEditor()!.getRenderEditor();
  }

  void onTapDown(TapDownDetails details) {
    getRenderEditor()!.handleTapDown(details);

    final kind = details.kind;
    shouldShowSelectionToolbar = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;
  }

  void onForcePressStart(ForcePressDetails details) {
    assert(delegate.getForcePressEnabled());
    shouldShowSelectionToolbar = true;
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectWordsInRange(
        details.globalPosition,
        null,
        SelectionChangedCause.forcePress,
      );
    }
  }

  void onForcePressEnd(ForcePressDetails details) {
    assert(delegate.getForcePressEnabled());
    getRenderEditor()!.selectWordsInRange(
      details.globalPosition,
      null,
      SelectionChangedCause.forcePress,
    );
    if (shouldShowSelectionToolbar) {
      getEditor()!.showToolbar();
    }
  }

  void onSingleTapUp(TapUpDetails details) {
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectWordEdge(SelectionChangedCause.tap);
    }
  }

  void onSingleTapCancel() {}

  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    }
  }

  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    }
  }

  void onSingleLongTapEnd(LongPressEndDetails details) {
    if (shouldShowSelectionToolbar) {
      getEditor()!.showToolbar();
    }
  }

  void onDoubleTapDown(TapDownDetails details) {
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectWord(SelectionChangedCause.tap);
      if (shouldShowSelectionToolbar) {
        getEditor()!.showToolbar();
      }
    }
  }

  void onDragSelectionStart(DragStartDetails details) {
    getRenderEditor()!.handleDragStart(details);
    listener?.onDragSelectionStart(details);
  }

  void onDragSelectionUpdate(
      DragStartDetails startDetails, DragUpdateDetails updateDetails) {
    getRenderEditor()!.extendSelection(updateDetails.globalPosition,
        cause: SelectionChangedCause.drag);
    listener?.onDragSelectionUpdate(updateDetails);
  }

  void onDragSelectionEnd(DragEndDetails details) {
    getRenderEditor()!.handleDragEnd(details);
    listener?.onDragSelectionEnd(details);
  }

  Widget build(HitTestBehavior behavior, Widget child) {
    return EditorTextSelectionGestureDetector(
      onTapDown: onTapDown,
      onForcePressStart:
          delegate.getForcePressEnabled() ? onForcePressStart : null,
      onForcePressEnd: delegate.getForcePressEnabled() ? onForcePressEnd : null,
      onSingleTapUp: onSingleTapUp,
      onSingleTapCancel: onSingleTapCancel,
      onSingleLongTapStart: onSingleLongTapStart,
      onSingleLongTapMoveUpdate: onSingleLongTapMoveUpdate,
      onSingleLongTapEnd: onSingleLongTapEnd,
      onDoubleTapDown: onDoubleTapDown,
      onDragSelectionStart: onDragSelectionStart,
      onDragSelectionUpdate: onDragSelectionUpdate,
      onDragSelectionEnd: onDragSelectionEnd,
      behavior: behavior,
      child: child,
    );
  }
}

class EditorGestureListener {
  void onDragSelectionStart(DragStartDetails details) {}

  void onDragSelectionUpdate(DragUpdateDetails updateDetails) {}

  void onDragSelectionEnd(DragEndDetails details) {}
}
