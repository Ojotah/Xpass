import 'dart:async';

import 'package:flutter/services.dart';

class ClipboardManager {
  Timer? _clearTimer;

  Future<void> copyWithOptionalAutoClear(
    String value, {
    required bool autoClear,
    required Duration clearAfter,
  }) async {
    _clearTimer?.cancel();
    await Clipboard.setData(ClipboardData(text: value));

    if (!autoClear) {
      return;
    }

    _clearTimer = Timer(clearAfter, () async {
      final current = await Clipboard.getData('text/plain');
      if (current?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  void dispose() {
    _clearTimer?.cancel();
  }
}
