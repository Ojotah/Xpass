import 'dart:async';

import 'package:flutter/material.dart';

enum TopRightNotificationType { success, warning, error, info }

class TopRightNotification {
  static final List<_NotificationHandle> _active = <_NotificationHandle>[];

  static void show(
    BuildContext context, {
    required String message,
    TopRightNotificationType type = TopRightNotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final offsetIndex = _active.length;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _TopRightNotificationBubble(
          message: message,
          type: type,
          index: offsetIndex,
          duration: duration,
          onDismissed: () {
            entry.remove();
            _active.removeWhere((item) => item.entry == entry);
          },
        );
      },
    );

    _active.add(_NotificationHandle(entry));
    overlay.insert(entry);
  }
}

class _NotificationHandle {
  const _NotificationHandle(this.entry);

  final OverlayEntry entry;
}

class _TopRightNotificationBubble extends StatefulWidget {
  const _TopRightNotificationBubble({
    required this.message,
    required this.type,
    required this.index,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final TopRightNotificationType type;
  final int index;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopRightNotificationBubble> createState() =>
      _TopRightNotificationBubbleState();
}

class _TopRightNotificationBubbleState
    extends State<_TopRightNotificationBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (widget.type) {
      TopRightNotificationType.success => (
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
          Icons.check_circle_outline,
        ),
      TopRightNotificationType.warning => (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
          Icons.warning_amber_rounded,
        ),
      TopRightNotificationType.error => (
          colorScheme.error,
          colorScheme.onError,
          Icons.error_outline,
        ),
      TopRightNotificationType.info => (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
          Icons.info_outline,
        ),
    };

    return Positioned(
      top: 16 + (widget.index * 72),
      right: 16,
      child: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: background,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _dismiss,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: foreground, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                            color: foreground, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
