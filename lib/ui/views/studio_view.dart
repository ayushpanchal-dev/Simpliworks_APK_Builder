import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/studio_controller.dart';
import '../../services/build_orchestrator.dart';
import '../../models/client_model.dart';
import '../../models/build_manifest.dart';
import '../../theme/app_theme.dart';
import '../components/terminal_console.dart';
import '../dialogs/build_result_dialog.dart';

class StudioView extends StatefulWidget {
  final StudioController controller;
  final BuildOrchestrator orchestrator;

  const StudioView({
    super.key,
    required this.controller,
    required this.orchestrator,
  });

  @override
  State<StudioView> createState() => _StudioViewState();
}

class _StudioViewState extends State<StudioView> {
  final _versionController = TextEditingController();
  final _buildNumController = TextEditingController();
  final _apkNameController = TextEditingController();
  final _sharedCompController = TextEditingController();

  final StreamController<String> _logController = StreamController<String>.broadcast();
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _versionController.text = c.versionName;
    _buildNumController.text = c.buildNumber.toString();
    _apkNameController.text = c.customApkName;
    _sharedCompController.text = c.sharedComponentVersion;

    c.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      if (_apkNameController.text != widget.controller.customApkName &&
          !widget.controller.isBuilding) {
        _apkNameController.text = widget.controller.customApkName;
      }
      if (_sharedCompController.text != widget.controller.sharedComponentVersion &&
          !widget.controller.isBuilding) {
        _sharedCompController.text = widget.controller.sharedComponentVersion;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _versionController.dispose();
    _buildNumController.dispose();
    _apkNameController.dispose();
    _sharedCompController.dispose();
    _sub?.cancel();
    _logController.close();
    super.dispose();
  }

