import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpliworks_apk_builder/services/client_registry_service.dart';
import 'package:simpliworks_apk_builder/controllers/studio_controller.dart';
import 'package:simpliworks_apk_builder/models/client_model.dart';
import 'package:simpliworks_apk_builder/models/build_manifest.dart';

void main() {
  test('Dual Build Type & Reactive Environment Test', () async {
    SharedPreferences.setMockInitialValues({});
    final registry = ClientRegistryService();
    await registry.initialize();

    final controller = StudioController(registryService: registry);

    // Initial state is BRM, Testing, Standalone Module mode
    expect(controller.selectedClient?.id, 'BRM');
    expect(controller.buildType, BuildType.separateModule);
    expect(controller.selectedStandaloneModule?.id, 'deliver_module');
    expect(controller.selectedEnv, 'Testing');
    expect(controller.derivedBaseUrl, 'https://wscsw2.simpliworks.co.in:453/');
    expect(controller.customApkName, contains('Simpliworks_BRM_DeliverModule_Testing_v1.0.0+1.apk'));

    // Switch Build Type to Home APK
    controller.setBuildType(BuildType.homeComposite);
    expect(controller.buildType, BuildType.homeComposite);
    expect(controller.customApkName, contains('Simpliworks_BRM_Home_Testing_v1.0.0+1.apk'));

    // Switch Environment to Production
    controller.setEnvironment('Production');
    expect(controller.derivedBaseUrl, 'https://brmdemo2.simpliworks.co.in/');
    expect(controller.customApkName, contains('Simpliworks_BRM_Home_Production_v1.0.0+1.apk'));

    // Switch Client to Ganraj
    final ganraj = registry.clients.firstWhere((c) => c.id == 'Ganraj');
    controller.setClient(ganraj);
    expect(controller.selectedClient?.id, 'Ganraj');
    expect(controller.selectedStandaloneModule?.id, 'deliver_module');
    expect(controller.derivedBaseUrl, 'https://ganraj.simpliworks.co.in/');
  });

  test('Client & Module Association CRUD Test', () async {
    SharedPreferences.setMockInitialValues({});
    final registry = ClientRegistryService();
    await registry.initialize();

    const newModule = ClientModuleConfig(
      id: 'custom_store',
      displayName: 'Custom Store Module',
      repoUrl: 'http://vitplgit.vegainnovations.co.in/store.git',
      defaultBranch: 'develop',
      isStandaloneSupported: true,
    );

    // Add module specifically for BRM
    await registry.addOrUpdateModuleForClient('BRM', newModule);
    final brm = registry.clients.firstWhere((c) => c.id == 'BRM');
    expect(brm.modules.any((m) => m.id == 'custom_store'), isTrue);

    // Verify it is NOT present in Kalika
    final kalika = registry.clients.firstWhere((c) => c.id == 'Kalika');
    expect(kalika.modules.any((m) => m.id == 'custom_store'), isFalse);

    // Remove module
    await registry.removeModuleFromClient('BRM', 'custom_store');
    final updatedBrm = registry.clients.firstWhere((c) => c.id == 'BRM');
    expect(updatedBrm.modules.any((m) => m.id == 'custom_store'), isFalse);
  });
}
