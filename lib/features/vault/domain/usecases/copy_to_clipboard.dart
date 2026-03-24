import '../../../../core/utils/clipboard_manager.dart';

class CopyToClipboard {
  const CopyToClipboard(this._clipboardManager);

  final ClipboardManager _clipboardManager;

  Future<void> call(
    String value, {
    required bool autoClear,
    required Duration clearAfter,
  }) {
    return _clipboardManager.copyWithOptionalAutoClear(
      value,
      autoClear: autoClear,
      clearAfter: clearAfter,
    );
  }
}
