import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml_edit/yaml_edit.dart';

const int kDaemonPort = 8765;
final List<WebSocket> _logClients = [];

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, kDaemonPort);
  print('[Simpliworks Daemon] Running on http://127.0.0.1:$kDaemonPort');

  await for (HttpRequest request in server) {
    _handleRequest(request);
  }
}

void _broadcastLog(String line) {
  print(line);
  for (var client in _logClients) {
    if (client.readyState == WebSocket.open) {
      client.add(line);
    }
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  // CORS Headers
  request.response.headers.add('Access-Control-Allow-Origin', '*');
  request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.ok;
    await request.response.close();
    return;
  }

  final uri = request.uri;

  if (uri.path == '/health') {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'status': 'ok', 'daemon': 'simpliworks_build_daemon', 'version': '1.0.0'}))
      ..close();
    return;
  }

  if (uri.path == '/api/build/logs') {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _logClients.add(socket);
      socket.done.then((_) => _logClients.remove(socket));
    } else {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
    }
    return;
  }

  if (uri.path == '/api/open-folder' && request.method == 'POST') {
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final filePath = data['path'] as String? ?? '';

      if (filePath.isNotEmpty) {
        if (Platform.isWindows) {
          final file = File(filePath);
          if (await file.exists()) {
            await Process.start('explorer.exe', ['/select,', p.normalize(filePath)], runInShell: true);
          } else {
            final parent = p.dirname(filePath);
            await Process.start('explorer.exe', [p.normalize(parent)], runInShell: true);
          }
        } else if (Platform.isMacOS) {
          await Process.start('open', ['-R', filePath]);
        }
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'success': true}))
        ..close();
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode({'error': e.toString()}))
        ..close();
    }
    return;
  }

  if (uri.path == '/api/artifacts/download') {
    final path = uri.queryParameters['path'];
    if (path == null || !await File(path).exists()) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Artifact not found.')
        ..close();
      return;
    }

    final file = File(path);
    final filename = p.basename(path);
    request.response.headers.contentType = ContentType('application', 'vnd.android.package-archive');
    request.response.headers.add('Content-Disposition', 'attachment; filename="$filename"');
    request.response.headers.contentLength = await file.length();
    await file.openRead().pipe(request.response);
    return;
  }

  if (uri.path == '/api/build' && request.method == 'POST') {
    try {
      final body = await utf8.decoder.bind(request).join();
      final manifest = jsonDecode(body) as Map<String, dynamic>;

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'started': true}))
        ..close();

      // Execute build asynchronously in daemon
      _executeRealBuild(manifest);
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': e.toString()}))
        ..close();
    }
    return;
  }

  request.response.statusCode = HttpStatus.notFound;
  await request.response.close();
}

