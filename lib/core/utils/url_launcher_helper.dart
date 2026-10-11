import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UrlLauncherHelper {
  static Future<void> openUrl(BuildContext context, String rawUrl) async {
    String url = rawUrl.trim();
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    bool launched = false;

    try {
      if (!kIsWeb && Platform.isWindows) {
        // Windows native URL launcher via rundll32 or explorer
        final res = await Process.run(
          'rundll32',
          ['url.dll,FileProtocolHandler', url],
          runInShell: true,
        );
        launched = res.exitCode == 0;
      } else if (!kIsWeb && Platform.isMacOS) {
        final res = await Process.run('open', [url]);
        launched = res.exitCode == 0;
      } else if (!kIsWeb && Platform.isLinux) {
        final res = await Process.run('xdg-open', [url]);
        launched = res.exitCode == 0;
      }
    } catch (_) {
      launched = false;
    }

    // Always ensure the URL is also copied to clipboard for quick access
    await Clipboard.setData(ClipboardData(text: url));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                launched ? Icons.open_in_browser : Icons.copy_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  launched
                      ? 'Opening link: $url'
                      : 'Link copied to clipboard: $url',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> copyToClipboard(BuildContext context, String rawUrl) async {
    String url = rawUrl.trim();
    if (url.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
