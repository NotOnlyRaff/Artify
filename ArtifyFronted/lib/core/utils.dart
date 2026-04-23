import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

String rgbToHex(Color color) {
  return '${color.red.toRadixString(16).padLeft(2, '0')}'
      '${color.green.toRadixString(16).padLeft(2, '0')}'
      '${color.blue.toRadixString(16).padLeft(2, '0')}';
}

Color hexToColor(String hex) {
  return Color(int.parse(hex, radix: 16) + 0xFF000000);
}

void showSnackBar(BuildContext context, String content) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(content),
      ),
    );
}

class PickedMedia {
  final String name;
  final String? filePath; // mobile/desktop
  final Uint8List? bytes; // web

  const PickedMedia({
    required this.name,
    this.filePath,
    this.bytes,
  });

  File? get asFile {
    if (kIsWeb) return null;
    if (filePath == null) return null;
    return File(filePath!);
  }
}

Future<PickedMedia?> pickImage() async {
  try {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (res == null || res.files.isEmpty) return null;
    final f = res.files.first;

    return PickedMedia(
      name: f.name,
      filePath: f.path,
      bytes: f.bytes,
    );
  } catch (_) {
    return null;
  }
}

Future<PickedMedia?> pickAudio() async {
  try {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: kIsWeb,
    );
    if (res == null || res.files.isEmpty) return null;
    final f = res.files.first;

    return PickedMedia(
      name: f.name,
      filePath: f.path,
      bytes: f.bytes,
    );
  } catch (_) {
    return null;
  }
}
