import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import '../models/build_manifest.dart';
import '../services/client_registry_service.dart';

class StudioController extends ChangeNotifier {
  final ClientRegistryService registryService;

  BuildType _buildType = BuildType.separateModule;
  ClientProfile? _selectedClient;
  ClientModuleConfig? _selectedStandaloneModule;
  String _selectedEnv = 'Testing'; // Testing, Preprod, Production
  String _selectedHomeBranch = 'master';
  String _versionName = '1.0.0';
  int _buildNumber = 1;
  String _customApkName = '';
  String _sharedComponentVersion = '1.4.6+67.2';
  
  // Home Composite mode modules selection & branch overrides
  final Set<String> _selectedModuleIds = {};
  final Map<String, String> _moduleBranches = {};

  bool _isBuilding = false;
  String _buildStatus = 'Ready';

  StudioController({required this.registryService}) {
    _initDefaults();
  }

  BuildType get buildType => _buildType;
  ClientProfile? get selectedClient => _selectedClient;
  ClientModuleConfig? get selectedStandaloneModule => _selectedStandaloneModule;
  String get selectedEnv => _selectedEnv;
  String get selectedHomeBranch => _selectedHomeBranch;
  String get versionName => _versionName;
  int get buildNumber => _buildNumber;
  String get customApkName => _customApkName;
  String get sharedComponentVersion => _sharedComponentVersion;
  Set<String> get selectedModuleIds => _selectedModuleIds;
  Map<String, String> get moduleBranches => _moduleBranches;
  bool get isBuilding => _isBuilding;
  String get buildStatus => _buildStatus;

  /// Dynamic Base URL actively derived based on client & environment
  String get derivedBaseUrl {
    if (_selectedClient == null) return '';
    return _selectedClient!.getBaseUrlForEnvironment(_selectedEnv);
  }

  /// Dynamic recommended APK Name
  String get recommendedApkName {
    final clientTag = _selectedClient?.id ?? 'Client';
    if (_buildType == BuildType.separateModule) {
      final modName = _selectedStandaloneModule?.displayName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') ?? 'Module';
      return 'Simpliworks_${clientTag}_${modName}_${_selectedEnv}_v$_versionName+$_buildNumber.apk';
    } else {
      return 'Simpliworks_${clientTag}_Home_${_selectedEnv}_v$_versionName+$_buildNumber.apk';
    }
  }

  void _initDefaults() {
    if (registryService.clients.isNotEmpty) {
      _selectedClient = registryService.clients.first;
      _selectedHomeBranch = _selectedClient!.defaultHomeBranch;
      if (_selectedClient!.modules.isNotEmpty) {
        _selectedStandaloneModule = _selectedClient!.modules.first;
        for (var m in _selectedClient!.modules) {
          _moduleBranches[m.id] = m.defaultBranch;
          if (m.isRequiredInHome) {
            _selectedModuleIds.add(m.id);
          }
        }
      }
      _customApkName = recommendedApkName;
    }
  }

  void setBuildType(BuildType type) {
    _buildType = type;
    _customApkName = recommendedApkName;
    notifyListeners();
  }

  void setClient(ClientProfile? client) {
    if (client == null) return;
    _selectedClient = client;
    _selectedHomeBranch = client.defaultHomeBranch;
    
    // Reset module selections for new client
    _selectedModuleIds.clear();
    _moduleBranches.clear();
    if (client.modules.isNotEmpty) {
      _selectedStandaloneModule = client.modules.first;
      for (var m in client.modules) {
        _moduleBranches[m.id] = m.defaultBranch;
        if (m.isRequiredInHome) {
          _selectedModuleIds.add(m.id);
        }
      }
    } else {
      _selectedStandaloneModule = null;
    }

    _customApkName = recommendedApkName;
    notifyListeners();
  }

  void setStandaloneModule(ClientModuleConfig? module) {
    _selectedStandaloneModule = module;
    _customApkName = recommendedApkName;
    notifyListeners();
  }

  void setEnvironment(String env) {
    _selectedEnv = env;
    _customApkName = recommendedApkName;
    notifyListeners();
  }

  void setHomeBranch(String branch) {
    _selectedHomeBranch = branch;
    notifyListeners();
  }

  void setSharedComponentVersion(String version) {
    _sharedComponentVersion = version;
    notifyListeners();
  }

  void setVersionName(String version) {
    _versionName = version;
    _customApkName = recommendedApkName;
    notifyListeners();
  }

  void setBuildNumber(int number) {
    _buildNumber = number;
    _customApkName = recommendedApkName;
    notifyListeners();
  }

  void setCustomApkName(String name) {
    _customApkName = name;
    notifyListeners();
  }

  void toggleModule(String moduleId, bool isSelected, {String? defaultBranch}) {
    if (isSelected) {
      _selectedModuleIds.add(moduleId);
      if (defaultBranch != null && !_moduleBranches.containsKey(moduleId)) {
        _moduleBranches[moduleId] = defaultBranch;
      }
    } else {
      _selectedModuleIds.remove(moduleId);
    }
    notifyListeners();
  }

  void setModuleBranch(String moduleId, String branch) {
    _moduleBranches[moduleId] = branch;
    notifyListeners();
  }

  void setBuilding(bool building, {String status = 'Ready'}) {
    _isBuilding = building;
    _buildStatus = status;
    notifyListeners();
  }

  BuildManifest createManifest() {
    final List<SelectedModuleItem> selectedItems = [];
    if (_selectedClient != null) {
      for (var m in _selectedClient!.modules) {
        if (_selectedModuleIds.contains(m.id) || m.isRequiredInHome) {
          final chosenBranch = _moduleBranches[m.id] ?? m.defaultBranch;
          selectedItems.add(SelectedModuleItem(module: m, pullBranch: chosenBranch));
        }
      }
    }

    final finalApkName = _customApkName.trim().isNotEmpty ? _customApkName.trim() : recommendedApkName;

    return BuildManifest(
      buildType: _buildType,
      clientId: _selectedClient?.id ?? 'client',
      clientName: _selectedClient?.name ?? 'Client',
      homeRepoUrl: _selectedClient?.homeRepoUrl ?? '',
      homeBranch: _selectedHomeBranch,
      environment: _selectedEnv,
      baseUrl: derivedBaseUrl,
      version: '$_versionName+$_buildNumber',
      apkFilename: finalApkName.endsWith('.apk') ? finalApkName : '$finalApkName.apk',
      targetSharedComponentVersion: _sharedComponentVersion,
      selectedModules: selectedItems,
      standaloneModule: _selectedStandaloneModule,
    );
  }
}
