import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import '../../services/build_orchestrator.dart';
import '../../theme/app_theme.dart';

class BuildResultDialog extends StatelessWidget {
  final String apkFileName;
  final String apkFilePath;
  final int fileSizeBytes;
  final Duration duration;
  final String? downloadUrl;

  const BuildResultDialog({
    super.key,
    required this.apkFileName,
    required this.apkFilePath,
    required this.fileSizeBytes,
    required this.duration,
    this.downloadUrl,
  });

  String get _formattedSize {
    if (fileSizeBytes <= 0) return 'Verified Release APK';
    final mb = fileSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get _formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes min $seconds sec';
    }
    return '$seconds seconds';
  }

  Future<void> _openFolder(BuildContext context) async {
    final success = await BuildOrchestrator.openFolderOnHost(apkFilePath);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open folder via daemon. Copied path to clipboard instead.'),
          backgroundColor: AppTheme.warningAmber,
        ),
      );
      _copyPath(context);
    }
  }

  void _downloadApk() {
    final url = downloadUrl ?? '${BuildOrchestrator.daemonUrl}/api/artifacts/download?path=${Uri.encodeComponent(apkFilePath)}';
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', apkFileName)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  }

  void _copyPath(BuildContext context) {
    Clipboard.setData(ClipboardData(text: apkFilePath));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local APK destination copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Release APK Generated!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Real Android APK compiled in $_formattedDuration',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // File Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.android_rounded, size: 22, color: AppTheme.primarySky),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            apkFileName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWhite,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Text(
                            _formattedSize,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Saved directly to host Downloads folder:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      apkFilePath,
                      style: const TextStyle(fontSize: 11, fontFamily: 'Consolas', color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Path'),
                    onPressed: () => _copyPath(context),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 18, color: AppTheme.primarySky),
                    label: const Text('Download APK'),
                    onPressed: _downloadApk,
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Open in Downloads Folder'),
                    onPressed: () => _openFolder(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
