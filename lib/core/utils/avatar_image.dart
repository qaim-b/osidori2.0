import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

ImageProvider<Object>? avatarImageProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.trim().isEmpty) return null;
  final url = avatarUrl.trim();

  if (url.startsWith('data:image')) {
    final comma = url.indexOf(',');
    if (comma <= 0 || comma >= url.length - 1) return null;
    try {
      final base64 = url.substring(comma + 1);
      final bytes = base64Decode(base64);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return NetworkImage(url);
  }

  return null;
}

Uint8List? decodeAvatarBytes(String? avatarUrl) {
  if (avatarUrl == null || !avatarUrl.startsWith('data:image')) return null;
  final comma = avatarUrl.indexOf(',');
  if (comma <= 0 || comma >= avatarUrl.length - 1) return null;
  try {
    return base64Decode(avatarUrl.substring(comma + 1));
  } catch (_) {
    return null;
  }
}
