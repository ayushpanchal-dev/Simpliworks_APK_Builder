import 'client_model.dart';

enum BuildType {
  separateModule, // Build single module APK directly
  homeComposite,  // Build composite Home APK with integrated modules
}

class BuildManifest {
  final BuildType buildType;
  final String clientId;
  final String clientName;
  final String homeRepoUrl;
  final String homeBranch;
  final String environment;
  final String baseUrl;
  final String version;
  final String apkFilename;
  final String targetSharedComponentVersion;
  final List<SelectedModuleItem> selectedModules;
  final ClientModuleConfig? standaloneModule;

  const BuildManifest({
    required this.buildType,
    required this.clientId,
    required this.clientName,
    required this.homeRepoUrl,
    required this.homeBranch,
    required this.environment,
    required this.baseUrl,
    required this.version,
    required this.apkFilename,
    required this.targetSharedComponentVersion,
    required this.selectedModules,
    this.standaloneModule,
  });
}

class SelectedModuleItem {
  final ClientModuleConfig module;
  final String pullBranch;

  const SelectedModuleItem({
    required this.module,
    required this.pullBranch,
  });
}
