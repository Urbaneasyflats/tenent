import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves a PDF to the device Downloads folder and shows a success dialog.
///
/// On Android the file is saved to `/storage/emulated/0/Download/`.
/// On iOS the share sheet is used as a fallback.
class PdfSaver {
  PdfSaver._();

  static Future<void> saveAndOffer(
    BuildContext context, {
    required Uint8List bytes,
    required String filename,
  }) async {
    String? savedPath;

    try {
      if (Platform.isAndroid) {
        final Directory downloads = Directory('/storage/emulated/0/Download');
        if (await downloads.exists()) {
          final File file = File('${downloads.path}/$filename');
          await file.writeAsBytes(bytes);
          savedPath = file.path;
        }
      }

      // Fallback: save to app documents directory.
      if (savedPath == null) {
        final Directory docs = await getApplicationDocumentsDirectory();
        final File file = File('${docs.path}/$filename');
        await file.writeAsBytes(bytes);
        savedPath = file.path;
      }
    } catch (_) {
      // If saving fails, fall back to share.
      Share.shareXFiles(
        <XFile>[XFile.fromData(bytes, name: filename, mimeType: 'application/pdf')],
      );
      return;
    }

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) => AlertDialog(
        title: const Text('File Saved'),
        content: Text('$filename saved to Downloads.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              OpenFilex.open(savedPath!);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
