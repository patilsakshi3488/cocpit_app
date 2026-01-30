import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../widgets/notification_toast.dart';
import 'feed/notification_screen.dart';
import '../main.dart'; // For navigatorKey

class NotificationWrapper extends StatefulWidget {
  final Widget? child;

  const NotificationWrapper({super.key, this.child});

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> {
  StreamSubscription? _subscription;
  Map<String, dynamic>? _currentNotification;
  Timer? _dismissTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _subscription = NotificationService().onNewNotification.listen((data) {
      // Determine if we should show this notification
      // (Optional: Check if we are already on the relevant screen?)
      _showToast(data);
    });
  }

  void _showToast(Map<String, dynamic> data) {
    _dismissTimer?.cancel();

    setState(() {
      _currentNotification = data;
      _isVisible = true;
    });

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _hideToast() {
    _dismissTimer?.cancel();
    setState(() {
      _isVisible = false;
    });
  }

  void _handleTap() {
    if (_currentNotification == null) return;

    final n = _currentNotification!;
    _hideToast();

    // Determine type
    final type = n['type']?.toString().toLowerCase() ?? '';

    // 1. Chat/Message -> Deep Link to Chat Screen
    if (type == 'message' || type == 'chat') {
      NotificationService.navigateToNotificationTarget(context, n);
      return;
    }

    // 2. Everything else -> Go to Notification Screen (List)
    // 2. Everything else -> Go to Notification Screen (List)
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        if (widget.child != null) widget.child!,

        // Animated Toast Overlay
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          top: _isVisible ? 0 : -150, // Slide in/out from top
          left: 0,
          right: 0,
          child: _currentNotification == null
              ? const SizedBox.shrink()
              : NotificationToast(
                  title: _getTitle(_currentNotification!),
                  body: _getBody(_currentNotification!),
                  avatarUrl: _getAvatar(_currentNotification!),
                  onTap: _handleTap,
                  onDismiss: _hideToast,
                ),
        ),
      ],
    );
  }

  String _getTitle(Map<String, dynamic> n) {
    final type = n['type']?.toString().toLowerCase() ?? 'system';
    final senderName =
        n['actor']?['name'] ??
        n['sender']?['full_name'] ??
        n['sender_name'] ??
        n['actor_name'] ??
        'New Notification';

    if (type == 'message' || type == 'chat') {
      return senderName;
    }
    return 'New Notification';
  }

  String _getBody(Map<String, dynamic> n) {
    final type = n['type']?.toString().toLowerCase() ?? 'system';

    if (type == 'message' || type == 'chat') {
      return n['text_content'] ?? n['content'] ?? n['text'] ?? 'Sent a message';
    }

    // Construct body for others
    final senderName =
        n['actor']?['name'] ??
        n['sender']?['full_name'] ??
        n['sender_name'] ??
        n['actor_name'] ??
        'Someone';

    // 🌟 PREFER BACKEND TEXT
    if (n['text'] != null && n['text'].toString().trim().isNotEmpty) {
      return n['text'];
    }

    if (type == 'follow') return '$senderName started following you';
    if (type == 'like') return '$senderName liked your post';
    if (type == 'comment') return '$senderName commented on your post';

    return n['message'] ?? 'You have a new update';
  }

  String? _getAvatar(Map<String, dynamic> n) {
    return n['actor']?['avatar_url'] ??
        n['actor']?['avatar'] ??
        n['sender']?['avatar_url'] ??
        n['sender']?['avatar'];
  }
}