  Future<void> _startBuild() async {
    final c = widget.controller;
    if (c.selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client first')),
      );
      return;
    }
    if (c.buildType == BuildType.separateModule && c.selectedStandaloneModule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a module for the standalone build')),
      );
      return;
    }

    c.setBuilding(true, status: 'Building');
    final manifest = c.createManifest();
    final stopwatch = Stopwatch()..start();

    _sub?.cancel();
    _sub = widget.orchestrator.buildStream(manifest).listen(
      (log) {
        _logController.add(log);
      },
      onError: (err) {
        _logController.add('[FATAL ERROR]: $err');
        c.setBuilding(false, status: 'Failed');
      },
      onDone: () {
        stopwatch.stop();
        c.setBuilding(false, status: 'Success');

        final outputApkPath = widget.orchestrator.lastOutputPath;
        if (outputApkPath != null && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => BuildResultDialog(
              apkFileName: manifest.apkFilename,
              apkFilePath: outputApkPath,
              fileSizeBytes: widget.orchestrator.lastOutputSizeBytes,
              duration: stopwatch.elapsed,
              downloadUrl: widget.orchestrator.lastDownloadUrl,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final clients = c.registryService.clients;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Configuration Panel (45% width)
          Expanded(
            flex: 45,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBuildTypeCard(c),
                  const SizedBox(height: 16),
                  _buildClientCard(c, clients),
                  const SizedBox(height: 16),
                  if (c.buildType == BuildType.separateModule)
                    _buildStandaloneModuleCard(c)
                  else
                    _buildHomeCompositeModulesCard(c),
                  const SizedBox(height: 16),
                  _buildSharedComponentsCard(c),
                  const SizedBox(height: 16),
                  _buildEnvironmentCard(c),
                  const SizedBox(height: 16),
                  _buildVersionCard(c),
                ],
              ),
            ),
          ),

          // Vertical Divider
          const VerticalDivider(width: 1, thickness: 1, color: AppTheme.borderSubtle),

          // Right Console & Execution Panel (55% width)
          Expanded(
            flex: 55,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPreflightSummary(c),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: c.isBuilding ? AppTheme.borderMedium : AppTheme.primarySky,
                    ),
                    icon: c.isBuilding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.rocket_launch_rounded, size: 20),
                    label: Text(
                      c.isBuilding ? 'Generating Release APK...' : 'Generate Release APK',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: c.isBuilding ? null : _startBuild,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TerminalConsole(
                      logStream: _logController.stream,
                      status: c.buildStatus,
                      onClear: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildTypeCard(StudioController c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.layers_rounded, size: 18, color: AppTheme.primarySky),
                const SizedBox(width: 8),
                const Text(
                  'APK Build Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: c.buildType == BuildType.separateModule
                          ? AppTheme.primarySky.withValues(alpha: 0.1)
                          : AppTheme.surfaceWhite,
                      side: BorderSide(
                        color: c.buildType == BuildType.separateModule ? AppTheme.primarySky : AppTheme.borderMedium,
                        width: c.buildType == BuildType.separateModule ? 2 : 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: c.isBuilding ? null : () => c.setBuildType(BuildType.separateModule),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.crop_square_rounded,
                          size: 16,
                          color: c.buildType == BuildType.separateModule ? AppTheme.primarySky : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Separate Module APK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: c.buildType == BuildType.separateModule ? AppTheme.primarySky : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: c.buildType == BuildType.homeComposite
                          ? AppTheme.primaryIndigo.withValues(alpha: 0.1)
                          : AppTheme.surfaceWhite,
                      side: BorderSide(
                        color: c.buildType == BuildType.homeComposite ? AppTheme.primaryIndigo : AppTheme.borderMedium,
                        width: c.buildType == BuildType.homeComposite ? 2 : 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: c.isBuilding ? null : () => c.setBuildType(BuildType.homeComposite),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 16,
                          color: c.buildType == BuildType.homeComposite ? AppTheme.primaryIndigo : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Home APK (Composite)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: c.buildType == BuildType.homeComposite ? AppTheme.primaryIndigo : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(StudioController c, List<ClientProfile> clients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business_rounded, size: 18, color: AppTheme.primarySky),
                const SizedBox(width: 8),
                const Text(
                  'Client Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ClientProfile>(
              key: ValueKey(c.selectedClient?.id),
              initialValue: c.selectedClient,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Target Client',
                prefixIcon: Icon(Icons.domain_rounded, size: 18, color: AppTheme.textSecondary),
              ),
              items: clients.map((client) {
                return DropdownMenuItem<ClientProfile>(
                  value: client,
                  child: Text(client.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: c.isBuilding ? null : (client) => c.setClient(client),
            ),
            if (c.buildType == BuildType.homeComposite && c.selectedClient != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.selectedClient!.homeRepoUrl,
                        style: const TextStyle(fontSize: 11, fontFamily: 'Consolas', color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: c.selectedHomeBranch,
                enabled: !c.isBuilding,
                decoration: const InputDecoration(
                  labelText: 'Home Git Branch',
                  prefixIcon: Icon(Icons.fork_right_rounded, size: 18, color: AppTheme.textSecondary),
                ),
                onChanged: (b) => c.setHomeBranch(b),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStandaloneModuleCard(StudioController c) {
    final clientModules = c.selectedClient?.modules ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.extension_rounded, size: 18, color: AppTheme.primarySky),
                const SizedBox(width: 8),
                const Text(
                  'Standalone Module Selection',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (clientModules.isEmpty)
              const Text('No modules registered for this client.', style: TextStyle(color: AppTheme.errorRed, fontSize: 12))
            else
              DropdownButtonFormField<ClientModuleConfig>(
                key: ValueKey(c.selectedStandaloneModule?.id),
                initialValue: c.selectedStandaloneModule,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Module to Build',
                  prefixIcon: Icon(Icons.inventory_2_rounded, size: 18, color: AppTheme.textSecondary),
                ),
                items: clientModules.map((m) {
                  return DropdownMenuItem<ClientModuleConfig>(
                    value: m,
                    child: Text(m.displayName, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: c.isBuilding ? null : (mod) => c.setStandaloneModule(mod),
              ),
            if (c.selectedStandaloneModule != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            c.selectedStandaloneModule!.repoUrl,
                            style: const TextStyle(fontSize: 11, fontFamily: 'Consolas', color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target Branch: ${c.selectedStandaloneModule!.defaultBranch}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primarySky),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCompositeModulesCard(StudioController c) {
    final modules = c.selectedClient?.modules ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.extension_rounded, size: 18, color: AppTheme.primaryIndigo),
                    const SizedBox(width: 8),
                    const Text(
                      'Integrated Modules into Home',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Text(
                  '${c.selectedModuleIds.length} Selected',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (modules.isEmpty)
              const Center(child: Text('No modules configured for this client.'))
            else
              ...modules.map((m) {
                final isSelected = c.selectedModuleIds.contains(m.id) || m.isRequiredInHome;
                final branch = c.moduleBranches[m.id] ?? m.defaultBranch;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryIndigo.withValues(alpha: 0.04) : AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryIndigo.withValues(alpha: 0.3) : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: AppTheme.primaryIndigo,
                        onChanged: (m.isRequiredInHome || c.isBuilding)
                            ? null
                            : (val) => c.toggleModule(m.id, val ?? false, defaultBranch: m.defaultBranch),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            Text(
                              m.repoUrl,
                              style: const TextStyle(fontSize: 10, fontFamily: 'Consolas', color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          initialValue: branch,
                          enabled: isSelected && !c.isBuilding,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            labelText: 'Branch',
                          ),
                          onChanged: (b) => c.setModuleBranch(m.id, b),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedComponentsCard(StudioController c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.sync_rounded, size: 18, color: AppTheme.primarySky),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Centralized Shared Components Version',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sharedCompController,
              enabled: !c.isBuilding,
              decoration: const InputDecoration(
                labelText: 'Target shared_component Version in pubspec.yaml',
                hintText: 'e.g. 1.4.6+67.2',
                prefixIcon: Icon(Icons.tag_rounded, size: 18, color: AppTheme.textSecondary),
              ),
              onChanged: (v) => c.setSharedComponentVersion(v),
            ),
            const SizedBox(height: 8),
            const Text(
              'This version will be applied centrally to all participating projects before building.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard(StudioController c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.public_rounded, size: 18, color: AppTheme.primarySky),
                const SizedBox(width: 8),
                const Text(
                  'Environment & Derived Backend URL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: ['Testing', 'Preprod', 'Production'].map((env) {
                final isSelected = c.selectedEnv == env;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? AppTheme.primarySky : AppTheme.surfaceWhite,
                        side: BorderSide(
                          color: isSelected ? AppTheme.primarySky : AppTheme.borderMedium,
                          width: isSelected ? 1.5 : 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: c.isBuilding ? null : () => c.setEnvironment(env),
                      child: Text(
                        env,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primarySky.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primarySky.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns_rounded, size: 18, color: AppTheme.primarySky),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Derived Base URL (Assets / config.json)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primarySky),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.derivedBaseUrl.isNotEmpty ? c.derivedBaseUrl : 'No Base URL configured for ${c.selectedEnv}',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Consolas',
                            color: c.derivedBaseUrl.isNotEmpty ? AppTheme.textPrimary : AppTheme.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (c.derivedBaseUrl.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.primarySky),
                      tooltip: 'Copy Base URL',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: c.derivedBaseUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Base URL copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(StudioController c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tag_rounded, size: 18, color: AppTheme.primarySky),
                const SizedBox(width: 8),
                const Text(
                  'App Version & Release APK Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _versionController,
                    enabled: !c.isBuilding,
                    decoration: const InputDecoration(labelText: 'Version Name', hintText: '1.0.0'),
                    onChanged: (v) => c.setVersionName(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _buildNumController,
                    enabled: !c.isBuilding,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Build No.', hintText: '1'),
                    onChanged: (n) => c.setBuildNumber(int.tryParse(n) ?? 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _apkNameController,
              enabled: !c.isBuilding,
              decoration: const InputDecoration(
                labelText: 'Target Output APK Filename',
                prefixIcon: Icon(Icons.file_present_rounded, size: 18, color: AppTheme.textSecondary),
              ),
              onChanged: (name) => c.setCustomApkName(name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreflightSummary(StudioController c) {
    final typeLabel = c.buildType == BuildType.separateModule ? 'Separate Module' : 'Home Composite';
    final targetLabel = c.buildType == BuildType.separateModule
        ? (c.selectedStandaloneModule?.displayName ?? 'None')
        : '${c.selectedModuleIds.length} Modules';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildSummaryItem('Build Type', typeLabel),
            ),
            const VerticalDivider(width: 12, thickness: 1),
            Expanded(
              flex: 2,
              child: _buildSummaryItem('Client', c.selectedClient?.id ?? 'None'),
            ),
            const VerticalDivider(width: 12, thickness: 1),
            Expanded(
              flex: 3,
              child: _buildSummaryItem('Target', targetLabel),
            ),
            const VerticalDivider(width: 12, thickness: 1),
            Expanded(
              flex: 3,
              child: _buildSummaryItem('Shared Comp.', c.sharedComponentVersion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
