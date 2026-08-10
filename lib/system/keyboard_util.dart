// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// * @Author: chuxiong
/// * @Created at: 2022/2/24 2:32 下午
/// * @Email:
/// * description

class KeyBoardUtils {
  KeyBoardUtils._();

  /// Closes the on-screen keyboard by releasing focus.
  ///
  /// Previously this also called
  /// `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive)`, which
  /// hid the status and navigation bars as a side effect of closing the
  /// keyboard. That system-UI manipulation has been removed; if the caller
  /// wants to hide system UI it should do so explicitly via [SystemUtils].
  static void closeKeyBoard(BuildContext context, {FocusNode? focusNode}) {
    if (focusNode != null) {
      focusNode.unfocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  ///isCapsLock 是否键盘锁定 CapsLock键，大写
  static String analysisKeyEvent(KeyEvent event) {
    // 不能和下面面代码合并，有时会返回两次enter
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey.keyLabel == LogicalKeyboardKey.select.keyLabel) {
      return "";
    }
    bool isNotEnterOrSelect = event.logicalKey != LogicalKeyboardKey.enter ||
        event.logicalKey.keyLabel != LogicalKeyboardKey.select.keyLabel;
    if (event.logicalKey.keyId > 255 && isNotEnterOrSelect) {
      return "";
    }
    // 1.首先从event.character判断，如果返回空，再从map中取值
    if (event.character != null && event.character!.isNotEmpty) {
      return event.character!;
    }
    // 2.以下情况为event.character返回之为空，则从map中取值
    final physicalKey = event.physicalKey;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    // 2.1 如果返回shift键说明是大写字符，从shiftPressedKeyEventMap中取值
    if (isShiftPressed) {
      final value = _shiftPressedKeyEventMap[physicalKey];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    // 2.2未返回shift键说明接下来返回的字符不是大写，从normalKeyEventMap中取值
    if (isShiftPressed == false) {
      final value = _normalKeyEventMap[physicalKey];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    // 2.3 执行以下代码，说明使用event.physicalKey未从map中取到值
    final keyLabel = event.logicalKey.keyLabel;
    final numValue = _numKeyEventMap[keyLabel];
    if (numValue != null && numValue.isNotEmpty) {
      return numValue;
    }
    return "";
  }
}

/// 未按shift和capsLock大写锁定键的字符集合map
Map<PhysicalKeyboardKey, String> _normalKeyEventMap = {
  PhysicalKeyboardKey.backquote: '`',
  PhysicalKeyboardKey.digit1: '1',
  PhysicalKeyboardKey.digit2: '2',
  PhysicalKeyboardKey.digit3: '3',
  PhysicalKeyboardKey.digit4: '4',
  PhysicalKeyboardKey.digit5: '5',
  PhysicalKeyboardKey.digit6: '6',
  PhysicalKeyboardKey.digit7: '7',
  PhysicalKeyboardKey.digit8: '8',
  PhysicalKeyboardKey.digit9: '9',
  PhysicalKeyboardKey.digit0: '0',
  PhysicalKeyboardKey.minus: '-',
  PhysicalKeyboardKey.equal: '=',
  PhysicalKeyboardKey.keyQ: 'q',
  PhysicalKeyboardKey.keyW: 'w',
  PhysicalKeyboardKey.keyE: 'e',
  PhysicalKeyboardKey.keyR: 'r',
  PhysicalKeyboardKey.keyT: 't',
  PhysicalKeyboardKey.keyY: 'y',
  PhysicalKeyboardKey.keyU: 'u',
  PhysicalKeyboardKey.keyI: 'i',
  PhysicalKeyboardKey.keyO: 'o',
  PhysicalKeyboardKey.keyP: 'p',
  PhysicalKeyboardKey.bracketLeft: '[',
  PhysicalKeyboardKey.bracketRight: ']',
  PhysicalKeyboardKey.backslash: r'\',
  PhysicalKeyboardKey.keyA: 'a',
  PhysicalKeyboardKey.keyS: 's',
  PhysicalKeyboardKey.keyD: 'd',
  PhysicalKeyboardKey.keyF: 'f',
  PhysicalKeyboardKey.keyG: 'g',
  PhysicalKeyboardKey.keyH: 'h',
  PhysicalKeyboardKey.keyJ: 'j',
  PhysicalKeyboardKey.keyK: 'k',
  PhysicalKeyboardKey.keyL: 'l',
  PhysicalKeyboardKey.semicolon: ';',
  PhysicalKeyboardKey.quote: '\'',
  PhysicalKeyboardKey.keyZ: 'z',
  PhysicalKeyboardKey.keyX: 'x',
  PhysicalKeyboardKey.keyC: 'c',
  PhysicalKeyboardKey.keyV: 'v',
  PhysicalKeyboardKey.keyB: 'b',
  PhysicalKeyboardKey.keyN: 'n',
  PhysicalKeyboardKey.keyM: 'm',
  PhysicalKeyboardKey.comma: ',',
  PhysicalKeyboardKey.period: '.',
  PhysicalKeyboardKey.slash: '/',
  PhysicalKeyboardKey.space: ' ',
  PhysicalKeyboardKey.numpadAdd: '+',
  PhysicalKeyboardKey.numpadSubtract: '-',
  PhysicalKeyboardKey.numpadMultiply: '*',
  PhysicalKeyboardKey.numpadDivide: '/',
  PhysicalKeyboardKey.numpadDecimal: '.',
  // 数字键盘 使用event.physicalKey 可能取不到值 然后使用event.logicalKey.keyLabel返回值
  PhysicalKeyboardKey.numpad0: '0',
  PhysicalKeyboardKey.numpad1: '1',
  PhysicalKeyboardKey.numpad2: '2',
  PhysicalKeyboardKey.numpad3: '3',
  PhysicalKeyboardKey.numpad4: '4',
  PhysicalKeyboardKey.numpad5: '5',
  PhysicalKeyboardKey.numpad6: '6',
  PhysicalKeyboardKey.numpad7: '7',
  PhysicalKeyboardKey.numpad8: '8',
  PhysicalKeyboardKey.numpad9: '9',
};

/// 按shift和大写锁定键识别的map
Map<PhysicalKeyboardKey, String> _shiftPressedKeyEventMap = {
  PhysicalKeyboardKey.backquote: '~',
  PhysicalKeyboardKey.digit1: '!',
  PhysicalKeyboardKey.digit2: '@',
  PhysicalKeyboardKey.digit3: '#',
  PhysicalKeyboardKey.digit4: r'$',
  PhysicalKeyboardKey.digit5: '%',
  PhysicalKeyboardKey.digit6: '^',
  PhysicalKeyboardKey.digit7: '&',
  PhysicalKeyboardKey.digit8: '*',
  PhysicalKeyboardKey.digit9: '(',
  PhysicalKeyboardKey.digit0: ')',
  PhysicalKeyboardKey.minus: '_',
  PhysicalKeyboardKey.equal: '+',
  PhysicalKeyboardKey.keyQ: 'Q',
  PhysicalKeyboardKey.keyW: 'W',
  PhysicalKeyboardKey.keyE: 'E',
  PhysicalKeyboardKey.keyR: 'R',
  PhysicalKeyboardKey.keyT: 'T',
  PhysicalKeyboardKey.keyY: 'Y',
  PhysicalKeyboardKey.keyU: 'U',
  PhysicalKeyboardKey.keyI: 'I',
  PhysicalKeyboardKey.keyO: 'O',
  PhysicalKeyboardKey.keyP: 'P',
  PhysicalKeyboardKey.bracketLeft: '{',
  PhysicalKeyboardKey.bracketRight: '}',
  PhysicalKeyboardKey.backslash: '|',
  PhysicalKeyboardKey.keyA: 'A',
  PhysicalKeyboardKey.keyS: 'S',
  PhysicalKeyboardKey.keyD: 'D',
  PhysicalKeyboardKey.keyF: 'F',
  PhysicalKeyboardKey.keyG: 'G',
  PhysicalKeyboardKey.keyH: 'H',
  PhysicalKeyboardKey.keyJ: 'J',
  PhysicalKeyboardKey.keyK: 'K',
  PhysicalKeyboardKey.keyL: 'L',
  PhysicalKeyboardKey.semicolon: ':',
  PhysicalKeyboardKey.quote: '"',
  PhysicalKeyboardKey.keyZ: 'Z',
  PhysicalKeyboardKey.keyX: 'X',
  PhysicalKeyboardKey.keyC: 'C',
  PhysicalKeyboardKey.keyV: 'V',
  PhysicalKeyboardKey.keyB: 'B',
  PhysicalKeyboardKey.keyN: 'N',
  PhysicalKeyboardKey.keyM: 'M',
  PhysicalKeyboardKey.comma: '<',
  PhysicalKeyboardKey.period: '>',
  PhysicalKeyboardKey.slash: '?',
};

/// 小数字键盘事件map 数字键盘 使用event.physicalKey 可能取不到值 然后使用event.logicalKey.keyLabel返回值
Map<String, String> _numKeyEventMap = {
  '0': '0',
  '1': '1',
  '2': '2',
  '3': '3',
  '4': '4',
  '5': '5',
  '6': '6',
  '7': '7',
  '8': '8',
  '9': '9',
};
