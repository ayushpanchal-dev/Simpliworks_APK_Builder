import 'package:flutter/material.dart';
import 'services/client_registry_service.dart';
import 'services/build_orchestrator.dart';
import 'theme/app_theme.dart';
import 'ui/views/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final registryService = ClientRegistryService();
  await registryService.initialize();

  final orchestrator = BuildOrchestrator();

  runApp(SimpliworksApkBuilderApp(
    registryService: registryService,
    orchestrator: orchestrator,
  ));
}

class SimpliworksApkBuilderApp extends StatelessWidget {
  final ClientRegistryService registryService;
  final BuildOrchestrator orchestrator;

  const SimpliworksApkBuilderApp({
    super.key,
    required this.registryService,
    required this.orchestrator,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simpliworks APK Builder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AppShell(
        registryService: registryService,
        orchestrator: orchestrator,
      ),
    );
  }
}