Future<void> _executeRealBuild(Map<String, dynamic> manifest) async {
  final startTime = DateTime.now();
  final clientId = manifest['clientId'] as String? ?? 'client';
  final clientName = manifest['clientName'] as String? ?? clientId;
  final buildType = manifest['buildType'] as String? ?? 'separateModule';
  final environment = manifest['environment'] as String? ?? 'Testing';
  final baseUrl = manifest['baseUrl'] as String? ?? '';
  final version = manifest['version'] as String? ?? '1.0.0+1';
  final targetSharedComp = manifest['targetSharedComponentVersion'] as String? ?? '1.4.6+67.2';
  final apkFilename = manifest['apkFilename'] as String? ?? 'output.apk';
  final isStandalone = buildType == 'separateModule';

  final gitUser = manifest['gitUsername'] as String?;
  final gitPass = manifest['gitPasswordOrToken'] as String?;

  _broadcastLog('===============================================================');
  _broadcastLog('⚡ SIMPLIWORKS ANDROID APK STUDIO - REAL HOST BUILD ENGINE');
  _broadcastLog('• Build Type: ${isStandalone ? "SEPARATE MODULE APK" : "HOME COMPOSITE APK"}');
  _broadcastLog('• Client: $clientName ($clientId)');
  _broadcastLog('• Environment: $environment (Base URL: $baseUrl)');
  _broadcastLog('• Target Version: $version');
  _broadcastLog('• Target shared_component: $targetSharedComp');
  _broadcastLog('• Output Destination: $apkFilename');
  _broadcastLog('===============================================================\n');

  try {
    // 1. Resolve workspace root
    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Dell';
    final downloadsDir = Directory(p.join(userProfile, 'Downloads'));
    final appSupportDir = Directory(p.join(userProfile, 'AppData', 'Roaming', 'SimpliworksBuilder', 'workspaces'));
    
    // Check local fallback directory if client already cloned
    final localClientDir = Directory(p.join('C:\\workspace\\SimpliWorks', clientId));

    if (isStandalone) {
      // --- STANDALONE MODULE BUILD ---
      final mod = manifest['standaloneModule'] as Map<String, dynamic>? ?? {};
      final modId = mod['id'] as String? ?? 'module';
      final modDisplayName = mod['displayName'] as String? ?? modId;
      final modRepoUrl = mod['repoUrl'] as String? ?? '';
      final modBranch = mod['defaultBranch'] as String? ?? 'master';

      _broadcastLog('[STAGE 1/6] Resolving Standalone Module: $modDisplayName');
      
      // Look for local workspace first
      Directory targetDir = Directory(p.join(appSupportDir.path, clientId, 'modules', modId));
      
      // Fallback to local cloned directory if available
      final localModCandidates = [
        Directory(p.join('C:\\workspace\\SimpliWorks', clientId, '${clientId}_Deliver_GUI')),
        Directory(p.join('C:\\workspace\\SimpliWorks', clientId, '${clientId}_CRM_GUI')),
        Directory(p.join('C:\\workspace\\SimpliWorks', clientId, '${clientId}_Finance_GUI')),
        Directory(p.join('C:\\workspace\\SimpliWorks', clientId, '${clientId}_Expense_GUI')),
      ];

      for (var cand in localModCandidates) {
        if (cand.path.toLowerCase().contains(modId.replaceAll('_module', '').toLowerCase()) && await cand.exists()) {
          targetDir = cand;
          break;
        }
      }

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
        _broadcastLog('[STAGE 2/6] Cloning remote module repository: $modRepoUrl');
        final authUrl = _formatAuthUrl(modRepoUrl, gitUser, gitPass);
        final ret = await _runProcess('git', ['clone', '--branch', modBranch, '--single-branch', authUrl, '.'], targetDir.path);
        if (ret != 0) throw Exception("git clone failed for $modRepoUrl.");
      } else {
        _broadcastLog('[STAGE 2/6] Using workspace directory: ${targetDir.path}');
        _broadcastLog('> Synchronizing Git branch: $modBranch');
        await _runProcess('git', ['fetch', '--all'], targetDir.path);
        await _runProcess('git', ['checkout', modBranch], targetDir.path);
        await _runProcess('git', ['pull'], targetDir.path);
      }

      // Update pubspec.yaml
      _broadcastLog('[STAGE 3/6] Applying shared_component ($targetSharedComp) & Version ($version)');
      final pubspecFile = File(p.join(targetDir.path, 'pubspec.yaml'));
      if (await pubspecFile.exists()) {
        final editor = YamlEditor(await pubspecFile.readAsString());
        if (targetSharedComp.isNotEmpty) {
          editor.update(['dependencies', 'shared_component'], targetSharedComp);
        }
        if (version.isNotEmpty) {
          editor.update(['version'], version);
        }
        await pubspecFile.writeAsString(editor.toString());
      }

      // Update config.json
      _broadcastLog('[STAGE 4/6] Updating assets/config.json with baseUrl: $baseUrl');
      final configFile = File(p.join(targetDir.path, 'assets', 'config.json'));
      if (await configFile.exists()) {
        final configJson = jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
        configJson['baseUrl'] = baseUrl;
        await configFile.writeAsString(const JsonEncoder.withIndent('  ').convert(configJson));
      }

      // Flutter pub get & Build APK
      _broadcastLog('[STAGE 5/6] Executing Flutter Pub Get & Release Build...');
      final pubGet = await _runProcess('flutter', ['pub', 'get'], targetDir.path);
      if (pubGet != 0) throw Exception('flutter pub get failed.');

      final buildArgs = ['build', 'apk', '--release'];
      if (version.contains('+')) {
        final parts = version.split('+');
        buildArgs.addAll(['--build-name=${parts[0]}', '--build-number=${parts[1]}']);
      }
      final buildApk = await _runProcess('flutter', buildArgs, targetDir.path);
      if (buildApk != 0) throw Exception('flutter build apk --release failed.');

      // Collect & Deliver
      _broadcastLog('[STAGE 6/6] Verifying APK Artifact & Delivering...');
      final builtApk = File(p.join(targetDir.path, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'));
      if (!await builtApk.exists()) throw Exception('Built APK not found at: ${builtApk.path}');

      final apkSize = await builtApk.length();
      if (apkSize < 1024 * 1024) throw Exception('Generated APK file size too small ($apkSize bytes). Invalid artifact.');

      final destApk = File(p.join(downloadsDir.path, apkFilename));
      await builtApk.copy(destApk.path);

      _broadcastLog('===============================================================');
      _broadcastLog('🎉 BUILD COMPLETED SUCCESSFULLY IN ${DateTime.now().difference(startTime).inSeconds}s!');
      _broadcastLog('• Verified APK Size: ${(apkSize / (1024 * 1024)).toStringAsFixed(1)} MB');
      _broadcastLog('• Delivered to: ${destApk.path}');
      _broadcastLog('===============================================================');

      _broadcastJsonEvent({
        'type': 'build_complete',
        'success': true,
        'outputPath': destApk.path,
        'apkFilename': apkFilename,
        'sizeBytes': apkSize,
        'downloadUrl': 'http://127.0.0.1:$kDaemonPort/api/artifacts/download?path=${Uri.encodeComponent(destApk.path)}',
      });

    } else {
      // --- HOME COMPOSITE BUILD ---
      final homeRepoUrl = manifest['homeRepoUrl'] as String? ?? '';
      final homeBranch = manifest['homeBranch'] as String? ?? 'master';
      final selectedModules = manifest['selectedModules'] as List? ?? [];

      _broadcastLog('[STAGE 1/6] Resolving Home Project for $clientName');
      Directory homeDir = Directory(p.join(appSupportDir.path, clientId, 'home'));

      final localHomeCandidates = [
        Directory(p.join('C:\\workspace\\SimpliWorks', clientId, '${clientId}_Home_GUI')),
        Directory(p.join('C:\\workspace\\SimpliWorks', clientId, 'WSC-SW-2.0-${clientId}_Home_GUI')),
        Directory(p.join('C:\\workspace\\SimpliWorks', clientId, '${clientId}_Main_GUI')),
      ];

      for (var cand in localHomeCandidates) {
        if (await cand.exists()) {
          homeDir = cand;
          break;
        }
      }

      if (!await homeDir.exists()) {
        await homeDir.create(recursive: true);
        _broadcastLog('[STAGE 2/6] Cloning remote Home repository: $homeRepoUrl');
        final authUrl = _formatAuthUrl(homeRepoUrl, gitUser, gitPass);
        final ret = await _runProcess('git', ['clone', '--branch', homeBranch, '--single-branch', authUrl, '.'], homeDir.path);
        if (ret != 0) throw Exception("git clone failed for $homeRepoUrl.");
      } else {
        _broadcastLog('[STAGE 2/6] Using Home workspace: ${homeDir.path}');
        _broadcastLog('> Synchronizing Git branch: $homeBranch');
        await _runProcess('git', ['fetch', '--all'], homeDir.path);
        await _runProcess('git', ['checkout', homeBranch], homeDir.path);
        await _runProcess('git', ['pull'], homeDir.path);
      }

      // Inject Sub-modules into pubspec.yaml
      _broadcastLog('[STAGE 3/6] Injecting Git Sub-modules & shared_component ($targetSharedComp)...');
      final pubspecFile = File(p.join(homeDir.path, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) throw Exception('pubspec.yaml missing in Home repository.');

      final editor = YamlEditor(await pubspecFile.readAsString());
      if (targetSharedComp.isNotEmpty) {
        editor.update(['dependencies', 'shared_component'], targetSharedComp);
      }
      if (version.isNotEmpty) {
        editor.update(['version'], version);
      }

      for (var item in selectedModules) {
        final mod = item['module'] as Map<String, dynamic>? ?? {};
        final modId = mod['id'] as String? ?? '';
        final modRepo = mod['repoUrl'] as String? ?? '';
        final pullBranch = item['pullBranch'] as String? ?? 'master';

        if (modId.isNotEmpty && modRepo.isNotEmpty) {
          final authModUrl = _formatAuthUrl(modRepo, gitUser, gitPass);
          _broadcastLog('> Injecting module "$modId" (ref: $pullBranch)...');
          editor.update(
            ['dependencies', modId],
            {
              'git': {
                'url': authModUrl,
                'ref': pullBranch,
              }
            },
          );
        }
      }
      await pubspecFile.writeAsString(editor.toString());

      // Update assets/config.json
      _broadcastLog('[STAGE 4/6] Updating Home assets/config.json baseUrl -> $baseUrl');
      final configFile = File(p.join(homeDir.path, 'assets', 'config.json'));
      if (await configFile.exists()) {
        final configJson = jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
        configJson['baseUrl'] = baseUrl;
        await configFile.writeAsString(const JsonEncoder.withIndent('  ').convert(configJson));
      }

      // Flutter pub get & Build APK
      _broadcastLog('[STAGE 5/6] Running Flutter Pub Get & Release Build...');
      final pubGet = await _runProcess('flutter', ['pub', 'get'], homeDir.path);
      if (pubGet != 0) throw Exception('flutter pub get failed.');

      final buildArgs = ['build', 'apk', '--release'];
      if (version.contains('+')) {
        final parts = version.split('+');
        buildArgs.addAll(['--build-name=${parts[0]}', '--build-number=${parts[1]}']);
      }
      final buildApk = await _runProcess('flutter', buildArgs, homeDir.path);
      if (buildApk != 0) throw Exception('flutter build apk --release failed.');

      // Collect & Deliver
      _broadcastLog('[STAGE 6/6] Verifying APK Artifact & Delivering...');
      final builtApk = File(p.join(homeDir.path, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'));
      if (!await builtApk.exists()) throw Exception('Built APK not found at: ${builtApk.path}');

      final apkSize = await builtApk.length();
      if (apkSize < 1024 * 1024) throw Exception('Generated APK file size too small ($apkSize bytes). Invalid artifact.');

      final destApk = File(p.join(downloadsDir.path, apkFilename));
      await builtApk.copy(destApk.path);

      _broadcastLog('===============================================================');
      _broadcastLog('🎉 HOME BUILD COMPLETED SUCCESSFULLY IN ${DateTime.now().difference(startTime).inSeconds}s!');
      _broadcastLog('• Verified APK Size: ${(apkSize / (1024 * 1024)).toStringAsFixed(1)} MB');
      _broadcastLog('• Delivered to: ${destApk.path}');
      _broadcastLog('===============================================================');

      _broadcastJsonEvent({
        'type': 'build_complete',
        'success': true,
        'outputPath': destApk.path,
        'apkFilename': apkFilename,
        'sizeBytes': apkSize,
        'downloadUrl': 'http://127.0.0.1:$kDaemonPort/api/artifacts/download?path=${Uri.encodeComponent(destApk.path)}',
      });
    }

  } catch (e) {
    _broadcastLog('\n❌ REAL BUILD FAILED: $e');
    _broadcastJsonEvent({
      'type': 'build_complete',
      'success': false,
      'error': e.toString(),
    });
  }
}

void _broadcastJsonEvent(Map<String, dynamic> data) {
  final encoded = jsonEncode(data);
  for (var client in _logClients) {
    if (client.readyState == WebSocket.open) {
      client.add('__JSON__:$encoded');
    }
  }
}

String _formatAuthUrl(String originalUrl, String? user, String? pass) {
  if (user == null || user.isEmpty || pass == null || pass.isEmpty) {
    return originalUrl;
  }
  final uri = Uri.tryParse(originalUrl);
  if (uri == null) return originalUrl;
  final encodedUser = Uri.encodeComponent(user);
  final encodedPass = Uri.encodeComponent(pass);
  return uri.replace(userInfo: '$encodedUser:$encodedPass').toString();
}

Future<int> _runProcess(String executable, List<String> args, String workingDir) async {
  _broadcastLog(r'$ ' '$executable ${args.join(' ')}');
  try {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDir,
      runInShell: Platform.isWindows,
    );

    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      _broadcastLog(line);
    });
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      _broadcastLog(line);
    });

    return await process.exitCode;
  } catch (e) {
    _broadcastLog('❌ Process launch error: $e');
    return -1;
  }
}
