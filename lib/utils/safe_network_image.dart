import 'package:flutter/material.dart';

ImageProvider? safeNetworkImage(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  if (!url.startsWith('http')) return null;
  return NetworkImage(url);
}
