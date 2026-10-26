import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import '../models/build_manifest.dart';

class BuildOrchestrator {
  static const String daemonUrl = 'http://127.0.0.1:8765';
  static const String daemonWsUrl = 'ws://127.0.0.1:8765/api/build/logs';

  String? _lastOutputPath;
  int _lastOutputSizeBytes = 0;
  String? _lastDownloadUrl;

  String? get lastOutputPath => _lastOutputPath;
  int get lastOutputSizeBytes => _lastOutputSizeBytes;
  String? get lastDownloadUrl => _lastDownloadUrl;

  Stream<String> buildStream(BuildManifest manifest, {String? gitUsername, String? gitPasswordOrToken}) {
    final controller = StreamController<String>.broadcast();

    _runDaemonBuild(
      manifest,
      onLog: (line) => controller.add(line),
      onDone: (success, path, size, downloadUrl, error) {
        _lastOutputPath = path;
        _lastOutputSizeBytes = size;
        _lastDownloadUrl = downloadUrl;
        if (error != null) {
          controller.addError(error);
        }
        controller.close();
      },
      gitUsername: gitUsername,
      gitPasswordOrToken: gitPasswordOrToken,
    );

    return controller.stream;
  }

  Future<void> _runDaemonBuild(
    BuildManifest manifest, {
    required Function(String log) onLog,
    required Function(bool success, String? path, int size, String? downloadUrl, String? error) onDone,
    String? gitUsername,
    String? gitPasswordOrToken,
  }) async {
    onLog('===============================================================');
    onLog('⚡ CONNECTING TO LOCAL SIMPLIWORKS BUILD DAEMON (PORT 8765)...');

    // 1. Verify Daemon Health
    try {
      final healthRes = await http.get(Uri.parse('$daemonUrl/health')).timeout(const Duration(seconds: 4));
      if (healthRes.statusCode != 200) {
        throw Exception('Daemon returned invalid status: ${healthRes.statusCode}');
      }
      onLog('✅ Connected to Host Build Engine (Simpliworks Daemon 1.0.0)');
    } catch (e) {
      onLog('❌ ERROR: Local Build Daemon is not reachable at $daemonUrl.');
      onLog('   Please ensure the daemon is running via: "dart run bin/build_daemon.dart"');
      onDone(false, null, 0, null, 'Daemon unreachable: $e');
      return;
    }

    // 2. Open WebSocket Log Stream
    html.WebSocket? ws;
    StreamSubscription? wsSub;

    try {
      ws = html.WebSocket(daemonWsUrl);
      await ws.onOpen.first.timeout(const Duration(seconds: 4));
      onLog('✅ Real-time process logging pipeline connected.');

      wsSub = ws.onMessage.listen((event) {
        final raw = event.data.toString();
        if (raw.startsWith('__JSON__:')) {
          try {
            final jsonStr = raw.substring('__JSON__:'.length);
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            if (data['type'] == 'build_complete') {
              final success = data['success'] as bool? ?? false;
              final path = data['outputPath'] as String?;
              final size = data['sizeBytes'] as int? ?? 0;
              final dlUrl = data['downloadUrl'] as String?;
              final err = data['error'] as String?;
              onDone(success, path, size, dlUrl, err);
            }
          } catch (_) {}
        } else {
          onLog(raw);
        }
      });
    } catch (e) {
      onLog('⚠️ WebSocket logging failed ($e), falling back to HTTP...');
    }

    // 3. Dispatch Manifest to Daemon
    try {
      final payload = {
        'clientId': manifest.clientId,
        'clientName': manifest.clientName,
        'buildType': manifest.buildType == BuildType.separateModule ? 'separateModule' : 'homeComposite',
        'homeRepoUrl': manifest.homeRepoUrl,
        'homeBranch': manifest.homeBranch,
        'environment': manifest.environment,
        'baseUrl': manifest.baseUrl,
        'version': manifest.version,
        'apkFilename': manifest.apkFilename,
        'targetSharedComponentVersion': manifest.targetSharedComponentVersion,
        'gitUsername': gitUsername,
        'gitPasswordOrToken': gitPasswordOrToken,
        'standaloneModule': manifest.standaloneModule?.toJson(),
        'selectedModules': manifest.selectedModules.map((m) => {
          'module': m.module.toJson(),
          'pullBranch': m.pullBranch,
        }).toList(),
      };

      final postRes = await http.post(
        Uri.parse('$daemonUrl/api/build'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (postRes.statusCode != 200) {
        throw Exception('Daemon rejected build request: ${postRes.body}');
      }
    } catch (e) {
      onLog('❌ Failed to dispatch build request to daemon: $e');
      wsSub?.cancel();
      ws?.close();
      onDone(false, null, 0, null, e.toString());
    }
  }

  static Future<bool> openFolderOnHost(String filePath) async {
    try {
      final res = await http.post(
        Uri.parse('$daemonUrl/api/open-folder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'path': filePath}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
