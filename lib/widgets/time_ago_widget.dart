import 'dart:async';
import 'package:flutter/material.dart';

class TimeAgoWidget extends StatefulWidget {
  final DateTime dateTime;
  final TextStyle? style;

  const TimeAgoWidget({super.key, required this.dateTime, this.style});

  @override
  State<TimeAgoWidget> createState() => _TimeAgoWidgetState();
}

class _TimeAgoWidgetState extends State<TimeAgoWidget> {
  Timer? _timer;
  late String _displayText;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _displayText = _formatTimeAgo(widget.dateTime);
    });
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (difference.inDays >= 1) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours >= 1) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes >= 1) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayText, style: widget.style);
  }
}
