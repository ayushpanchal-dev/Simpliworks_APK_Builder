class ClientModuleConfig {
  final String id;
  final String displayName;
  final String repoUrl;
  final String defaultBranch;
  final bool isStandaloneSupported;
  final bool isRequiredInHome;

  const ClientModuleConfig({
    required this.id,
    required this.displayName,
    required this.repoUrl,
    this.defaultBranch = 'master',
    this.isStandaloneSupported = true,
    this.isRequiredInHome = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'repoUrl': repoUrl,
    'defaultBranch': defaultBranch,
    'isStandaloneSupported': isStandaloneSupported,
    'isRequiredInHome': isRequiredInHome,
  };

  factory ClientModuleConfig.fromJson(Map<String, dynamic> json) {
    return ClientModuleConfig(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['display_name'] as String? ?? json['id'] as String? ?? '',
      repoUrl: json['repoUrl'] as String? ?? json['git_url'] as String? ?? '',
      defaultBranch: json['defaultBranch'] as String? ?? json['branch'] as String? ?? 'master',
      isStandaloneSupported: json['isStandaloneSupported'] as bool? ?? true,
      isRequiredInHome: json['isRequiredInHome'] as bool? ?? json['is_required'] as bool? ?? false,
    );
  }

  ClientModuleConfig copyWith({
    String? id,
    String? displayName,
    String? repoUrl,
    String? defaultBranch,
    bool? isStandaloneSupported,
    bool? isRequiredInHome,
  }) {
    return ClientModuleConfig(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      repoUrl: repoUrl ?? this.repoUrl,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      isStandaloneSupported: isStandaloneSupported ?? this.isStandaloneSupported,
      isRequiredInHome: isRequiredInHome ?? this.isRequiredInHome,
    );
  }
}

class ClientProfile {
  final String id;
  final String name;
  final String homeRepoUrl;
  final String defaultHomeBranch;
  final Map<String, String> baseUrls;
  final List<ClientModuleConfig> modules;

  const ClientProfile({
    required this.id,
    required this.name,
    required this.homeRepoUrl,
    required this.defaultHomeBranch,
    required this.baseUrls,
    this.modules = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'homeRepoUrl': homeRepoUrl,
    'defaultHomeBranch': defaultHomeBranch,
    'baseUrls': baseUrls,
    'modules': modules.map((m) => m.toJson()).toList(),
  };

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    final modulesList = <ClientModuleConfig>[];
    if (json['modules'] is List) {
      for (var m in json['modules']) {
        if (m is Map) {
          modulesList.add(ClientModuleConfig.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    } else if (json['embeddable_modules'] is List) {
      for (var m in json['embeddable_modules']) {
        if (m is Map) {
          modulesList.add(ClientModuleConfig.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }

    return ClientProfile(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String? ?? json['display_name'] as String? ?? '',
      homeRepoUrl: json['homeRepoUrl'] as String? ?? json['home_repo_url'] as String? ?? '',
      defaultHomeBranch: json['defaultHomeBranch'] as String? ?? json['default_home_branch'] as String? ?? 'master',
      baseUrls: Map<String, String>.from(json['baseUrls'] as Map? ?? json['backend_urls'] as Map? ?? {}),
      modules: modulesList,
    );
  }

  /// Case-insensitive resolution of base URL based on environment key ('Testing', 'Preprod', 'Production')
  String getBaseUrlForEnvironment(String envKey) {
    final lower = envKey.trim().toLowerCase();
    if (lower.contains('prod') && !lower.contains('pre')) {
      return baseUrls['production'] ?? baseUrls['Production'] ?? baseUrls['Master'] ?? '';
    } else if (lower.contains('preprod') || lower.contains('pp')) {
      return baseUrls['preprod'] ?? baseUrls['Preprod'] ?? baseUrls['PP'] ?? '';
    } else {
      return baseUrls['testing'] ?? baseUrls['Testing'] ?? baseUrls['WSC'] ?? '';
    }
  }

  ClientProfile copyWith({
    String? id,
    String? name,
    String? homeRepoUrl,
    String? defaultHomeBranch,
    Map<String, String>? baseUrls,
    List<ClientModuleConfig>? modules,
  }) {
    return ClientProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      homeRepoUrl: homeRepoUrl ?? this.homeRepoUrl,
      defaultHomeBranch: defaultHomeBranch ?? this.defaultHomeBranch,
      baseUrls: baseUrls ?? this.baseUrls,
      modules: modules ?? this.modules,
    );
  }
}
